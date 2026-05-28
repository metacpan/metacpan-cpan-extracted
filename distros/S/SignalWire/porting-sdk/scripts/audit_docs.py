#!/usr/bin/env python3
"""audit_docs.py — catch phantom-API references in docs and examples.

Every method or class referenced in a port's documentation or example file
must resolve to a real symbol in the port's source. The Java/C++ SDK shipped
``rest/docs/fabric.md`` promising ``assign_phone_route`` + ``swml_webhooks.create``
— methods that had never been implemented. The checklist let it through because
nothing cross-checked doc promises against the actual code.

This script walks a port's doc and example directories, extracts method-call
patterns from fenced code blocks, and fails if any reference doesn't exist in
the port's ``port_surface.json`` inventory. Language-agnostic — works for
every port because it operates on the JSON surface, not language AST.

Usage:
    python3 audit_docs.py --surface port_surface.json
    python3 audit_docs.py --surface port_surface.json --doc-dir docs --doc-dir examples
    python3 audit_docs.py --surface port_surface.json --ignore IGNORE.md

The ``IGNORE.md`` file (one name per line, ``# comments`` allowed) lists
identifiers to skip — use for external SDK methods (``os.environ.get``,
``process.env``), stdlib calls, or intentional future-reference placeholders.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path


# Method-call pattern in a code block: something that looks like
# ``.identifier(`` (Python/JS/Java/Ruby/Perl/C++/Rust/Go style) or
# ``->identifier(`` (PHP / C++ pointer syntax). The identifier must be
# at least two chars to reduce noise like ``f(`` / ``x(``. Name picked is
# immediately before the ``(``. Handles both chained and simple calls.
METHOD_CALL_RE = re.compile(r"(?:\.|->)([A-Za-z_][A-Za-z0-9_]{1,})\s*\(")

# Fenced code-block pattern in markdown — grabs the body of ``` ... ```.
CODE_BLOCK_RE = re.compile(r"```(?:\w+)?\n(.*?)```", re.DOTALL)

# Default doc directories. CLI can override.
DEFAULT_DOC_DIRS = (
    "docs", "rest/docs", "relay/docs",
    "examples", "rest/examples", "relay/examples",
)

# Built-in identifiers that are ubiquitous and not interesting to flag.
# The per-port IGNORE.md should be used for port-specific external calls.
UNIVERSAL_IGNORES = frozenset({
    # common pythonic builtins
    "get", "set", "append", "extend", "items", "keys", "values", "pop",
    "join", "split", "strip", "replace", "format", "startswith", "endswith",
    "lower", "upper", "find", "index", "count", "copy", "sort", "sorted",
    "loads", "dumps", "read", "write", "close", "open", "exists", "isfile",
    "isdir", "mkdir", "now", "today", "strftime", "strptime",
    # common testing / mocking
    "assert_called", "assert_called_with", "assert_called_once",
    "assert_called_once_with", "assert_any_call", "return_value",
    # common serverless / env / JSON
    "getenv", "environ", "parse", "stringify", "encode", "decode",
    "toString", "valueOf",
    # HTTP client basics
    "request", "post", "put", "patch", "delete", "head", "options",
    "status_code", "json", "text", "raise_for_status",
    # unit test frameworks
    "assertEqual", "assertTrue", "assertFalse", "assertRaises",
    "assertIn", "assertNotIn", "assertIsNone", "assertIsNotNone",
    "to", "toBe", "toEqual", "toMatch", "toContain", "toThrow",
    "describe", "it", "expect", "beforeEach", "afterEach",
    # language-level
    "map", "filter", "reduce", "forEach", "then", "catch", "finally",
    "push", "shift", "unshift", "slice", "splice",
    # one-letter / two-letter names that are almost always noise
})


@dataclass
class AuditResult:
    unresolved: dict[str, list[tuple[str, int, str]]] = field(default_factory=dict)
    total_calls: int = 0
    resolved_calls: int = 0

    @property
    def drift(self) -> bool:
        return bool(self.unresolved)


def _snake_to_camel(name: str) -> str:
    """``snake_case`` → ``camelCase`` (Python-canonical → PHP/Java/JS idiom).

    ``__init__`` and other dunder names are returned unchanged.
    Single-segment names (no underscore) are returned unchanged.
    """
    if name.startswith("_") or "_" not in name:
        return name
    parts = name.split("_")
    return parts[0] + "".join(p.title() for p in parts[1:] if p)


def _snake_to_pascal(name: str) -> str:
    """``snake_case`` → ``PascalCase`` (Python-canonical → C#/.NET idiom).

    Dunder names returned unchanged. Single-segment lowercase names are
    title-cased ("name" -> "Name") so .NET property accessors line up.
    """
    if name.startswith("_"):
        return name
    parts = name.split("_")
    return "".join(p.title() for p in parts if p)


def load_surface_methods(surface_path: Path) -> set[str]:
    """Return every method, class, and function name from ``port_surface.json``.

    Each snake_case method name is also added in its ``camelCase`` and
    ``PascalCase`` forms (with optional ``Async`` suffix for .NET) so
    ports that emit native-cased examples line up against the canonical
    snake_case surface. The translation is purely cosmetic — the methods
    are the same either way.
    """
    data = json.loads(surface_path.read_text(encoding="utf-8"))
    names: set[str] = set()
    def add_translations(name: str) -> None:
        names.add(name)
        camel = _snake_to_camel(name)
        pascal = _snake_to_pascal(name)
        names.add(camel)
        names.add(pascal)
        # .NET appends Async to async methods; honour both forms.
        if not name.startswith("_"):
            names.add(camel + "Async")
            names.add(pascal + "Async")
    for mod, entry in data.get("modules", {}).items():
        for cls, methods in entry.get("classes", {}).items():
            names.add(cls)
            for method in methods:
                add_translations(method)
        for fn in entry.get("functions", []):
            add_translations(fn)
    return names


def load_ignore_list(ignore_path: Path | None) -> set[str]:
    if ignore_path is None or not ignore_path.is_file():
        return set()
    ignored: set[str] = set()
    for raw in ignore_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        # Support "name" or "name: rationale"
        name = line.split(":", 1)[0].strip()
        if name:
            ignored.add(name)
    return ignored


def extract_method_calls(text: str) -> list[tuple[int, str]]:
    """Return [(line_number, method_name)] from fenced code blocks."""
    calls: list[tuple[int, str]] = []
    for block_match in CODE_BLOCK_RE.finditer(text):
        block_start = text[: block_match.start()].count("\n") + 2
        body = block_match.group(1)
        for call in METHOD_CALL_RE.finditer(body):
            line_offset = body[: call.start()].count("\n")
            calls.append((block_start + line_offset, call.group(1)))
    return calls


def audit_port(
    root: Path, surface_path: Path, doc_dirs: list[str],
    ignore_path: Path | None,
) -> AuditResult:
    known = load_surface_methods(surface_path)
    ignores = UNIVERSAL_IGNORES | load_ignore_list(ignore_path)
    result = AuditResult()

    for rel in doc_dirs:
        base = root / rel
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            if path.suffix not in (".md", ".py", ".ts", ".mjs", ".js",
                                    ".go", ".java", ".rb", ".pm", ".pl",
                                    ".cpp", ".hpp", ".h", ".rs", ".php",
                                    ".cs", ".kt"):
                continue
            # Skip build artifact directories. These contain auto-generated
            # files (AssemblyInfo.cs, .d.ts type stubs, compiled bytecode
            # masquerading as text) that reference framework-only symbols
            # outside the port's surface and aren't real doc/example content.
            parts_set = set(path.relative_to(base).parts)
            if parts_set & {"obj", "bin", "build", "target", "node_modules",
                              "_audit_examples", "dist", "out", ".gradle",
                              "__pycache__", ".venv", "venv"}:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue

            # For markdown, parse code blocks. For source files (examples),
            # treat the whole file as a code block.
            if path.suffix == ".md":
                calls = extract_method_calls(text)
            else:
                calls = [
                    (i + 1, m.group(1))
                    for i, line in enumerate(text.splitlines())
                    for m in METHOD_CALL_RE.finditer(line)
                ]

            rel_path = str(path.relative_to(root))
            for lineno, name in calls:
                result.total_calls += 1
                if name in ignores:
                    continue
                if name in known:
                    result.resolved_calls += 1
                    continue
                # Unresolved. Record.
                result.unresolved.setdefault(name, []).append(
                    (rel_path, lineno, name)
                )

    return result


def print_human(result: AuditResult) -> bool:
    if not result.drift:
        print(f"\033[32m✓\033[0m docs/examples reference only known symbols "
              f"({result.resolved_calls} resolved / {result.total_calls} total)")
        return False
    print(f"\033[31m✗\033[0m {len(result.unresolved)} unresolved symbol name(s) "
          f"in docs/examples:")
    for name in sorted(result.unresolved):
        hits = result.unresolved[name]
        print(f"    {name}  ({len(hits)} hit(s))")
        for path, lineno, _ in hits[:5]:
            print(f"        {path}:{lineno}")
        if len(hits) > 5:
            print(f"        ... and {len(hits) - 5} more")
    print()
    print("Fix each reference by: (a) implementing the method, "
          "(b) correcting the doc, or (c) adding the name to DOC_AUDIT_IGNORE.md "
          "with a one-line rationale (external SDK, intentional placeholder, etc).")
    return True


def print_json(result: AuditResult) -> bool:
    payload = {
        "drift": result.drift,
        "total_calls": result.total_calls,
        "resolved_calls": result.resolved_calls,
        "unresolved": {
            name: [{"path": p, "line": l} for p, l, _ in hits]
            for name, hits in result.unresolved.items()
        },
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return result.drift


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd(),
                        help="Port repo root (default: cwd)")
    parser.add_argument("--surface", type=Path, required=True,
                        help="Path to port_surface.json")
    parser.add_argument("--doc-dir", action="append", default=None,
                        help="Doc/example directory (may repeat). "
                             f"Default: {list(DEFAULT_DOC_DIRS)}")
    parser.add_argument("--ignore", type=Path, default=None,
                        help="Path to DOC_AUDIT_IGNORE.md")
    parser.add_argument("--json", action="store_true",
                        help="Emit JSON report")
    args = parser.parse_args(argv)

    doc_dirs = args.doc_dir if args.doc_dir else list(DEFAULT_DOC_DIRS)

    if not args.surface.is_file():
        print(f"error: surface JSON not found at {args.surface}",
              file=sys.stderr)
        return 2

    result = audit_port(args.root, args.surface, doc_dirs, args.ignore)
    emit = print_json if args.json else print_human
    drift = emit(result)
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
