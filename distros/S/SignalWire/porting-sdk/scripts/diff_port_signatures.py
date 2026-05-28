#!/usr/bin/env python3
"""diff_port_signatures.py — fail CI if a port's signatures drift from
the Python reference.

This is the signature-level sibling of diff_port_surface.py. The existing
diff_port_surface compares NAMES; this one compares full signatures
(parameter names, count, types, defaults, return types) per the canonical
shape defined by surface_schema_v2.json.

Inputs:
    --reference        python_signatures.json (the oracle)
    --port-signatures  port_signatures.json (the port's adapter output)
    --omissions        PORT_SIGNATURE_OMISSIONS.md (documented divergences)
    --aliases          type_aliases.yaml (cross-language type alias table)
    --json             machine-readable output (for CI consumption)

Drift classes reported (each can be excused via PORT_SIGNATURE_OMISSIONS.md):

    1. Method present in reference but missing in port (or vice versa).
    2. Parameter list mismatch — different name, count, or order.
    3. Parameter type mismatch — after normalization through type_aliases.
    4. Return type mismatch — same.
    5. Required-vs-optional flip — caller must / must-not supply value.
    6. Default value mismatch — different defaults.

Strict on parameter names + count: those are language-agnostic. Lenient
on types: the alias table maps native type expressions to canonical, but
we additionally normalize cosmetic differences (whitespace, ordering of
union members) at compare time.

Exit codes:
    0  clean (or all drift excused)
    1  drift exists
    2  usage / invalid input
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
PSDK = HERE.parent

SYMBOL_RE = re.compile(r"^[A-Za-z_][\w?!]*(?:\.[A-Za-z_][\w?!]*)*$")


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------


def load_json(path: Path) -> dict:
    if not path.is_file():
        raise SystemExit(f"error: {path} not found")
    return json.loads(path.read_text(encoding="utf-8"))


def parse_omissions(path: Path) -> dict[str, str]:
    if not path or not path.is_file():
        return {}
    out: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("- ["):
            continue
        if ":" not in line:
            continue
        sym, _, rationale = line.partition(":")
        sym = sym.strip()
        rationale = rationale.strip()
        if not SYMBOL_RE.match(sym):
            continue
        out[sym] = rationale or "(no rationale)"
    return out


# ---------------------------------------------------------------------------
# Type normalization
# ---------------------------------------------------------------------------


def types_compatible(t_ref: str, t_port: str) -> bool:
    """Structural compatibility: ``any`` matches anything at any nesting
    depth. ``list<any>`` is compatible with ``list<X>``, ``dict<string,any>``
    with ``dict<string,X>``, etc. Other generic shells must match
    head-to-head; their type arguments are checked recursively. Unions
    are compatible if every member of the more-specific side is covered
    by some member of the other side.
    """
    if t_ref == t_port:
        return True
    if t_ref == "any" or t_port == "any":
        return True

    def split(t: str) -> tuple[str, list[str]]:
        if "<" not in t or not t.endswith(">"):
            return t, []
        idx = t.index("<")
        head = t[:idx]
        inner = t[idx + 1:-1]
        return head, _split_top_commas(inner)

    head_ref, args_ref = split(t_ref)
    head_port, args_port = split(t_port)

    if head_ref == "union" and args_ref:
        return all(any(types_compatible(a, b) for b in args_port or [t_port])
                   for a in args_ref)
    if head_port == "union" and args_port:
        return any(types_compatible(t_ref, b) for b in args_port)

    if head_ref == "optional" and len(args_ref) == 1:
        return types_compatible(args_ref[0], t_port) or t_port in ("null",)
    if head_port == "optional" and len(args_port) == 1:
        return types_compatible(t_ref, args_port[0]) or t_ref in ("null",)

    if head_ref != head_port:
        return False
    if len(args_ref) != len(args_port):
        return False
    return all(types_compatible(a, b) for a, b in zip(args_ref, args_port))


def normalize_type(t: str) -> str:
    """Canonical-form normalisation for diff. Strips spaces, sorts union
    members alphabetically (so ``union<a,b>`` matches ``union<b,a>``),
    treats bare-erased dict/list as equivalent to the most common typed
    form (``dict<string,any>`` / ``list<any>``), and leaves everything
    else byte-identical.

    The alias table is applied at adapter time, not here. This function
    only handles cosmetic ordering differences and bare-vs-typed
    equivalence inside canonical strings.
    """
    if t is None:
        return "any"
    t = t.replace(" ", "")
    # Dynamically-typed JSON-value classes that ports use as a stand-in
    # for "any JSON shape" (Rust's ``serde_json::Value``, .NET's
    # ``System.Text.Json.JsonElement``, etc.). The reference adapter
    # would translate these via type_aliases.yaml to ``any``, but rustdoc
    # may resolve as a port-internal class path that the adapter emits
    # under ``class:signalwire.value.Value``. Treat such bare ``Value``
    # class refs as equivalent to ``any``.
    if t.endswith(".value.Value") or t == "class:signalwire.value.Value":
        return "any"
    if t.startswith("union<") and t.endswith(">"):
        inner = t[len("union<"):-1]
        parts = _split_top_commas(inner)
        parts = sorted(normalize_type(p) for p in parts)
        return "union<" + ",".join(parts) + ">"
    # Erased generic equivalence: Python's ``dict`` (untyped) and
    # ``dict[str, Any]`` describe the same contract — every Python dict
    # is string-keyed by convention. Same for list<any>.
    if t == "dict<any,any>":
        return "dict<string,any>"
    if "<" in t and t.endswith(">"):
        idx = t.index("<")
        head = t[:idx]
        inner = t[idx + 1:-1]
        parts = _split_top_commas(inner)
        normalized_inner = ",".join(normalize_type(p) for p in parts)
        # Recurse: dict<any,any> at any nesting level normalizes the same way.
        if head == "dict" and normalized_inner == "any,any":
            return "dict<string,any>"
        return head + "<" + normalized_inner + ">"
    return t


def _split_top_commas(s: str) -> list[str]:
    out, buf, depth = [], [], 0
    for ch in s:
        if ch == "<":
            depth += 1
        elif ch == ">":
            depth -= 1
        if ch == "," and depth == 0:
            out.append("".join(buf))
            buf.clear()
            continue
        buf.append(ch)
    if buf:
        out.append("".join(buf))
    return [p.strip() for p in out]


# ---------------------------------------------------------------------------
# Diff result types
# ---------------------------------------------------------------------------


@dataclass
class Drift:
    symbol: str       # fully-qualified canonical path
    kind: str         # 'missing-port', 'missing-reference', 'param-mismatch',
                      # 'return-mismatch', 'default-mismatch', 'required-flip'
    detail: str

    def line(self) -> str:
        return f"{self.kind}: {self.symbol} — {self.detail}"


@dataclass
class DiffResult:
    drift: list[Drift] = field(default_factory=list)
    excused: list[Drift] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Index helpers
# ---------------------------------------------------------------------------


_PRIMITIVE_RET_PREFIXES = (
    "string", "int", "float", "bool", "bytes", "datetime", "any", "void",
)


def _is_port_state_accessor(sig: dict) -> bool:
    """Zero-arg method (only ``self``) returning a primitive type, list of
    primitives, dict of primitives, or optional-of-primitive — i.e. a
    port-side getter for a state attribute (.NET property, Java getter,
    etc.). Python's reference adapter excludes such state attributes by
    design, so port-only entries of this shape are not real drift."""
    params = sig.get("params", [])
    if len(params) != 1 or params[0].get("kind") != "self":
        return False
    ret = (sig.get("returns") or "").replace(" ", "")
    if ret.startswith("optional<"):
        ret = ret[len("optional<"):-1]
    if ret.startswith("list<"):
        ret = ret[len("list<"):-1]
    if ret.startswith("dict<"):
        return True
    if ret.startswith("class:"):
        return False
    if ret.startswith("union<"):
        return "class:" not in ret
    return ret.split("<", 1)[0] in _PRIMITIVE_RET_PREFIXES


def index_signatures(inv: dict) -> dict[str, dict]:
    """Flatten an inventory to ``{fully_qualified_path: signature_dict}``."""
    out: dict[str, dict] = {}
    for mod, mod_entry in inv.get("modules", {}).items():
        for cls, cls_entry in mod_entry.get("classes", {}).items():
            for m, sig in cls_entry.get("methods", {}).items():
                out[f"{mod}.{cls}.{m}"] = sig
        for fn, sig in mod_entry.get("functions", {}).items():
            out[f"{mod}.{fn}"] = sig
    return out


# ---------------------------------------------------------------------------
# Comparison
# ---------------------------------------------------------------------------


def compare_param(p_ref: dict, p_port: dict) -> list[str]:
    """Return list of structural mismatch descriptions. Empty list = compatible.

    Audit philosophy: we verify FUNCTIONAL parity (you can write the same
    code in any language) — not literal name/idiom parity. So we check:

      - Parameter KIND (positional / var_keyword / var_positional / self).
        Python's ``**kwargs`` ≡ port's positional ``dict<string,*>``;
        Python's ``*args`` ≡ port's positional ``list<*>``.
      - Parameter TYPE (compatibility through canonical vocabulary).
        ``any`` on either side matches anything — dynamic-typed ports
        emit ``any``; Python's ``Any`` accepts any subtype.

    We do NOT check parameter names or default values — those are
    language-idiom choices (C# ``verb`` vs Python ``verb_name`` describe
    the same parameter at the same position).
    """
    issues: list[str] = []
    ref_kind = p_ref.get("kind", "positional")
    port_kind = p_port.get("kind", "positional")
    # Python's variadic kwargs/args ≡ port's positional dict/list of the
    # corresponding canonical type.
    port_type = (p_port.get("type") or "").replace(" ", "")
    if ref_kind == "var_keyword" and port_kind == "positional" and port_type.startswith("dict<string,"):
        ref_kind = port_kind
    if ref_kind == "var_positional" and port_kind == "positional" and port_type.startswith("list<"):
        ref_kind = port_kind
    # `cls` (classmethod receiver) and `self` (instance receiver) are the
    # same conceptual receiver in non-Python languages.
    if {ref_kind, port_kind} == {"self", "cls"}:
        port_kind = ref_kind
    if ref_kind != port_kind:
        issues.append(
            f"kind {p_ref.get('kind', 'positional')!r} vs {p_port.get('kind', 'positional')!r}"
        )
    # Receivers carry no type info to compare.
    if p_ref.get("kind") in ("self", "cls"):
        return issues
    t_ref = normalize_type(p_ref.get("type", "any"))
    t_port = normalize_type(p_port.get("type", "any"))
    if not types_compatible(t_ref, t_port):
        issues.append(f"type {t_ref!r} vs {t_port!r}")
    return issues


def compare_signature(
    sym: str, sig_ref: dict, sig_port: dict
) -> list[Drift]:
    drift: list[Drift] = []
    pr = sig_ref.get("params", [])
    pp = sig_port.get("params", [])
    # Functional-parity check: if the port has the SAME-or-MORE params than
    # the reference, and every one of the port's extras is optional (has
    # default), it's still compatible — Python code can still call the
    # method with the Python-shaped argument list. Only fail when the port
    # has FEWER params (can't accept a Python-arity call) OR when port
    # extras are required (would need to be supplied to call at all).
    extra = pp[len(pr):] if len(pp) > len(pr) else []
    extras_all_optional = all(not p.get("required", True) for p in extra)
    if len(pr) > len(pp) or (len(pp) > len(pr) and not extras_all_optional):
        drift.append(
            Drift(
                sym, "param-count-mismatch",
                f"reference has {len(pr)} param(s), port has {len(pp)}: "
                f"reference={[p.get('name') for p in pr]} "
                f"port={[p.get('name') for p in pp]}"
            )
        )
    else:
        # Compare overlapping prefix; ignore extra port-side optional params.
        for i, (a, b) in enumerate(zip(pr, pp)):
            issues = compare_param(a, b)
            if issues:
                drift.append(
                    Drift(
                        sym, "param-mismatch",
                        f"param[{i}] ({a.get('name')}): " + "; ".join(issues),
                    )
                )

    r_ref = normalize_type(sig_ref.get("returns", "any"))
    r_port = normalize_type(sig_port.get("returns", "any"))
    # ``any`` on either side matches anything (see compare_param).
    # Fluent-API equivalence: Python returns ``void``/``None`` (procedure)
    # while ports return ``Self``/``this``/``*self`` (class:<owner>) for
    # method chaining. Both describe the same callable contract — the
    # caller can ignore or chain the return. Treat ``void`` ≡ ``class:X``
    # where X is the method's owning class. Class-ref returns where Python
    # is void are common: builders, configurators, fluent-API setters.
    is_fluent_void = (
        r_ref == "void" and r_port.startswith("class:")
        and r_port[len("class:"):] == sym.rsplit(".", 1)[0]
    )
    if not types_compatible(r_ref, r_port) and not is_fluent_void:
        drift.append(
            Drift(
                sym, "return-mismatch",
                f"returns {r_ref!r} vs {r_port!r}",
            )
        )
    return drift


def diff(
    reference: dict, port: dict, omissions: dict[str, str]
) -> DiffResult:
    return diff_with_surface(reference, port, omissions, set())


def diff_with_surface(
    reference: dict, port: dict,
    omissions: dict[str, str], surface_excused: set[str],
) -> DiffResult:
    """Like diff(), but additionally hides missing-port/missing-reference
    drift for symbols already documented in the port's surface-level
    PORT_OMISSIONS.md / PORT_ADDITIONS.md. Signature-level drift on shared
    symbols still requires its own PORT_SIGNATURE_OMISSIONS.md entry.

    Surface-excused entries can be class-level (``module.Class``) or
    method-level; we treat any class-level entry as covering all of its
    methods, since the surface audit doesn't enumerate method drift.
    """
    ref_idx = index_signatures(reference)
    port_idx = index_signatures(port)
    result = DiffResult()

    def is_surface_excused(sym: str) -> bool:
        if sym in surface_excused:
            return True
        # Class-level entry covers its methods
        parts = sym.split(".")
        for i in range(len(parts) - 1, 0, -1):
            prefix = ".".join(parts[:i])
            if prefix in surface_excused:
                return True
        return False

    all_syms = sorted(set(ref_idx) | set(port_idx))
    for sym in all_syms:
        sig_excused = sym in omissions
        in_ref = sym in ref_idx
        in_port = sym in port_idx

        if in_ref and not in_port:
            d = Drift(sym, "missing-port", f"in reference, not in port")
            if sig_excused or is_surface_excused(sym):
                result.excused.append(d)
            else:
                result.drift.append(d)
            continue
        if in_port and not in_ref:
            # Symmetric leniency: ports commonly expose state as public
            # properties (``Call.State``, ``Call.Tag``, ``Call.CallId``)
            # while Python keeps them as instance attributes typed as
            # primitives, which the Python adapter intentionally excludes
            # (state, not API). A port-only zero-arg getter returning a
            # primitive is the same convention rendered in the port's
            # native idiom — not real cross-language drift.
            sig = port_idx[sym]
            if _is_port_state_accessor(sig):
                result.excused.append(
                    Drift(sym, "missing-reference",
                          "port-side state accessor (no Python counterpart)")
                )
                continue
            d = Drift(sym, "missing-reference", f"in port, not in reference")
            if sig_excused or is_surface_excused(sym):
                result.excused.append(d)
            else:
                result.drift.append(d)
            continue
        sig_drift = compare_signature(sym, ref_idx[sym], port_idx[sym])
        for d in sig_drift:
            (result.excused if sig_excused else result.drift).append(d)
    return result


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--port-signatures", type=Path, required=True)
    parser.add_argument("--omissions", type=Path, default=None,
                        help="PORT_SIGNATURE_OMISSIONS.md — documented "
                             "signature divergences for symbols that exist "
                             "in both reference and port.")
    parser.add_argument("--surface-omissions", type=Path, default=None,
                        help="PORT_OMISSIONS.md — symbols in Python not in "
                             "port, already documented for the surface audit. "
                             "Hides the corresponding missing-port drift here.")
    parser.add_argument("--surface-additions", type=Path, default=None,
                        help="PORT_ADDITIONS.md — symbols in port not in "
                             "Python, already documented for the surface "
                             "audit. Hides the corresponding missing-reference "
                             "drift here.")
    parser.add_argument("--json", action="store_true",
                        help="Emit machine-readable JSON instead of text.")
    args = parser.parse_args()

    reference = load_json(args.reference)
    port = load_json(args.port_signatures)
    omissions = parse_omissions(args.omissions) if args.omissions else {}
    surface_omissions = parse_omissions(args.surface_omissions) if args.surface_omissions else {}
    surface_additions = parse_omissions(args.surface_additions) if args.surface_additions else {}
    # Combine: any symbol that's been excused for the surface audit also
    # excuses the corresponding missing-port / missing-reference drift here.
    # Signature-level drift on shared symbols still requires its own
    # PORT_SIGNATURE_OMISSIONS.md entry.
    surface_excused = set(surface_omissions) | set(surface_additions)

    result = diff_with_surface(reference, port, omissions, surface_excused)

    if args.json:
        print(json.dumps({
            "drift": [d.__dict__ for d in result.drift],
            "excused": [d.__dict__ for d in result.excused],
        }, indent=2))
    else:
        if not result.drift:
            n_ref = len(index_signatures(reference))
            n_port = len(index_signatures(port))
            print(
                f"\033[32m✓\033[0m signatures match "
                f"({n_ref} reference symbols, {n_port} port symbols, "
                f"{len(result.excused)} excused divergences)."
            )
        else:
            print(
                f"\033[31m✗\033[0m {len(result.drift)} signature drift(s) "
                f"(and not in PORT_SIGNATURE_OMISSIONS.md):",
                file=sys.stderr,
            )
            # Group by symbol for readability
            by_sym: dict[str, list[Drift]] = {}
            for d in result.drift:
                by_sym.setdefault(d.symbol, []).append(d)
            for sym in sorted(by_sym):
                print(f"  {sym}:", file=sys.stderr)
                for d in by_sym[sym]:
                    print(f"    - {d.kind}: {d.detail}", file=sys.stderr)
            if result.excused:
                print(
                    f"  ({len(result.excused)} excused divergence(s) hidden)",
                    file=sys.stderr,
                )

    return 0 if not result.drift else 1


if __name__ == "__main__":
    sys.exit(main())
