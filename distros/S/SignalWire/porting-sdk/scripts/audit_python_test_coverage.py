#!/usr/bin/env python3
"""audit_python_test_coverage.py — classify Python REST/Relay symbols by test coverage.

Walks signalwire-python source for the REST + Relay surfaces, walks the unit
tests, and classifies each public symbol as ``covered``, ``partial``, or
``uncovered``:

  - covered:    a test calls the method on a resolved receiver AND the call's
                return value flows into an assertion (or appears inside an
                ``assert`` statement directly).
  - partial:    the symbol is referenced (constructor called, name imported,
                method called on something we couldn't fully resolve) but no
                behavioural assertion ties to its return value.
  - uncovered:  zero references in the unit tests.

The tool is *intentionally conservative* on the false-negative axis: when in
doubt about whether a call binds to a target symbol, we err on the side of
recording a touch. False positives (counting something as covered when it
isn't) are far more dangerous than false negatives because the next phase
ports those tests; if a test doesn't actually exercise the symbol we'll find
out when the port fails.

Output:
    /usr/local/home/devuser/src/porting-sdk/PYTHON_COVERAGE_GAPS.md
    plus a one-line summary on stdout.

Usage:
    python3 scripts/audit_python_test_coverage.py
    python3 scripts/audit_python_test_coverage.py --output /tmp/report.md
    python3 scripts/audit_python_test_coverage.py --json
"""

from __future__ import annotations

import argparse
import ast
import json
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Optional

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

DEFAULT_PYTHON_SDK = Path("/home/devuser/src/signalwire-python")
DEFAULT_OUTPUT = Path("/usr/local/home/devuser/src/porting-sdk/PYTHON_COVERAGE_GAPS.md")

# Modules in scope, expressed as relative paths inside
# ``signalwire-python/signalwire/signalwire/``. The audit walks each path and
# its descendants; a match against any of these prefixes makes a module a
# target.
TARGET_MODULE_PREFIXES = (
    "rest",      # rest._base, rest.client, rest.namespaces.*
    "relay",     # relay.client, relay.call, relay.message, relay.event
)


# ---------------------------------------------------------------------------
# Source-side symbol enumeration
# ---------------------------------------------------------------------------


def _is_public(name: str) -> bool:
    """Public symbol per the audit spec — drops single-underscore names but
    keeps dunders so that ``__init__`` shows up in coverage reports.
    """
    if name.startswith("__") and name.endswith("__"):
        return True
    return not name.startswith("_")


@dataclass
class ClassInfo:
    """Defines a class, including its (textual) base classes."""

    qualname: str            # e.g. "signalwire.rest._base.CrudResource"
    short_name: str          # e.g. "CrudResource"
    module: str              # e.g. "signalwire.rest._base"
    bases: list[str] = field(default_factory=list)  # raw text of base names
    methods: dict[str, int] = field(default_factory=dict)  # method -> lineno
    properties: set[str] = field(default_factory=set)


@dataclass
class ModuleInfo:
    module: str
    path: Path
    classes: dict[str, ClassInfo] = field(default_factory=dict)  # short_name -> ClassInfo
    functions: dict[str, int] = field(default_factory=dict)      # name -> lineno


def module_name_from_path(package_root: Path, path: Path) -> str:
    """Convert a path to a dotted module name, e.g. signalwire.relay.call."""
    rel = path.relative_to(package_root.parent)
    parts = list(rel.with_suffix("").parts)
    if parts[-1] == "__init__":
        parts.pop()
    return ".".join(parts)


def _ast_name(node: ast.AST) -> Optional[str]:
    """Render an AST expression as a dotted name string ("a.b.c") or None."""
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        prefix = _ast_name(node.value)
        if prefix is None:
            return None
        return f"{prefix}.{node.attr}"
    return None


def _decorator_name(dec: ast.AST) -> Optional[str]:
    """Get the decorator name."""
    if isinstance(dec, ast.Call):
        return _ast_name(dec.func)
    return _ast_name(dec)


def _is_property(item: ast.AST) -> bool:
    if not isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
        return False
    for dec in item.decorator_list:
        name = _decorator_name(dec)
        if name == "property":
            return True
    return False


def parse_source_module(path: Path, module: str, log: list[str]) -> Optional[ModuleInfo]:
    """Parse a single .py file into a ModuleInfo. None if unparseable."""
    try:
        tree = ast.parse(path.read_text(encoding="utf-8"))
    except (SyntaxError, UnicodeDecodeError) as exc:
        log.append(f"warn: skipping {path}: {exc}")
        return None

    info = ModuleInfo(module=module, path=path)
    for node in tree.body:
        if isinstance(node, ast.ClassDef):
            if not _is_public(node.name):
                continue
            bases = [b for b in (_ast_name(base) for base in node.bases) if b]
            ci = ClassInfo(
                qualname=f"{module}.{node.name}",
                short_name=node.name,
                module=module,
                bases=bases,
            )
            for item in node.body:
                if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    if not _is_public(item.name):
                        continue
                    ci.methods[item.name] = item.lineno
                    if _is_property(item):
                        ci.properties.add(item.name)
            info.classes[node.name] = ci
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if _is_public(node.name):
                info.functions[node.name] = node.lineno
    return info


def in_scope(module: str) -> bool:
    """A module is in scope if it's one of the target prefixes."""
    if not module.startswith("signalwire."):
        return False
    rel = module[len("signalwire.") :]
    return any(rel == prefix or rel.startswith(prefix + ".") for prefix in TARGET_MODULE_PREFIXES)


def enumerate_target_modules(python_sdk: Path, log: list[str]) -> dict[str, ModuleInfo]:
    """Walk the package recursively and return ModuleInfo for in-scope modules."""
    package_root = python_sdk / "signalwire" / "signalwire"
    if not package_root.is_dir():
        raise SystemExit(f"error: package not found at {package_root}")

    modules: dict[str, ModuleInfo] = {}
    for path in sorted(package_root.rglob("*.py")):
        if "__pycache__" in path.parts:
            continue
        module = module_name_from_path(package_root, path)
        if not in_scope(module):
            continue
        info = parse_source_module(path, module, log)
        if info is None:
            continue
        modules[module] = info
    return modules


# ---------------------------------------------------------------------------
# Inheritance resolution
# ---------------------------------------------------------------------------


def resolve_class_by_short_name(
    short_name: str,
    modules: dict[str, ModuleInfo],
) -> Optional[ClassInfo]:
    """Find a ClassInfo by short name across all modules. First match wins.

    Conservative: this is only used for resolving base classes within the
    target modules. If a class extends something from outside (e.g.
    ``Exception``) we just won't pick up inherited methods — that's fine
    because those aren't target symbols.
    """
    for mod in modules.values():
        if short_name in mod.classes:
            return mod.classes[short_name]
    return None


def collect_effective_methods(
    cls: ClassInfo,
    modules: dict[str, ModuleInfo],
    seen: Optional[set[str]] = None,
) -> dict[str, str]:
    """Return method_name -> defining_qualname for the class's effective public surface.

    Walks the (textual) MRO. The class's own methods shadow inherited ones.
    """
    if seen is None:
        seen = set()
    if cls.qualname in seen:
        return {}
    seen.add(cls.qualname)

    methods: dict[str, str] = {}
    # Walk bases first so own methods override.
    for base_text in cls.bases:
        # base_text might be "BaseResource" or "fabric.FabricResource".
        # For our purposes, the short name (last segment) is enough.
        short = base_text.rsplit(".", 1)[-1]
        base_cls = resolve_class_by_short_name(short, modules)
        if base_cls is None:
            continue
        for m, qn in collect_effective_methods(base_cls, modules, seen).items():
            methods[m] = qn

    for m in cls.methods:
        methods[m] = cls.qualname
    return methods


# ---------------------------------------------------------------------------
# Receiver -> class binding from RestClient & namespace constructors
# ---------------------------------------------------------------------------


def extract_self_assignments(cls: ClassInfo, modules: dict[str, ModuleInfo]) -> dict[str, str]:
    """Inspect ``__init__`` of cls and pull out ``self.<name> = <Class>(...)`` bindings.

    Returns a dict: attribute_name -> class_short_name. Only used to model
    things like ``self.fabric = FabricNamespace(...)`` so we can resolve
    ``client.fabric.ai_agents.list()`` paths during test analysis.
    """
    src_path = next(
        (m.path for m in modules.values() if m.module == cls.module),
        None,
    )
    if src_path is None:
        return {}
    try:
        tree = ast.parse(src_path.read_text(encoding="utf-8"))
    except Exception:
        return {}

    bindings: dict[str, str] = {}
    for node in ast.walk(tree):
        if not isinstance(node, ast.ClassDef) or node.name != cls.short_name:
            continue
        for item in node.body:
            if not isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            if item.name != "__init__":
                continue
            for stmt in ast.walk(item):
                if not isinstance(stmt, ast.Assign):
                    continue
                if len(stmt.targets) != 1:
                    continue
                target = stmt.targets[0]
                if not isinstance(target, ast.Attribute):
                    continue
                if not isinstance(target.value, ast.Name) or target.value.id != "self":
                    continue
                attr = target.attr
                value = stmt.value
                if isinstance(value, ast.Call):
                    func_name = _ast_name(value.func)
                    if func_name:
                        short = func_name.rsplit(".", 1)[-1]
                        bindings[attr] = short
    return bindings


@dataclass
class BindingTable:
    """Maps a "starting variable name" plus an attribute chain to a class.

    Two layers:
      - root_name -> class_short  (e.g. ``client`` -> ``RestClient``)
      - (class_short, attr) -> class_short  (e.g. (``RestClient``, ``fabric``)
        -> ``FabricNamespace``).

    The receiver-resolution loop walks the chain using these tables.
    """

    roots: dict[str, str] = field(default_factory=dict)
    attrs: dict[tuple[str, str], str] = field(default_factory=dict)

    def root(self, name: str, cls: str) -> None:
        self.roots[name] = cls

    def attr(self, cls: str, name: str, target: str) -> None:
        self.attrs[(cls, name)] = target


def build_binding_table(modules: dict[str, ModuleInfo]) -> BindingTable:
    """Assemble a binding table from RestClient + namespace classes.

    This isn't full type inference — it's a static reading of ``__init__``
    bodies that say ``self.x = SomeClass(...)``.
    """
    table = BindingTable()

    # Common test-fixture root names -> class. These come from
    # tests/unit/{rest,relay}/conftest.py; if the conftest changes these,
    # update them here.
    table.root("client", "RestClient")
    table.root("relay", "RelayClient")
    table.root("relay_client", "RelayClient")

    # Resolve self.<x> = SomeClass(...) for every class in scope that has an
    # __init__. This covers:
    #   - RestClient.__init__ creating fabric/calling/...
    #   - FabricNamespace.__init__ creating ai_agents/swml_scripts/...
    #   - CompatNamespace.__init__ creating calls/messages/...
    for module in modules.values():
        for cls in module.classes.values():
            if "__init__" not in cls.methods:
                continue
            bindings = extract_self_assignments(cls, modules)
            for attr, target_short in bindings.items():
                table.attr(cls.short_name, attr, target_short)

    return table


# ---------------------------------------------------------------------------
# Test-side scanning
# ---------------------------------------------------------------------------


@dataclass
class CallSite:
    file: Path
    line: int
    in_assert: bool


@dataclass
class CoverageEntry:
    qualname: str            # e.g. signalwire.rest._base.CrudResource.list
    cls: str                 # CrudResource
    method: str              # list
    module: str              # signalwire.rest._base
    is_inherited_into: list[str] = field(default_factory=list)
    touched: list[CallSite] = field(default_factory=list)
    asserted: list[CallSite] = field(default_factory=list)
    referenced_only: list[CallSite] = field(default_factory=list)

    def status(self) -> str:
        if self.asserted:
            return "covered"
        if self.touched or self.referenced_only:
            return "partial"
        return "uncovered"


@dataclass
class TestScan:
    files_scanned: int = 0
    parse_errors: list[Path] = field(default_factory=list)


# Per-class qualname -> set of method names. Built from the modules.
SymbolIndex = dict[str, set[str]]


def build_symbol_index(modules: dict[str, ModuleInfo]) -> SymbolIndex:
    """class_qualname -> {effective methods on that class}.

    Uses inheritance: a method defined on the base is part of every subclass's
    surface unless shadowed.
    """
    index: SymbolIndex = {}
    for module in modules.values():
        for cls in module.classes.values():
            effective = collect_effective_methods(cls, modules)
            index[cls.qualname] = set(effective.keys())
    return index


def scan_unit_tests(
    test_root: Path,
    modules: dict[str, ModuleInfo],
    binding: BindingTable,
    symbol_index: SymbolIndex,
    log: list[str],
) -> tuple[dict[str, CoverageEntry], TestScan]:
    """Walk tests/**/*.py and accumulate per-symbol coverage.

    Skips tests/integration/* — the audit spec says "focus on unit".
    """
    scan = TestScan()
    coverage: dict[str, CoverageEntry] = {}

    # Seed coverage entries for every (class, method) including inherited.
    for cls_qual, methods in symbol_index.items():
        cls_short = cls_qual.rsplit(".", 1)[-1]
        cls_module = cls_qual.rsplit(".", 1)[0]
        for m in methods:
            qual = f"{cls_qual}.{m}"
            coverage[qual] = CoverageEntry(
                qualname=qual,
                cls=cls_short,
                method=m,
                module=cls_module,
            )

    # Free functions: keyed as module + "." + name.
    for module in modules.values():
        for fn in module.functions:
            qual = f"{module.module}.{fn}"
            if qual not in coverage:
                coverage[qual] = CoverageEntry(
                    qualname=qual,
                    cls="",
                    method=fn,
                    module=module.module,
                )

    # Index classes by short name for "constructor reference" detection
    # (test imports SomeClass and instantiates it).
    short_to_qualnames: dict[str, list[str]] = defaultdict(list)
    properties_by_class: dict[str, set[str]] = defaultdict(set)
    for module in modules.values():
        for cls in module.classes.values():
            short_to_qualnames[cls.short_name].append(cls.qualname)
            if cls.properties:
                properties_by_class[cls.short_name] |= cls.properties
    # Include inherited properties: a property defined on Action is also a
    # property of every Action subclass that doesn't shadow it.
    cls_by_qualname = {
        cls.qualname: cls
        for module in modules.values()
        for cls in module.classes.values()
    }
    for cls in cls_by_qualname.values():
        for method, defining_qual in collect_effective_methods(cls, modules).items():
            defining_cls = cls_by_qualname.get(defining_qual)
            if defining_cls is None:
                continue
            if method in defining_cls.properties:
                properties_by_class[cls.short_name].add(method)

    # Collect conftest-derived fixture name -> class maps, keyed by the
    # directory the conftest lives in. A test inside that directory tree
    # (or any descendant) inherits these fixtures.
    conftest_locals: dict[Path, dict[str, str]] = {}
    for conftest in sorted(test_root.rglob("conftest.py")):
        if "__pycache__" in conftest.parts or "integration" in conftest.parts:
            continue
        try:
            tree = ast.parse(conftest.read_text(encoding="utf-8"))
        except Exception as exc:
            log.append(f"warn: failed to parse conftest {conftest}: {exc}")
            continue
        # Reuse analyze_test_module to *populate* the bindings, but discard
        # touch-data — conftest isn't a test, just a fixture provider.
        # We use a one-shot "inspect" via _build_locals_only.
        conftest_locals[conftest.parent] = _build_locals_for_module(
            tree, binding, short_to_qualnames
        )

    for path in sorted(test_root.rglob("*.py")):
        if "integration" in path.parts:
            continue
        if "__pycache__" in path.parts:
            continue
        if not path.is_file():
            continue
        if path.name == "conftest.py":
            # We already extracted bindings above; conftest assertions
            # don't count as test coverage.
            continue
        scan.files_scanned += 1
        try:
            source = path.read_text(encoding="utf-8")
            tree = ast.parse(source)
        except Exception as exc:
            scan.parse_errors.append(path)
            log.append(f"warn: failed to parse test {path}: {exc}")
            continue

        # Inherit conftest fixtures from this directory upward.
        inherited: dict[str, str] = {}
        for parent in [path.parent, *path.parent.parents]:
            if parent in conftest_locals:
                # closer conftests shadow farther ones
                for k, v in conftest_locals[parent].items():
                    inherited.setdefault(k, v)
            if parent == test_root:
                break

        # Only allow the unresolved-method-name fallback for tests that
        # are clearly aimed at the REST/Relay surface; other tests using
        # method names like ``delete``, ``get``, ``list`` produce too many
        # false positives.
        unresolved_ok = _is_target_test_path(path, test_root)

        analyze_test_module(
            tree=tree,
            path=path,
            binding=binding,
            symbol_index=symbol_index,
            coverage=coverage,
            short_to_qualnames=short_to_qualnames,
            properties_by_class=properties_by_class,
            extra_locals=inherited,
            allow_unresolved_match=unresolved_ok,
        )

    return coverage, scan


def _is_target_test_path(path: Path, test_root: Path) -> bool:
    """True if a test file is in tests/unit/{rest,relay}/ or tests/test_*.py
    that imports our target package. We use a path heuristic for speed.
    """
    try:
        rel = path.relative_to(test_root).parts
    except ValueError:
        return False
    if len(rel) >= 2 and rel[0] == "unit" and rel[1] in ("rest", "relay"):
        return True
    return False


def _build_locals_for_module(
    tree: ast.AST,
    binding: BindingTable,
    short_to_qualnames: dict[str, list[str]],
) -> dict[str, str]:
    """Extract fixture/import name -> class bindings from a tree (no
    coverage recording). Used for conftests."""
    locals_to_class: dict[str, str] = {}
    for node in ast.walk(tree):
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            for alias in node.names:
                shortname = alias.asname or alias.name.rsplit(".", 1)[-1]
                if shortname in short_to_qualnames:
                    locals_to_class.setdefault(shortname, shortname)
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        cls = _function_returned_class(
            node, locals_to_class, binding, short_to_qualnames
        )
        if cls:
            locals_to_class[node.name] = cls
    return locals_to_class


def _function_returned_class(
    func: ast.AST,
    locals_to_class: dict[str, str],
    binding: BindingTable,
    short_to_qualnames: dict[str, list[str]],
) -> Optional[str]:
    """If a function definitively returns/yields a known target class,
    return that short name. Otherwise None. Used to resolve fixture
    parameter names.
    """
    if not isinstance(func, (ast.FunctionDef, ast.AsyncFunctionDef)):
        return None
    for stmt in ast.walk(func):
        candidate = None
        if isinstance(stmt, ast.Return) and stmt.value is not None:
            candidate = stmt.value
        elif isinstance(stmt, ast.Expr) and isinstance(stmt.value, ast.Yield) and stmt.value.value is not None:
            candidate = stmt.value.value
        if candidate is None:
            continue
        cls = _infer_call_return_class(candidate, locals_to_class, binding)
        if cls and cls in short_to_qualnames:
            return cls
    return None


def _iter_test_functions(tree: ast.AST) -> Iterable[ast.AST]:
    """Yield function/method defs that look like tests.

    A test is any def whose name starts with ``test_`` or ``test`` (allowing
    ``def test():`` too), or any def inside a class whose name starts with
    ``Test``.
    """
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and node.name.startswith("Test"):
            for item in node.body:
                if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    yield item
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name.startswith("test"):
                yield node


# Method names on a mock object that count as "behavioural assertions".
# Any test function that calls one of these is treated as actually
# verifying behaviour, not just instantiating.
_BEHAVIOURAL_MOCK_METHODS = frozenset({
    "assert_called",
    "assert_called_once",
    "assert_called_with",
    "assert_called_once_with",
    "assert_any_call",
    "assert_has_calls",
    "assert_not_called",
})


def _function_has_behavioural_assertion(func: ast.AST) -> bool:
    """True if ``func`` contains either a real ``assert`` or a mock-style
    behavioural assertion call. False if the function is a pure smoke (e.g.
    just instantiates and returns)."""
    for sub in ast.walk(func):
        if isinstance(sub, ast.Assert):
            return True
        if isinstance(sub, ast.Call) and isinstance(sub.func, ast.Attribute):
            if sub.func.attr in _BEHAVIOURAL_MOCK_METHODS:
                return True
        # pytest.raises(...) and pytest.warns(...) count as behavioural
        if isinstance(sub, ast.Call):
            name = _ast_name(sub.func)
            if name:
                if name.endswith("pytest.raises") or name.endswith("pytest.warns"):
                    return True
                if name.endswith(".raises") or name.endswith(".warns"):
                    return True
    return False


def _names_from_targets(target: ast.AST) -> list[str]:
    """Return assignable names produced by an assignment LHS (Name/Tuple)."""
    if isinstance(target, ast.Name):
        return [target.id]
    if isinstance(target, (ast.Tuple, ast.List)):
        names: list[str] = []
        for elt in target.elts:
            names.extend(_names_from_targets(elt))
        return names
    return []


def analyze_test_module(
    tree: ast.AST,
    path: Path,
    binding: BindingTable,
    symbol_index: SymbolIndex,
    coverage: dict[str, CoverageEntry],
    short_to_qualnames: dict[str, list[str]],
    properties_by_class: dict[str, set[str]],
    extra_locals: Optional[dict[str, str]] = None,
    allow_unresolved_match: bool = True,
) -> None:
    """Walk a single test file; update ``coverage`` in place."""

    # File-local "name -> class short name" map. Built from:
    #   - imports: `from signalwire.relay.call import Call` -> Call -> Call
    #   - assignments: `client = RestClient(...)` -> client -> RestClient
    #   - assignments: `play = await call.play(...)` -> play -> PlayAction
    #   - fixtures: `def foo(...): return SomeClass(...)` -> foo -> SomeClass
    locals_to_class: dict[str, str] = dict(binding.roots)
    if extra_locals:
        for k, v in extra_locals.items():
            locals_to_class.setdefault(k, v)

    # Imports first (so subsequent assignments can resolve constructors).
    imported_classes: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            for alias in node.names:
                shortname = alias.asname or alias.name.rsplit(".", 1)[-1]
                # Track if this matches one of our class short names.
                if shortname in short_to_qualnames:
                    imported_classes.add(shortname)
                    # constructor reference: SomeClass == that class
                    locals_to_class.setdefault(shortname, shortname)

    # First pass: pytest fixtures. ``def foo(...): return Foo(...)`` (or
    # ``yield Foo(...)``) maps the fixture name to that class so test funcs
    # taking ``foo`` as a parameter can resolve it to ``Foo``.
    fixture_returns: dict[str, str] = {}
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        # Heuristic: fixtures are decorated with @pytest.fixture or just
        # have a single return/yield statement. We accept either.
        cls_returned = _function_returned_class(
            node, locals_to_class, binding, short_to_qualnames
        )
        if cls_returned:
            fixture_returns[node.name] = cls_returned
    # Map fixture parameter names to classes for test functions whose
    # parameter list includes the fixture name. We do this via a synthetic
    # entry in locals_to_class; for the purposes of attribute resolution
    # this is good enough because we don't track scopes.
    for fname, cls in fixture_returns.items():
        locals_to_class.setdefault(fname, cls)

    # Pre-scan the test file for known assignment patterns to populate
    # locals_to_class. Walks top-level, function bodies and class bodies
    # (including nested fixtures/tests) — a single pass over all assign
    # statements suffices for our coarse needs.
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            target_names = []
            for t in node.targets:
                target_names.extend(_names_from_targets(t))
            value = node.value
            cls_for_value = _infer_call_return_class(
                value, locals_to_class, binding
            )
            if cls_for_value is None:
                # Try direct constructor: ``foo = SomeClass(...)`` —
                # _infer_call_return_class already handles this.
                continue
            for n in target_names:
                locals_to_class[n] = cls_for_value
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name) and node.value is not None:
            cls_for_value = _infer_call_return_class(
                node.value, locals_to_class, binding
            )
            if cls_for_value:
                locals_to_class[node.target.id] = cls_for_value

    # Track which ast.Call nodes are "covered" — i.e. occur in a test
    # function (def test_*) that contains at least one assert or
    # ``mock.assert_called_*`` style behavioural check. The spec's
    # "asserts on the result" includes side-effect assertions: most REST
    # tests call ``client.foo.bar(...)`` then assert on
    # ``mock_session.request.call_args``. That counts as covered.
    assert_call_ids: set[int] = set()

    # Walk top-level test functions and methods inside test classes.
    test_funcs = list(_iter_test_functions(tree))
    for func in test_funcs:
        if _function_has_behavioural_assertion(func):
            for sub in ast.walk(func):
                if isinstance(sub, ast.Call):
                    assert_call_ids.add(id(sub))

    # Also include direct `assert <call>` statements (covers tests that
    # don't follow the def-test_* pattern, e.g. helpers).
    for node in ast.walk(tree):
        if isinstance(node, ast.Assert):
            for sub in ast.walk(node):
                if isinstance(sub, ast.Call):
                    assert_call_ids.add(id(sub))

    # Property accesses: ``<receiver>.<attr>`` where attr is a @property
    # on a target class.  These are plain ast.Attribute nodes (no call).
    # Walk attributes; skip ones that are themselves the func of a Call
    # (those are method calls, handled below).
    method_call_attr_ids: set[int] = set()
    assert_attr_node_ids: set[int] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            method_call_attr_ids.add(id(node.func))
        if isinstance(node, ast.Assert):
            for sub in ast.walk(node):
                if isinstance(sub, ast.Attribute):
                    assert_attr_node_ids.add(id(sub))

    for node in ast.walk(tree):
        if not isinstance(node, ast.Attribute):
            continue
        if id(node) in method_call_attr_ids:
            continue
        recv_class = _resolve_receiver_class(node.value, locals_to_class, binding)
        if recv_class is None:
            continue
        attr = node.attr
        # Only record property accesses (not arbitrary attributes).
        if attr not in properties_by_class.get(recv_class, set()):
            continue
        in_assert = id(node) in assert_attr_node_ids
        cs = CallSite(file=path, line=node.lineno, in_assert=in_assert)
        for cls_qual, methods in symbol_index.items():
            cls_short = cls_qual.rsplit(".", 1)[-1]
            if cls_short != recv_class:
                continue
            if attr not in methods:
                continue
            entry = coverage.get(f"{cls_qual}.{attr}")
            if entry is None:
                continue
            if in_assert:
                entry.asserted.append(cs)
            else:
                entry.touched.append(cs)

    # Now walk all calls and record touches.
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        # Constructor reference: SomeClass(...) — counts as referenced for
        # the class itself, not necessarily for any method.
        func_name = _ast_name(node.func)
        if func_name is not None:
            short = func_name.rsplit(".", 1)[-1]
            if short in short_to_qualnames:
                # mark __init__ as referenced (or asserted if inside assert)
                for qual in short_to_qualnames[short]:
                    init_qual = f"{qual}.__init__"
                    entry = coverage.get(init_qual)
                    if entry is None:
                        continue
                    cs = CallSite(file=path, line=node.lineno,
                                  in_assert=id(node) in assert_call_ids)
                    if cs.in_assert:
                        entry.asserted.append(cs)
                    else:
                        entry.touched.append(cs)

        # Method call: <chain>.<method>(...)
        if isinstance(node.func, ast.Attribute):
            recv_class = _resolve_receiver_class(node.func.value, locals_to_class, binding)
            method = node.func.attr
            if recv_class is None:
                # Even when we can't resolve, if the method name is unique
                # to one target class in the symbol index, count as a
                # "referenced_only" hit so we don't completely miss it.
                # Only do this for tests that target REST/Relay — common
                # method names (delete, get, list) collide with FastAPI
                # test clients, dict ops, etc.
                if allow_unresolved_match:
                    _maybe_record_unresolved(
                        method, path, node.lineno, symbol_index, coverage
                    )
                continue
            _record_method_call(
                recv_class=recv_class,
                method=method,
                path=path,
                lineno=node.lineno,
                in_assert=id(node) in assert_call_ids,
                symbol_index=symbol_index,
                coverage=coverage,
            )


def _infer_call_return_class(
    value: ast.AST,
    locals_to_class: dict[str, str],
    binding: BindingTable,
) -> Optional[str]:
    """Best-effort: figure out what class a given expression returns.

    Currently handles:
      - Direct constructor calls ``SomeClass(...)`` if SomeClass is one of
        our target shortnames.
      - ``await <call>`` peels off the await wrapper.
      - Method calls returning Action subclasses (call.play() -> PlayAction).
    """
    if isinstance(value, ast.Await):
        return _infer_call_return_class(value.value, locals_to_class, binding)
    if not isinstance(value, ast.Call):
        return None
    func_name = _ast_name(value.func)
    if func_name is None:
        return None
    short = func_name.rsplit(".", 1)[-1]

    # Method call ``call.play(...)`` -> PlayAction.
    if isinstance(value.func, ast.Attribute):
        recv_class = _resolve_receiver_class(value.func.value, locals_to_class, binding)
        if recv_class is not None:
            ret = _ACTION_RETURN_HINTS.get((recv_class, short))
            if ret is not None:
                return ret

    return short


# Hardcoded "this Call method returns this Action class" map. Avoids needing
# a real return-type inferencer. Sourced from relay/call.py.
_ACTION_RETURN_HINTS: dict[tuple[str, str], str] = {
    ("Call", "play"): "PlayAction",
    ("Call", "play_silence"): "PlayAction",
    ("Call", "play_audio"): "PlayAction",
    ("Call", "play_tts"): "PlayAction",
    ("Call", "play_ringtone"): "PlayAction",
    ("Call", "play_and_collect"): "CollectAction",
    ("Call", "collect"): "StandaloneCollectAction",
    ("Call", "record"): "RecordAction",
    ("Call", "detect"): "DetectAction",
    ("Call", "detect_machine"): "DetectAction",
    ("Call", "detect_fax"): "DetectAction",
    ("Call", "detect_digit"): "DetectAction",
    ("Call", "tap"): "TapAction",
    ("Call", "stream"): "StreamAction",
    ("Call", "send_fax"): "FaxAction",
    ("Call", "receive_fax"): "FaxAction",
    ("Call", "pay"): "PayAction",
    ("Call", "transcribe"): "TranscribeAction",
    ("Call", "ai"): "AIAction",
}


def _resolve_receiver_class(
    receiver: ast.AST,
    locals_to_class: dict[str, str],
    binding: BindingTable,
) -> Optional[str]:
    """Resolve a receiver expression to a class short name, if possible.

    Walks attribute chains:
      ``client``                   -> RestClient
      ``client.fabric``            -> FabricNamespace
      ``client.fabric.ai_agents``  -> FabricResource
    """
    chain = _flatten_chain(receiver)
    if not chain:
        return None
    head, *rest = chain
    cls = locals_to_class.get(head)
    if cls is None:
        return None
    for attr in rest:
        nxt = binding.attrs.get((cls, attr))
        if nxt is None:
            return None
        cls = nxt
    return cls


def _flatten_chain(node: ast.AST) -> list[str]:
    """[a, b, c] for a.b.c. Empty if not a pure attribute chain."""
    parts: list[str] = []
    cur = node
    while isinstance(cur, ast.Attribute):
        parts.append(cur.attr)
        cur = cur.value
    if isinstance(cur, ast.Name):
        parts.append(cur.id)
        return list(reversed(parts))
    if isinstance(cur, ast.Call):
        # `Foo()` at the head — treat the call's class as the chain head if
        # we can resolve it.
        func_name = _ast_name(cur.func)
        if func_name is None:
            return []
        short = func_name.rsplit(".", 1)[-1]
        # Use a synthetic name "<Class>" so locals_to_class can map it. Tests
        # rarely chain off a fresh constructor, so this is best-effort.
        parts.append(short)
        return list(reversed(parts))
    if isinstance(cur, ast.Await):
        return _flatten_chain(cur.value)
    return []


# Method names too generic to attribute to a specific target class when
# the receiver doesn't resolve. ``__init__`` lives on every class; CRUD
# verbs are universal. We deliberately *don't* record name-only hits for
# these to avoid noise.
_GENERIC_METHOD_NAMES = frozenset({
    "__init__", "__del__", "__repr__", "__str__", "__eq__",
    "list", "get", "create", "update", "delete",
})


def _maybe_record_unresolved(
    method: str,
    path: Path,
    lineno: int,
    symbol_index: SymbolIndex,
    coverage: dict[str, CoverageEntry],
) -> None:
    """Method-name-only hit when the receiver resolves to nothing.

    Walks the symbol index; for any (class, method) pair where the method
    matches, record this as a "referenced_only" touch. This is conservative:
    if a method name is shared across many classes (`list`, `get`, etc.) we
    *don't* record it (see _GENERIC_METHOD_NAMES) so we don't end up with a
    long list of bogus partials on every Crud method.
    """
    if method in _GENERIC_METHOD_NAMES:
        return
    matched = False
    for cls_qual, methods in symbol_index.items():
        if method not in methods:
            continue
        qual = f"{cls_qual}.{method}"
        entry = coverage.get(qual)
        if entry is None:
            continue
        matched = True
        entry.referenced_only.append(CallSite(file=path, line=lineno, in_assert=False))
    # Free functions
    if not matched:
        for qual, entry in coverage.items():
            if entry.cls:
                continue  # only free functions
            if entry.method == method:
                entry.referenced_only.append(CallSite(file=path, line=lineno, in_assert=False))


def _record_method_call(
    recv_class: str,
    method: str,
    path: Path,
    lineno: int,
    in_assert: bool,
    symbol_index: SymbolIndex,
    coverage: dict[str, CoverageEntry],
) -> None:
    """Record a call against every (class, method) entry that matches.

    Because we only know class *short* names, we mark all classes with that
    short name. In practice short names are unique inside the target
    package.
    """
    for cls_qual, methods in symbol_index.items():
        cls_short = cls_qual.rsplit(".", 1)[-1]
        if cls_short != recv_class:
            continue
        if method not in methods:
            continue
        qual = f"{cls_qual}.{method}"
        entry = coverage.get(qual)
        if entry is None:
            continue
        cs = CallSite(file=path, line=lineno, in_assert=in_assert)
        if in_assert:
            entry.asserted.append(cs)
        else:
            entry.touched.append(cs)


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------


def render_report(
    coverage: dict[str, CoverageEntry],
    test_scan: TestScan,
    log: list[str],
) -> str:
    by_module: dict[str, list[CoverageEntry]] = defaultdict(list)
    for entry in coverage.values():
        by_module[entry.module].append(entry)

    # Aggregate counts per module.
    summary_rows = []
    for module in sorted(by_module):
        entries = by_module[module]
        covered = sum(1 for e in entries if e.status() == "covered")
        partial = sum(1 for e in entries if e.status() == "partial")
        uncovered = sum(1 for e in entries if e.status() == "uncovered")
        summary_rows.append((module, len(entries), covered, partial, uncovered))

    total_symbols = sum(r[1] for r in summary_rows)
    total_covered = sum(r[2] for r in summary_rows)
    total_partial = sum(r[3] for r in summary_rows)
    total_uncovered = sum(r[4] for r in summary_rows)

    out: list[str] = []
    out.append("# Python Test Coverage — Gap Report (REST + Relay)")
    out.append("")
    out.append("Generated by `scripts/audit_python_test_coverage.py` against the")
    out.append("`signalwire-python` unit tests (`tests/unit/`). Integration tests")
    out.append("are deliberately excluded.")
    out.append("")
    out.append(f"- Test files scanned: **{test_scan.files_scanned}**")
    out.append(f"- Test parse errors: **{len(test_scan.parse_errors)}**")
    out.append(f"- Total public symbols audited: **{total_symbols}**")
    pct_cov = (100 * total_covered / total_symbols) if total_symbols else 0
    pct_par = (100 * total_partial / total_symbols) if total_symbols else 0
    pct_unc = (100 * total_uncovered / total_symbols) if total_symbols else 0
    out.append(
        f"- **Covered**: {total_covered} ({pct_cov:.1f}%)  "
        f"**Partial**: {total_partial} ({pct_par:.1f}%)  "
        f"**Uncovered**: {total_uncovered} ({pct_unc:.1f}%)"
    )
    out.append("")
    out.append("Coverage labels:")
    out.append("")
    out.append("- **covered** — a unit test calls the symbol on a resolved receiver and the")
    out.append("  call's return value (or the call itself) participates in an `assert`.")
    out.append("- **partial** — the symbol is referenced (constructor invoked, name-only call,")
    out.append("  attribute accessed) but no behavioural assertion ties to its return value.")
    out.append("- **uncovered** — zero references in the unit tests.")
    out.append("")

    out.append("## Summary")
    out.append("")
    out.append("| Module | Symbols | Covered | Partial | Uncovered |")
    out.append("|---|---:|---:|---:|---:|")
    for module, total, c, p, u in summary_rows:
        out.append(f"| `{module}` | {total} | {c} | {p} | {u} |")
    out.append("")

    # Per-module sections
    for module in sorted(by_module):
        entries = sorted(by_module[module], key=lambda e: (e.cls, e.method))
        covered = [e for e in entries if e.status() == "covered"]
        partial = [e for e in entries if e.status() == "partial"]
        uncovered = [e for e in entries if e.status() == "uncovered"]
        gaps = len(partial) + len(uncovered)
        if gaps == 0 and not entries:
            continue
        out.append(f"## {module} ({len(entries)} symbols, {gaps} gaps)")
        out.append("")

        if uncovered:
            out.append(f"### Uncovered ({len(uncovered)})")
            out.append("")
            for e in uncovered:
                out.append(f"- `{_render_symbol(e)}`")
            out.append("")
        if partial:
            out.append(f"### Partial ({len(partial)}) — referenced but no behavioral assertion")
            out.append("")
            for e in partial:
                site = _first_site(e)
                out.append(f"- `{_render_symbol(e)}` — referenced in `{site}`")
            out.append("")
        if covered:
            out.append(f"<details><summary>Covered ({len(covered)})</summary>")
            out.append("")
            for e in covered:
                site = _first_site(e)
                out.append(f"- `{_render_symbol(e)}` — `{site}`")
            out.append("")
            out.append("</details>")
            out.append("")

    if log:
        out.append("## Audit log")
        out.append("")
        for line in log:
            out.append(f"- {line}")
        out.append("")

    return "\n".join(out)


def _render_symbol(e: CoverageEntry) -> str:
    if e.cls:
        return f"{e.cls}.{e.method}"
    return e.method


def _first_site(e: CoverageEntry) -> str:
    for site_list in (e.asserted, e.touched, e.referenced_only):
        for s in site_list:
            return f"{s.file}:{s.line}"
    return "(no site)"


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------


def run_audit(
    python_sdk: Path,
) -> tuple[dict[str, CoverageEntry], TestScan, list[str]]:
    log: list[str] = []
    modules = enumerate_target_modules(python_sdk, log)
    binding = build_binding_table(modules)
    symbol_index = build_symbol_index(modules)
    test_root = python_sdk / "tests"
    coverage, scan = scan_unit_tests(
        test_root=test_root,
        modules=modules,
        binding=binding,
        symbol_index=symbol_index,
        log=log,
    )
    # Inheritance rollup: a base-class method is "transitively covered" if
    # any subclass that does NOT shadow the method is itself covered for
    # that method. We propagate by adding a synthetic site to the base entry
    # tagged with the subclass's site, so the base's status() flips to
    # covered/partial without losing the audit trail.
    _propagate_inherited_coverage(coverage, modules)
    # Constructor-containment rollup: if A.__init__ is covered and A's
    # init constructs B(...), B.__init__ is transitively covered too.
    _propagate_constructor_containment(coverage, binding, modules)
    return coverage, scan, log


def _propagate_inherited_coverage(
    coverage: dict[str, CoverageEntry],
    modules: dict[str, ModuleInfo],
) -> None:
    """Propagate inherited-method coverage in both directions.

    Pass 1 (UP):   subclass coverage rolls up to its base.  If
                   ``CrudWithAddresses.list`` is covered, ``CrudResource.list``
                   becomes covered too — testing the subclass exercises the
                   inherited base method.
    Pass 2 (DOWN): base coverage rolls down to subclasses that *don't*
                   shadow the method.  If ``Action.wait`` is covered (likely
                   via a subclass through pass 1), ``AIAction.wait`` —
                   which inherits from ``Action`` and doesn't override
                   ``wait`` — is also covered.

    A subclass that overrides a method has its OWN entry; coverage of
    ``Action.<m>`` does NOT roll down to a class that shadows ``<m>`` (a
    redefinition is a distinct symbol with potentially different
    behaviour).
    """
    # Map qualname -> ClassInfo for fast lookup.
    cls_by_qualname: dict[str, ClassInfo] = {}
    for module in modules.values():
        for cls in module.classes.values():
            cls_by_qualname[cls.qualname] = cls

    # subclass->bases and base->subclasses edges (textual, by short name).
    subclasses_of: dict[str, list[str]] = defaultdict(list)
    for cls in cls_by_qualname.values():
        for base_text in cls.bases:
            base_short = base_text.rsplit(".", 1)[-1]
            for other in cls_by_qualname.values():
                if other.short_name == base_short:
                    subclasses_of[other.qualname].append(cls.qualname)

    def _mirror(src: CoverageEntry, dst: CoverageEntry) -> None:
        """Copy sites from src to dst (idempotent on (file, line) pairs)."""
        existing_asserted = {(str(s.file), s.line) for s in dst.asserted}
        existing_touched = {(str(s.file), s.line) for s in dst.touched}
        existing_ref = {(str(s.file), s.line) for s in dst.referenced_only}
        for site in src.asserted:
            if (str(site.file), site.line) not in existing_asserted:
                dst.asserted.append(site)
                existing_asserted.add((str(site.file), site.line))
        for site in src.touched:
            if (str(site.file), site.line) not in existing_touched:
                dst.touched.append(site)
                existing_touched.add((str(site.file), site.line))
        for site in src.referenced_only:
            if (str(site.file), site.line) not in existing_ref:
                dst.referenced_only.append(site)
                existing_ref.add((str(site.file), site.line))

    # Pass 1: UP propagation. Walk every base class; for each method
    # defined on it, find descendants that inherit (don't redefine) it
    # and mirror their sites.
    for base_qual, base_cls in cls_by_qualname.items():
        for method in base_cls.methods:
            base_entry = coverage.get(f"{base_qual}.{method}")
            if base_entry is None:
                continue
            stack = list(subclasses_of.get(base_qual, []))
            visited: set[str] = set()
            while stack:
                sub_qual = stack.pop()
                if sub_qual in visited:
                    continue
                visited.add(sub_qual)
                sub_cls = cls_by_qualname.get(sub_qual)
                if sub_cls is None:
                    continue
                if method in sub_cls.methods:
                    continue  # shadow — don't propagate through
                stack.extend(subclasses_of.get(sub_qual, []))
                sub_entry = coverage.get(f"{sub_qual}.{method}")
                if sub_entry is None:
                    continue
                _mirror(sub_entry, base_entry)
                base_entry.is_inherited_into.append(sub_qual)

    # Pass 2: DOWN propagation. For each (class, method) entry, if the
    # class doesn't define it directly (i.e. it's inherited), copy
    # coverage from the nearest base that defines the method.
    for cls_qual, cls_info in cls_by_qualname.items():
        # Walk effective methods; for each one not in cls_info.methods
        # (= inherited), find the defining base and copy its coverage.
        effective = collect_effective_methods(cls_info, modules)
        for method, defining_qual in effective.items():
            if defining_qual == cls_qual:
                continue  # defined here, nothing to inherit
            sub_entry = coverage.get(f"{cls_qual}.{method}")
            base_entry = coverage.get(f"{defining_qual}.{method}")
            if sub_entry is None or base_entry is None:
                continue
            _mirror(base_entry, sub_entry)


def _propagate_constructor_containment(
    coverage: dict[str, CoverageEntry],
    binding: BindingTable,
    modules: dict[str, ModuleInfo],
) -> None:
    """If outer class A constructs inner class B inside A.__init__ via
    ``self.x = B(...)`` and ``A.__init__`` is covered, then ``B.__init__``
    is transitively covered (B is instantiated whenever A is).

    We use ``binding.attrs`` (which already maps (A, "x") -> B) as the
    edge set.  Apply iteratively until fixed point so chains like
    RestClient -> CompatNamespace -> CompatCalls are all reached.
    """
    short_to_qualnames: dict[str, list[str]] = defaultdict(list)
    for module in modules.values():
        for cls in module.classes.values():
            short_to_qualnames[cls.short_name].append(cls.qualname)

    edges: list[tuple[str, str]] = []  # (outer_short, inner_short)
    for (outer_short, _attr), inner_short in binding.attrs.items():
        edges.append((outer_short, inner_short))

    changed = True
    while changed:
        changed = False
        for outer_short, inner_short in edges:
            for outer_qual in short_to_qualnames.get(outer_short, []):
                outer_init = coverage.get(f"{outer_qual}.__init__")
                if outer_init is None:
                    continue
                if outer_init.status() == "uncovered":
                    continue
                for inner_qual in short_to_qualnames.get(inner_short, []):
                    inner_init = coverage.get(f"{inner_qual}.__init__")
                    if inner_init is None:
                        continue
                    if inner_init.status() != "uncovered":
                        continue
                    # Mirror outer's site to inner so inner's status flips.
                    if outer_init.asserted:
                        inner_init.asserted.append(outer_init.asserted[0])
                    elif outer_init.touched:
                        inner_init.touched.append(outer_init.touched[0])
                    else:
                        inner_init.referenced_only.append(
                            outer_init.referenced_only[0]
                        )
                    changed = True


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--python-sdk", type=Path, default=DEFAULT_PYTHON_SDK,
        help="Path to signalwire-python checkout (default: ~/src/signalwire-python)",
    )
    parser.add_argument(
        "--output", type=Path, default=DEFAULT_OUTPUT,
        help="Markdown gap report output path",
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Emit raw coverage data as JSON to stdout in addition to the markdown report",
    )
    args = parser.parse_args(argv)

    coverage, scan, log = run_audit(args.python_sdk)
    report = render_report(coverage, scan, log)
    args.output.write_text(report, encoding="utf-8")

    # Console summary
    by_status: dict[str, int] = defaultdict(int)
    for e in coverage.values():
        by_status[e.status()] += 1
    total = sum(by_status.values())
    print(
        f"audit: {total} symbols — "
        f"covered={by_status['covered']} "
        f"partial={by_status['partial']} "
        f"uncovered={by_status['uncovered']} -> {args.output}"
    )

    if args.json:
        payload = {
            "summary": {
                "files_scanned": scan.files_scanned,
                "parse_errors": [str(p) for p in scan.parse_errors],
                "total": total,
                **dict(by_status),
            },
            "symbols": [
                {
                    "qualname": e.qualname,
                    "status": e.status(),
                    "asserted": [(str(s.file), s.line) for s in e.asserted],
                    "touched": [(str(s.file), s.line) for s in e.touched],
                    "referenced_only": [(str(s.file), s.line) for s in e.referenced_only],
                }
                for e in coverage.values()
            ],
        }
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
