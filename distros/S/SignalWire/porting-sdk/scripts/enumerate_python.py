#!/usr/bin/env python3
"""enumerate_python.py — emit a JSON snapshot of the Python SDK's public API.

The output (``python_surface.json``) is the canonical inventory every port
must implement or explicitly opt out of. It lives in this repo so ports can
diff against a single stable artifact rather than re-parse the Python SDK.

What counts as "public":
  * A class whose name does not start with ``_``.
  * A method or function whose name does not start with a single ``_`` but
    may start with ``__`` (dunders like ``__init__`` are part of the
    constructor contract and worth pinning).
  * Only symbols defined in ``signalwire/signalwire/`` (the package tree).

Output shape::

    {
      "version": "1",
      "generated_from": "signalwire-python @ <git sha or N/A>",
      "python_version": "3.x",
      "modules": {
        "signalwire.core.agent_base": {
          "classes": {
            "AgentBase": ["__init__", "set_prompt", "serve", ...]
          },
          "functions": ["get_logger", ...]
        },
        ...
      }
    }

Usage:
    python3 scripts/enumerate_python.py                        # print JSON
    python3 scripts/enumerate_python.py --output python_surface.json
    python3 scripts/enumerate_python.py --check                # exit 1 if
                                                                 existing file
                                                                 differs
"""

from __future__ import annotations

import argparse
import ast
import json
import subprocess
import sys
from pathlib import Path


def _is_public(name: str) -> bool:
    """Public = not starting with a single underscore. Dunders are public."""
    if name.startswith("__") and name.endswith("__"):
        return True
    return not name.startswith("_")


def enumerate_module(path: Path, module_name: str) -> dict:
    """Return public classes/functions in a single .py file."""
    try:
        tree = ast.parse(path.read_text(encoding="utf-8"))
    except (SyntaxError, UnicodeDecodeError):
        return {"classes": {}, "functions": []}

    classes: dict[str, list[str]] = {}
    functions: list[str] = []

    for node in tree.body:
        if isinstance(node, ast.ClassDef):
            if not _is_public(node.name):
                continue
            methods = [
                item.name
                for item in node.body
                if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef))
                and _is_public(item.name)
            ]
            classes[node.name] = sorted(methods)
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if _is_public(node.name):
                functions.append(node.name)

    return {"classes": classes, "functions": sorted(functions)}


def module_name_from_path(package_root: Path, path: Path) -> str:
    """Convert a path to a dotted module name, e.g. signalwire.core.agent_base."""
    rel = path.relative_to(package_root.parent)
    parts = list(rel.with_suffix("").parts)
    if parts[-1] == "__init__":
        parts.pop()
    return ".".join(parts)


def enumerate_package(package_root: Path) -> dict[str, dict]:
    """Walk the package and collect inventories per module."""
    modules: dict[str, dict] = {}
    for path in sorted(package_root.rglob("*.py")):
        # Skip caches and tests inside the package (there shouldn't be any,
        # but be defensive).
        if "__pycache__" in path.parts or "/tests/" in str(path):
            continue
        mod = module_name_from_path(package_root, path)
        inv = enumerate_module(path, mod)
        if inv["classes"] or inv["functions"]:
            modules[mod] = inv
    return modules


def git_sha(repo: Path) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo), "rev-parse", "HEAD"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except Exception:
        return "N/A"


def build_snapshot(python_sdk: Path) -> dict:
    package_root = python_sdk / "signalwire" / "signalwire"
    if not package_root.is_dir():
        raise SystemExit(f"error: package not found at {package_root}")
    return {
        "version": "1",
        "generated_from": f"signalwire-python @ {git_sha(python_sdk)}",
        "python_version": f"{sys.version_info.major}.{sys.version_info.minor}",
        "modules": enumerate_package(package_root),
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--python-sdk", type=Path,
        default=Path.home() / "src" / "signalwire-python",
    )
    parser.add_argument(
        "--output", type=Path, default=None,
        help="Write JSON to this path (default: stdout)",
    )
    parser.add_argument(
        "--check", action="store_true",
        help="Compare against the file at --output; exit 1 on drift",
    )
    args = parser.parse_args(argv)

    if args.check and not args.output:
        parser.error("--check requires --output")

    snapshot = build_snapshot(args.python_sdk)
    rendered = json.dumps(snapshot, indent=2, sort_keys=True) + "\n"

    if args.check:
        if not args.output.is_file():
            print(f"error: {args.output} does not exist", file=sys.stderr)
            return 1
        existing = args.output.read_text(encoding="utf-8")
        # Normalise `generated_from` (git SHA) before comparison — we care
        # about the surface, not which commit the snapshot was taken at.
        def strip_meta(s: str) -> str:
            obj = json.loads(s)
            obj.pop("generated_from", None)
            return json.dumps(obj, indent=2, sort_keys=True) + "\n"
        if strip_meta(rendered) != strip_meta(existing):
            print(
                "DRIFT: python_surface.json is stale relative to signalwire-python.\n"
                "  Regenerate:\n"
                "    python3 scripts/enumerate_python.py --output python_surface.json",
                file=sys.stderr,
            )
            return 1
        return 0

    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
