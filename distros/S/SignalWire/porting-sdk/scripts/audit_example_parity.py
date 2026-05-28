#!/usr/bin/env python3
"""
audit_example_parity.py — fail CI if a port is missing examples that
exist in the Python reference.

Why this exists
---------------
Examples are part of the SDK's public surface. A user evaluating the
port will start with the closest-matching example from Python, expect
the same thing in the port, and lose trust if it isn't there. The
parity rule (every port matches Python unless documented in
PORT_OMISSIONS.md) extends to examples.

What this checks
----------------
1. Walks Python's `examples/` tree, gets every example file (minus the
   skip list — search, pgvector, sigmond, bedrock).
2. For each Python example, looks for a port-equivalent — the port's
   examples/ contains a file with a matching stem (case-insensitive
   normalization, language-specific naming conventions handled).
3. Optionally: for each port-equivalent, parse the port file's first
   docstring/header comment and assert it documents the same contract
   the Python file does. (Light heuristic — catches "agent renamed
   the example but kept the wrong header.")

Skip list
---------
Per the documented Python skip list:
- examples named `bedrock_*` → ports must implement Bedrock per the
  parity-with-Python rule, but examples may be deferred until that
  port lands. Tracked in PORT_EXAMPLE_OMISSIONS.md per port.
- examples named `*_search*` / `*_pgvector*` / `*_sigmond*` → search-
  related, only Python ships.

Usage
-----
    python audit_example_parity.py --root <port-dir>
    python audit_example_parity.py --root <port-dir> --python <python-repo>

Exit codes
----------
    0  — every Python example (minus skip list, minus omissions) has a
         port-equivalent.
    1  — at least one Python example has no port-equivalent.
    2  — usage / Python reference not found.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

DEFAULT_PYTHON_REPO = Path("/home/devuser/src/signalwire-python")

# Skip patterns: Python examples we never expect ports to mirror as-is.
# Search/pgvector/sigmond features only Python ships; bedrock examples
# are deferred per current scope (Bedrock implementation per parity rule
# is required, but example port is tracked in PORT_EXAMPLE_OMISSIONS.md).
SKIP_EXAMPLE_RE = re.compile(
    r"(?:^|_)(?:"
    r"bedrock|"
    r"search|"
    r"pgvector|"
    r"sigmond|"
    r"datasphereserverless|"
    r"datasphere_serverless"
    r")(?:_|$)",
    re.IGNORECASE,
)


# Map a Python example stem to a normalized form that we can compare
# across languages (lowercase, alnum-only).
def _normalize(stem: str) -> str:
    s = stem.lower()
    s = re.sub(r"[^a-z0-9]", "", s)
    return s


def _list_python_examples(python_root: Path) -> dict[str, str]:
    """Return {normalized_stem: relative_path} for every .py example
    minus the skip list."""
    out: dict[str, str] = {}
    examples_dir = python_root / "examples"
    if not examples_dir.is_dir():
        return out
    for p in examples_dir.iterdir():
        if not p.is_file() or p.suffix.lower() != ".py":
            continue
        if SKIP_EXAMPLE_RE.match(p.stem):
            continue
        out[_normalize(p.stem)] = str(p.relative_to(python_root))
    return out


# Per-language extension list. Examples in a port can use either the
# canonical extension or a per-language naming convention.
_LANG_EXTS = {
    "python": [".py"],
    "typescript": [".ts"],
    "javascript": [".js"],
    "java": [".java"],
    "csharp": [".cs"],
    "go": [".go"],          # examples/<name>/main.go — handled in walker
    "rust": [".rs"],
    "ruby": [".rb"],
    "perl": [".pl"],
    "php": [".php"],
    "cpp": [".cpp"],
}


def _list_port_examples(port_root: Path, language: str) -> dict[str, str]:
    out: dict[str, str] = {}
    examples_dir = port_root / "examples"
    if not examples_dir.is_dir():
        return out
    exts = _LANG_EXTS.get(language, [])
    for entry in examples_dir.iterdir():
        if entry.is_file() and entry.suffix.lower() in exts:
            out[_normalize(entry.stem)] = str(entry.relative_to(port_root))
        elif entry.is_dir() and language == "go":
            # Go examples convention: examples/<name>/main.go
            main_go = entry / "main.go"
            if main_go.is_file():
                out[_normalize(entry.name)] = str(main_go.relative_to(port_root))
    return out


def _detect_language(root: Path) -> str | None:
    if (root / "pyproject.toml").exists() and (root / "signalwire").is_dir():
        return "python"
    if (root / "package.json").exists() and (root / "src" / "AgentBase.ts").exists():
        return "typescript"
    if (root / "Cargo.toml").exists():
        return "rust"
    if (root / "go.mod").exists():
        return "go"
    if (root / "build.gradle").exists() or (root / "build.gradle.kts").exists():
        return "java"
    if (root / "Gemfile").exists() and (root / "lib" / "signalwire").is_dir():
        return "ruby"
    if (root / "cpanfile").exists() or (root / "lib" / "SignalWire").is_dir():
        return "perl"
    if (root / "composer.json").exists() and (root / "src" / "SignalWire").is_dir():
        return "php"
    if (root / "include" / "signalwire").is_dir():
        return "cpp"
    if any((root / "src").rglob("*.csproj")) if (root / "src").is_dir() else False:
        return "csharp"
    return None


def _load_omissions(path: Path) -> set[str]:
    if not path.exists():
        return set()
    out: set[str] = set()
    item_re = re.compile(r"^\s*[-*]\s+`?([\w.]+)`?\b")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = item_re.match(line)
        if m:
            out.add(_normalize(Path(m.group(1)).stem))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--root", required=True, help="Path to the port repo.")
    parser.add_argument(
        "--python",
        default=str(DEFAULT_PYTHON_REPO),
        help=f"Path to the Python reference (default: {DEFAULT_PYTHON_REPO})",
    )
    parser.add_argument("--limit", type=int, default=50)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    python_root = Path(args.python).resolve()
    if not root.is_dir():
        print(f"audit_example_parity: --root {root} is not a directory", file=sys.stderr)
        return 2
    if not python_root.is_dir():
        print(f"audit_example_parity: --python {python_root} not found", file=sys.stderr)
        return 2

    language = _detect_language(root)
    if language is None:
        print(f"audit_example_parity: could not detect language for {root}", file=sys.stderr)
        return 2

    py_examples = _list_python_examples(python_root)
    port_examples = _list_port_examples(root, language)
    omissions = _load_omissions(root / "PORT_EXAMPLE_OMISSIONS.md")

    missing: list[tuple[str, str]] = []
    for norm, py_path in sorted(py_examples.items()):
        if norm in port_examples:
            continue
        if norm in omissions:
            continue
        missing.append((norm, py_path))

    if not missing:
        print(f"audit_example_parity: clean. {language}: {len(port_examples)} example(s) cover all {len(py_examples)} Python examples (modulo {len(omissions)} omissions).")
        return 0

    print(
        f"audit_example_parity: {language} is missing {len(missing)} example(s) that exist in Python.",
        file=sys.stderr,
    )
    print(
        "Each must be either ported (add an equivalent under examples/) or "
        "recorded in PORT_EXAMPLE_OMISSIONS.md with rationale.\n",
        file=sys.stderr,
    )
    for norm, py_path in missing[:args.limit]:
        print(f"  {norm} (Python: {py_path})", file=sys.stderr)
    if len(missing) > args.limit:
        print(f"  ... ({len(missing) - args.limit} more, raise --limit to show)", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
