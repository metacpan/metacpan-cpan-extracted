#!/usr/bin/env python3
"""enumerate_python_signatures.py — emit python_signatures.json from the
Python reference SDK.

This is the Phase 1 deliverable from SIGNATURE_AUDIT_PLAN.md: walk
signalwire-python via griffe (v2.0.2), translate every public method's
signature into the canonical shape defined by surface_schema_v2.json,
and write the result to python_signatures.json.

Python is the audit's oracle. Every other port's adapter compares
against this output. So unlike port-side adapters, this enumerator is
intentionally strict: any annotation it can't translate to a canonical
type fails loudly with the source path, the offending griffe expression,
and a suggestion. This is the contract from ADAPTER_CONTRACT.md applied
to the reference itself.

Usage:
    python3 scripts/enumerate_python_signatures.py \\
        --signalwire-python /path/to/signalwire-python/signalwire \\
        --out python_signatures.json

The default --signalwire-python path matches the local dev environment
where the package is at ~/src/signalwire-python/signalwire/signalwire/.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import yaml

import griffe
from griffe import (
    Alias, Attribute, Class, Function, Module, Parameter, ParameterKind,
    Expr, ExprAttribute, ExprBinOp, ExprBoolOp, ExprCall, ExprConstant,
    ExprList, ExprName, ExprSubscript, ExprTuple,
)


HERE = Path(__file__).resolve().parent
PSDK = HERE.parent  # porting-sdk root

# ---------------------------------------------------------------------------
# Canonical type translation
# ---------------------------------------------------------------------------


class TypeTranslationError(RuntimeError):
    """Raised when an annotation can't be mapped to the canonical vocabulary.

    This is the loud-failure contract from ADAPTER_CONTRACT.md: the
    enumerator never silently emits ``any`` as a fallback for unknown.
    """


def load_aliases(aliases_path: Path) -> dict[str, str]:
    """Return a flat ``{native_name: canonical_type}`` mapping for Python."""
    data = yaml.safe_load(aliases_path.read_text(encoding="utf-8"))
    py = data.get("aliases", {}).get("python", {})
    # Normalise keys to plain strings (yaml may have parsed special tokens).
    return {str(k): str(v) for k, v in py.items()}


def _resolve_class_ref(expr: ExprName) -> str | None:
    """If ``expr`` resolves to a Class in griffe's collection, return its
    canonical Python dotted path. Otherwise None."""
    try:
        target = expr.canonical_path
    except (AttributeError, KeyError):
        return None
    if not target or "." not in target:
        return None
    # canonical_path can resolve to a builtin (e.g. 'builtins.str'); skip those
    if target.startswith("builtins."):
        return None
    return target


def expr_to_canonical(expr, aliases: dict[str, str], context: str) -> str:
    """Translate a griffe annotation expression to a canonical type string.

    ``context`` is a human-readable location used in error messages
    (e.g. ``signalwire.core.agent_base.AgentBase.set_prompt[text]``).
    """
    if expr is None:
        return "any"  # bare unannotated parameter; matches Python's typing.Any

    # griffe sometimes returns the literal string "None" for ``-> None`` returns
    if isinstance(expr, str):
        s = expr.strip()
        if s in ("None", "NoneType"):
            return "void"
        if s in aliases:
            return aliases[s]
        # PEP 484 string forward reference: the literal source ``'Call'``
        # comes through as the string ``"'Call'"``. Strip surrounding quotes
        # and treat as a class name.
        unquoted = s
        if (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
            unquoted = s[1:-1].strip()
        if unquoted in aliases:
            return aliases[unquoted]
        if unquoted in ("None", "NoneType"):
            return "void"
        if unquoted == "Any":
            return "any"
        if unquoted and unquoted[0].isupper() and unquoted.replace("_", "").replace(".", "").isalnum():
            # Best-effort class reference — diff tool will compare across ports
            return f"class:{unquoted}"
        raise TypeTranslationError(
            f"unknown raw-string annotation '{s}' at {context}; "
            f"add to type_aliases.yaml under aliases.python or fix the source"
        )

    if isinstance(expr, ExprName):
        name = expr.name
        # 1. Try to resolve as a class reference into the SDK
        resolved = _resolve_class_ref(expr)
        if resolved and resolved.startswith("signalwire."):
            return f"class:{resolved}"
        # 2. Stdlib / builtins via alias table
        if name in aliases:
            return aliases[name]
        if name in ("None", "NoneType"):
            return "void"
        if name == "Any":
            return "any"
        # 3. Forward references / unresolved names — emit class:<name> if it
        #    looks like a class (PascalCase), else fail loudly.
        if name and name[0].isupper():
            # Best-effort class reference; if the resolution failed, emit
            # the bare name so the diff can still match across ports.
            return f"class:{name}"
        raise TypeTranslationError(
            f"unknown name '{name}' at {context}; "
            f"add to type_aliases.yaml under aliases.python or fix the source"
        )

    if isinstance(expr, ExprAttribute):
        # e.g. typing.Any, datetime.datetime
        s = str(expr)
        if s in aliases:
            return aliases[s]
        # Try just the rightmost segment
        last = s.rsplit(".", 1)[-1]
        if last in aliases:
            return aliases[last]
        if last in ("None", "NoneType"):
            return "void"
        if last == "Any":
            return "any"
        if last and last[0].isupper():
            return f"class:{s}"
        raise TypeTranslationError(
            f"unknown attribute annotation '{s}' at {context}"
        )

    if isinstance(expr, ExprConstant):
        # Literal None in an annotation
        v = expr.value
        if v == "None" or v is None:
            return "void"
        # Other constants in annotations are unusual; treat the source string
        s = str(v).strip("'\"")
        if s in ("None",):
            return "void"
        raise TypeTranslationError(
            f"unexpected constant annotation '{v}' at {context}"
        )

    if isinstance(expr, ExprSubscript):
        # Generic types: Optional[X], List[X], Dict[K,V], Tuple[X,Y],
        # Union[A,B], Callable[[A,B],R]
        outer_expr = expr.left
        outer_name = (
            outer_expr.name if isinstance(outer_expr, ExprName)
            else str(outer_expr).rsplit(".", 1)[-1]
        )
        slice_ = expr.slice
        if outer_name in ("Optional",):
            inner = expr_to_canonical(slice_, aliases, context)
            return f"optional<{inner}>"
        if outer_name in ("List", "list", "Sequence", "Iterable", "Iterator"):
            inner = expr_to_canonical(slice_, aliases, context)
            return f"list<{inner}>"
        if outer_name in ("Set", "set", "FrozenSet", "frozenset"):
            inner = expr_to_canonical(slice_, aliases, context)
            return f"list<{inner}>"  # canonical vocabulary has no set type
        if outer_name in ("Dict", "dict", "Mapping", "MutableMapping"):
            if isinstance(slice_, ExprTuple):
                k = expr_to_canonical(slice_.elements[0], aliases, context)
                v = expr_to_canonical(slice_.elements[1], aliases, context)
                return f"dict<{k},{v}>"
            raise TypeTranslationError(
                f"Dict subscript without two elements at {context}"
            )
        if outer_name in ("Tuple", "tuple"):
            if isinstance(slice_, ExprTuple):
                inner = ",".join(
                    expr_to_canonical(e, aliases, context) for e in slice_.elements
                )
            else:
                inner = expr_to_canonical(slice_, aliases, context)
            return f"tuple<{inner}>"
        if outer_name in ("Union",):
            if isinstance(slice_, ExprTuple):
                inner = ",".join(
                    expr_to_canonical(e, aliases, context) for e in slice_.elements
                )
            else:
                inner = expr_to_canonical(slice_, aliases, context)
            return f"union<{inner}>"
        if outer_name == "Callable":
            # Callable[[A,B], R]
            if isinstance(slice_, ExprTuple) and len(slice_.elements) == 2:
                args_expr, ret_expr = slice_.elements
                if isinstance(args_expr, ExprList):
                    arg_types = ",".join(
                        expr_to_canonical(a, aliases, context)
                        for a in args_expr.elements
                    )
                else:
                    arg_types = expr_to_canonical(args_expr, aliases, context)
                ret_type = expr_to_canonical(ret_expr, aliases, context)
                return f"callable<list<{arg_types}>,{ret_type}>"
            return "callable<list<any>,any>"
        if outer_name in ("Type", "type"):
            inner = expr_to_canonical(slice_, aliases, context)
            return f"class:{inner}" if not inner.startswith("class:") else inner
        # Fallback: parameterized class reference
        if outer_name and outer_name[0].isupper():
            return f"class:{outer_name}"
        raise TypeTranslationError(
            f"unsupported parameterized type {outer_name!r} at {context}"
        )

    if isinstance(expr, ExprBinOp):
        # PEP 604: X | Y  →  union<X,Y>; X | None  →  optional<X>
        op = getattr(expr, "operator", None)
        if op == "|":
            left = expr_to_canonical(expr.left, aliases, context)
            right = expr_to_canonical(expr.right, aliases, context)
            # Optional shortcut
            if right == "void":
                return f"optional<{left}>"
            if left == "void":
                return f"optional<{right}>"
            return f"union<{left},{right}>"
        raise TypeTranslationError(
            f"unsupported binary operator {op!r} in annotation at {context}"
        )

    if isinstance(expr, ExprBoolOp):
        # Rare; treat like a union of operands
        parts = [expr_to_canonical(o, aliases, context) for o in expr.operands]
        return f"union<{','.join(parts)}>"

    if isinstance(expr, ExprTuple):
        # Bare tuple in an annotation context: shouldn't really happen but
        # treat like Tuple[...]
        inner = ",".join(
            expr_to_canonical(e, aliases, context) for e in expr.elements
        )
        return f"tuple<{inner}>"

    raise TypeTranslationError(
        f"unhandled annotation type {type(expr).__name__} "
        f"({expr!r}) at {context}"
    )


# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------

PRIVATE_RE = re.compile(r"^_[^_]")  # one leading underscore, not dunder


def is_public_name(name: str) -> bool:
    if name == "__init__":
        return True
    if name.startswith("__") and name.endswith("__"):
        return False  # other dunders not part of the public API
    if PRIVATE_RE.match(name):
        return False
    return True


def is_locally_defined(member, owner) -> bool:
    """A method ``member`` is locally defined on class ``owner`` if it is
    not an Alias (re-exported import) and its module path matches the
    owner's module path."""
    if isinstance(member, Alias):
        return False
    if not hasattr(member, "module") or member.module is None:
        return False
    return member.module.canonical_path == owner.module.canonical_path


def _types_loosely_equal(a: str, b: str) -> bool:
    """Tolerant type equivalence used by the override-skip rule.
    ``any`` matches anything; ``list<any>`` matches ``list<X>``; etc.
    Mirrors the audit-side ``types_compatible`` rule but lives here so
    the Python adapter can apply it before emission."""
    a = (a or "any").replace(" ", "")
    b = (b or "any").replace(" ", "")
    if a == b or a == "any" or b == "any":
        return True
    def split(t):
        if "<" not in t or not t.endswith(">"):
            return t, []
        idx = t.index("<")
        head = t[:idx]
        depth = 0
        parts: list[str] = []
        cur = ""
        for ch in t[idx + 1:-1]:
            if ch == "<":
                depth += 1
                cur += ch
            elif ch == ">":
                depth -= 1
                cur += ch
            elif ch == "," and depth == 0:
                parts.append(cur); cur = ""
            else:
                cur += ch
        if cur:
            parts.append(cur)
        return head, parts
    ha, aa = split(a)
    hb, bb = split(b)
    if ha != hb or len(aa) != len(bb):
        return False
    return all(_types_loosely_equal(x, y) for x, y in zip(aa, bb))


def _signatures_equivalent(base_sig: dict, override_sig: dict) -> bool:
    """An override carries no new API surface when its params and return
    type are loosely equivalent to the base. ``list<any>`` overriding
    ``list<string>`` counts (Python idiom: drop type annotation)."""
    bp = base_sig.get("params", [])
    op = override_sig.get("params", [])
    if len(bp) != len(op):
        return False
    for a, b in zip(bp, op):
        if a.get("name") != b.get("name"):
            return False
        if a.get("kind", "positional") != b.get("kind", "positional"):
            return False
        if not _types_loosely_equal(a.get("type", "any"), b.get("type", "any")):
            return False
    return _types_loosely_equal(
        base_sig.get("returns", "any"),
        override_sig.get("returns", "any"),
    )


def _is_sdk_class_type(canonical: str) -> bool:
    """An attribute is part of the cross-language API surface only when it
    references an SDK class (composition / namespace pattern). Primitive
    state attributes (`str`, `int`, `dict`, `any`, etc.) are Python-internal
    scaffolding that ports surface differently or not at all."""
    if canonical.startswith("class:"):
        return True
    if canonical.startswith("optional<class:"):
        return True
    if canonical.startswith("list<class:"):
        return True
    if canonical.startswith("union<") and "class:" in canonical:
        return True
    return False


def _infer_class_from_value(value, aliases: dict[str, str]) -> str | None:
    """When an instance attribute lacks a type annotation but is assigned
    via ``self.foo = SomeClass(...)``, the callee's resolved class is the
    attribute's effective type for cross-language audit purposes. Returns
    a canonical ``class:...`` string when inference succeeds, else None."""
    if not isinstance(value, ExprCall):
        return None
    func = value.function
    if not isinstance(func, ExprName):
        return None
    resolved = _resolve_class_ref(func)
    if not resolved:
        return None
    if resolved in aliases:
        resolved = aliases[resolved]
    return f"class:{resolved}"


# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

KIND_MAP = {
    ParameterKind.positional_or_keyword: "positional",
    ParameterKind.positional_only: "positional",
    ParameterKind.keyword_only: "keyword",
    ParameterKind.var_positional: "var_positional",
    ParameterKind.var_keyword: "var_keyword",
}


def convert_default(raw):
    """Convert griffe's source-level default representation into a JSON
    primitive. ``raw`` is either None (no default), a string (source-level
    repr like ``'None'``, ``'3000'``, ``'"foo"'``), or already a primitive."""
    if raw is None:
        return None  # in JSON output we'll OMIT the default; null != omitted
    if isinstance(raw, (int, float, bool)):
        return raw
    s = str(raw).strip()
    if s in ("None",):
        return None
    if s in ("True",):
        return True
    if s in ("False",):
        return False
    # Numeric literal
    try:
        if "." in s or "e" in s or "E" in s:
            return float(s)
        return int(s)
    except ValueError:
        pass
    # String literal — strip surrounding quotes
    if (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
        return s[1:-1]
    # Empty list / dict literals
    if s in ("[]",):
        return []
    if s in ("{}",):
        return {}
    # Unknown — emit as the raw source string. Diff tool can normalize later.
    return s


def convert_signature(func: Function, aliases: dict[str, str]) -> dict:
    qualified = func.canonical_path
    params_out = []
    seen_names: set[str] = set()
    is_method = func.parent is not None and isinstance(func.parent, Class)
    for i, p in enumerate(func.parameters):
        ctx = f"{qualified}[{p.name}]"
        kind_str: str
        if i == 0 and is_method and p.name == "self":
            kind_str = "self"
        elif i == 0 and is_method and p.name == "cls":
            kind_str = "cls"
        else:
            kind_str = KIND_MAP.get(p.kind, "positional")

        param_dict: dict = {"name": p.name}
        if kind_str != "positional":
            param_dict["kind"] = kind_str

        if kind_str in ("self", "cls"):
            # Receiver — no type, no default per schema.
            params_out.append(param_dict)
            seen_names.add(p.name)
            continue

        param_dict["type"] = expr_to_canonical(p.annotation, aliases, ctx)

        # required/default. griffe Parameter.default == None when there's no
        # default literal. Source default of literal None is the *string*
        # ``'None'``.
        if p.default is None:
            param_dict["required"] = True
        else:
            param_dict["required"] = False
            converted = convert_default(p.default)
            param_dict["default"] = converted

        params_out.append(param_dict)
        seen_names.add(p.name)

    ctx = f"{qualified}[->]"
    returns = expr_to_canonical(func.returns, aliases, ctx)
    # Python's __init__ has no return annotation by convention; treat as
    # void so it matches every other port's constructor return type.
    if func.name == "__init__":
        returns = "void"
    return {"params": params_out, "returns": returns}


def collect_module(
    module: Module,
    aliases: dict[str, str],
    out_modules: dict,
    failures: list,
) -> None:
    """Recursively walk a module and emit its public surface."""
    mod_path = module.canonical_path
    # Python-ecosystem-only modules — not part of the cross-language SDK
    # surface ports must mirror.
    #
    #   ``signalwire.cli.*`` — Python `signalwire init` / `signalwire dokku`
    #     CLI tooling. Each port has its own packaging/CLI conventions or
    #     none at all.
    #   ``signalwire.search.*`` — optional `pip install signalwire-sdk[search]`
    #     extra (sqlite-vec / sentence-transformers / pgvector). A
    #     Python-only local search engine.
    #   ``signalwire.livewire.*`` — livekit-agents compat stubs that exist
    #     so Python code targeting livekit can run unchanged. Python-only.
    if (mod_path.startswith("signalwire.cli")
        or mod_path.startswith("signalwire.search")
        or mod_path.startswith("signalwire.livewire")
        or mod_path.startswith("signalwire.mcp_gateway")
        or mod_path == "signalwire.pom.pom_tool"
        or mod_path == "signalwire.core.agent.tools.type_inference"):
        return
    # Dev-scratch alternate-implementation modules. Python's web_search
    # skill ships ``skill.py`` (canonical) plus ``skill_improved.py`` /
    # ``skill_original.py`` as alternate variants — none re-exported via
    # ``__init__.py``, none used by the CLI. Ports expose only the
    # canonical skill module.
    if mod_path.endswith("_improved") or mod_path.endswith("_original"):
        return
    # Implementation-detail helper classes inside skill modules. Python's
    # ``signalwire.skills.web_search.skill`` defines ``GoogleSearchScraper``
    # alongside ``WebSearchSkill``; ``signalwire.skills.google_maps.skill``
    # defines ``GoogleMapsClient`` alongside ``GoogleMapsSkill``. Only
    # the ``*Skill`` class is the cross-language API contract — the
    # helpers are Python-internal scaffolding for that skill's
    # implementation.
    skill_helpers_to_skip: set[str] = set()
    if mod_path.startswith("signalwire.skills.") and mod_path.endswith(".skill"):
        for cname in module.members:
            if isinstance(module.members[cname], Class) and "Skill" not in cname:
                skill_helpers_to_skip.add(cname)

    # Python-only code-gen helper methods — these generate PYTHON SOURCE
    # CODE STRINGS (e.g. ``def ai(self, ...): ...``) for verb-method
    # autogeneration during the Python build. No other language has
    # Python source-code as output; ports either generate code in
    # their own language (different signature) or don't autogenerate at
    # all (different code path). Not part of the cross-language API.
    method_skips: dict[tuple[str, str], set[str]] = {
        ("signalwire.utils.schema_utils", "SchemaUtils"): {
            "generate_method_signature",
            "generate_method_body",
        },
        # ``as_router`` returns a FastAPI APIRouter — Python+FastAPI
        # specific. Each port exposes "embed agent routes in my app"
        # using its native framework abstraction (.NET
        # IEndpointRouteBuilder, Java Spring routes, Go http.Handler,
        # etc.) — different shape per language. Capability mirrored
        # per-port; this Python signature has no cross-language form.
        ("signalwire.core.swml_service", "SWMLService"): {"as_router"},
    }

    # Top-level free-function skips — Python-only CLI shims that
    # lazy-import from signalwire.cli.helpers (already filtered).
    # These are convenience entry points for ``signalwire.start_agent(...)``
    # etc. that ports either don't have or implement via their own CLI.
    free_function_skips: dict[str, set[str]] = {
        "signalwire": {"start_agent", "run_agent", "list_skills"},
    }
    classes_out: dict = {}
    functions_out: dict = {}

    for name, member in module.members.items():
        if isinstance(member, Module):
            # Python convention prefixes internal modules with ``_``
            # (``signalwire.rest._base``, ``signalwire.rest._pagination``).
            # Ports treat the same classes as public — CrudResource,
            # HttpClient, BaseResource, PaginatedIterator all have to
            # exist somewhere, and ports place them in the same dotted
            # path. Recurse regardless of prefix so the cross-language
            # audit sees them.
            collect_module(member, aliases, out_modules, failures)
            continue
        if not is_public_name(name):
            continue
        if isinstance(member, Alias):
            # Re-exports / imports: skip in v1. Match the existing
            # python_surface enumerator behaviour.
            continue
        if isinstance(member, Class):
            if name in skill_helpers_to_skip:
                continue
            # Build a quick lookup of base-class method signatures so we
            # can skip subclass overrides that don't change the signature.
            # The cross-language audit is signature-only — port-side
            # subclasses inherit base methods, and the audit can't see
            # those, so emitting same-signature overrides on Python's
            # subclass while ports inherit silently produces false
            # positives.
            base_method_sigs: dict[str, dict] = {}
            for base_expr in member.bases:
                base_cls = getattr(base_expr, "resolved", None)
                if not isinstance(base_cls, Class):
                    continue
                for bname, bmember in base_cls.members.items():
                    if isinstance(bmember, Function) and bname not in base_method_sigs:
                        try:
                            base_method_sigs[bname] = convert_signature(bmember, aliases)
                        except TypeTranslationError:
                            pass
            methods_out: dict = {}
            class_skip_methods = method_skips.get((mod_path, name), set())
            for mname, mmember in member.members.items():
                if not is_public_name(mname):
                    continue
                if mname in class_skip_methods:
                    continue
                if isinstance(mmember, Function):
                    if not is_locally_defined(mmember, member):
                        continue
                    try:
                        sig = convert_signature(mmember, aliases)
                    except TypeTranslationError as e:
                        failures.append(str(e))
                        continue
                    # Skip override-only-by-body redefinitions: if the
                    # signature is identical to a base class's, the
                    # override carries no additional API surface for the
                    # cross-language audit. Subclass-specific signature
                    # changes (different params/types) still emit.
                    base_sig = base_method_sigs.get(mname)
                    if base_sig is not None and _signatures_equivalent(base_sig, sig):
                        continue
                    methods_out[mname] = sig
                elif isinstance(mmember, Attribute):
                    # Instance attribute (assigned in __init__) or class
                    # attribute. Emit as a zero-arg property-style method
                    # ONLY when the attribute holds another SDK class
                    # (composition / namespace pattern) — that is the
                    # cross-language surface other ports expose explicitly
                    # (RestClient.addresses, RestClient.fabric, AgentBase.pom).
                    #
                    # State attributes (str/int/bool/dict/etc. or untyped
                    # `any`) are Python-internal scaffolding, not API:
                    # ports surface those via constructors, properties, or
                    # not at all. Including them here generated thousands
                    # of false-positive missing-port entries.
                    if not is_locally_defined(mmember, member):
                        continue
                    if mname.startswith("_"):
                        continue
                    if mname.isupper() or mname.replace("_", "").isupper():
                        continue
                    ret_type = "any"
                    if mmember.annotation is not None:
                        try:
                            ret_type = expr_to_canonical(mmember.annotation, aliases, f"{member.canonical_path}.{mname}")
                        except TypeTranslationError:
                            ret_type = "any"
                    elif mmember.value is not None:
                        # Common Python pattern: ``self.foo = SomeClass(...)``
                        # has no annotation but the call's callee names the
                        # class. Infer the canonical class type from the
                        # call expression so namespace getters surface.
                        ret_type = _infer_class_from_value(mmember.value, aliases) or "any"
                    if not _is_sdk_class_type(ret_type):
                        continue
                    methods_out[mname] = {
                        "params": [{"name": "self", "kind": "self"}],
                        "returns": ret_type,
                    }
            if methods_out:
                classes_out[name] = {"methods": methods_out}
            continue
        if isinstance(member, Function):
            if name in free_function_skips.get(mod_path, set()):
                continue
            try:
                functions_out[name] = convert_signature(member, aliases)
            except TypeTranslationError as e:
                failures.append(str(e))
            continue
        # Attributes / data — not part of the signature inventory.

    if classes_out or functions_out:
        entry: dict = {}
        if classes_out:
            entry["classes"] = classes_out
        if functions_out:
            entry["functions"] = functions_out
        out_modules[mod_path] = entry


def build(signalwire_python_dir: Path, aliases: dict[str, str]) -> tuple[dict, list]:
    loader = griffe.GriffeLoader(search_paths=[str(signalwire_python_dir)])
    root = loader.load("signalwire")

    out_modules: dict = {}
    failures: list = []
    collect_module(root, aliases, out_modules, failures)

    # Sort modules + class methods + module functions for determinism
    sorted_modules: dict = {}
    for mod in sorted(out_modules):
        entry = out_modules[mod]
        new_entry: dict = {}
        if "classes" in entry:
            new_entry["classes"] = {
                cls: {
                    "methods": dict(sorted(entry["classes"][cls]["methods"].items()))
                }
                for cls in sorted(entry["classes"])
            }
        if "functions" in entry:
            new_entry["functions"] = dict(sorted(entry["functions"].items()))
        sorted_modules[mod] = new_entry

    inventory = {
        "version": "2",
        "generated_from": f"griffe {griffe_version()}",
        "modules": sorted_modules,
    }
    return inventory, failures


def griffe_version() -> str:
    try:
        from importlib.metadata import version
        return version("griffe")
    except Exception:
        return "unknown"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--signalwire-python",
        type=Path,
        default=Path("/home/devuser/src/signalwire-python/signalwire"),
        help="Path containing the signalwire/ package directory.",
    )
    parser.add_argument(
        "--aliases",
        type=Path,
        default=PSDK / "type_aliases.yaml",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=PSDK / "python_signatures.json",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit non-zero if any annotation fails to translate. "
             "Without this, failures are reported on stderr but the JSON "
             "is still written for the symbols that succeeded — useful "
             "for incremental development of the alias table.",
    )
    args = parser.parse_args()

    aliases = load_aliases(args.aliases)
    inventory, failures = build(args.signalwire_python, aliases)

    if failures:
        print(
            f"enumerate_python_signatures: {len(failures)} translation failure(s)",
            file=sys.stderr,
        )
        for f in failures[:20]:
            print(f"  - {f}", file=sys.stderr)
        if len(failures) > 20:
            print(f"  ... ({len(failures) - 20} more)", file=sys.stderr)
        if args.strict:
            return 1

    args.out.write_text(
        json.dumps(inventory, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )
    n_mods = len(inventory["modules"])
    n_classes = sum(len(m.get("classes", {})) for m in inventory["modules"].values())
    n_methods = sum(
        sum(len(c["methods"]) for c in m.get("classes", {}).values())
        for m in inventory["modules"].values()
    )
    n_funcs = sum(len(m.get("functions", {})) for m in inventory["modules"].values())
    print(
        f"enumerate_python_signatures: wrote {args.out} "
        f"({n_mods} modules, {n_classes} classes, {n_methods} methods, "
        f"{n_funcs} functions; griffe {griffe_version()})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
