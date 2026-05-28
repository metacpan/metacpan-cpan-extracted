#!/usr/bin/env python3
"""
audit_test_parity.py — fail CI if a port is missing tests that exist
in the Python reference.

Why this exists
---------------
Every port must match Python's behavior unless the deviation is recorded
in PORT_OMISSIONS.md. Tests are part of behavior — a port that ships
the production code but skips the test loses the regression coverage
Python earned. This audit walks Python's tests/ tree, extracts every
test function, and confirms the port has a test of equivalent name in
its tests directory.

The check is fuzzy by design: ports use different test-file naming
(Python `test_swml_service.py`, TypeScript `SWMLService.test.ts`, Go
`pkg/swml/service_test.go`), and per-language test naming idioms vary
(`test_x` in Python/Go/Rust, `testX` / `test_x` mix in Java, `it("does
x")` in JS). The audit normalizes test names (snake_case, lowercased,
markers stripped) and asserts every Python test has an equivalent.

LIMITATION: BDD-style `it('text description')` test names in JS/TS/RSpec
do not auto-map to Python's `test_snake_case` names — the words in the
descriptions are different. For ports using BDD style, expect the
audit to report many false-positive misses on the first run. Resolve
by either (a) renaming BDD tests to follow Python's convention where
appropriate, or (b) recording the alias in PORT_TEST_OMISSIONS.md
explicitly listing the Python test name and naming the BDD-style
equivalent in a comment.

Skip list
---------
Tests in subtrees the port doesn't have to mirror:
  - signalwire/search/  (search-related — only Python ships)
  - tests/integration/  (integration tests gated on live creds)
  - test_*_search*  (search-related)
  - test_*_pgvector* (pgvector-related)
  - test_*_sigmond*  (sigmond-related)

Plus per-port additions / omissions in PORT_TEST_OMISSIONS.md (same
format as PORT_OMISSIONS.md).

Usage
-----
    python audit_test_parity.py --root <port-dir>
    python audit_test_parity.py --root <port-dir> --python <path/to/signalwire-python>

Exit codes
----------
    0  — every Python test (minus skip list, minus
         PORT_TEST_OMISSIONS.md) has a port-equivalent test of the
         same name.
    1  — at least one Python test has no port-equivalent.
    2  — usage error / Python reference not found.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

DEFAULT_PYTHON_REPO = Path("/home/devuser/src/signalwire-python")

# Skip patterns — Python tests we never expect ports to mirror.
SKIP_TEST_PATH_RE = re.compile(
    r"(?:/|^)(?:"
    r"signalwire/search/|"
    r"tests/integration/|"
    r"test_(?:search|pgvector|sigmond|bedrock|datasphere_serverless)|"
    r"test_native_vector_search\.py$|"
    r"test_signalwire_search\.py$|"
    r"test_dokku\.py$"
    r")",
    re.IGNORECASE,
)

# Stem normalization — convert any test name across languages to a
# comparable canonical form.
def _normalize(name: str) -> str:
    s = name.lower()
    s = re.sub(r"[^a-z0-9]", "", s)
    return s


# Python test discovery (the reference).
def _walk_python_tests(python_root: Path) -> dict[str, list[str]]:
    """Walk Python's tests/ tree, return
    {normalized_test_name: [list of file paths it appears in (relative)]}.

    A test name is `def test_<X>` at module or class scope.
    """
    found: dict[str, list[str]] = {}
    tests_dir = python_root / "tests"
    if not tests_dir.is_dir():
        return found
    test_def_re = re.compile(r"^\s*def\s+(test_\w+)\s*\(")
    for dirpath, _dirnames, filenames in os.walk(tests_dir):
        for fname in filenames:
            if not fname.endswith(".py"):
                continue
            full = Path(dirpath) / fname
            rel = str(full.relative_to(python_root))
            if SKIP_TEST_PATH_RE.search("/" + rel):
                continue
            try:
                text = full.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for line in text.splitlines():
                m = test_def_re.match(line)
                if m:
                    norm = _normalize(m.group(1))
                    found.setdefault(norm, []).append(rel)
    return found


# Per-port test-name extraction. Each function returns the normalized
# set of test names defined in the port's tests directory.
def _walk_port_tests(port_root: Path, language: str) -> set[str]:
    found: set[str] = set()
    test_dirs = []
    for d in ("tests", "test", "spec", "t", "src/test"):
        p = port_root / d
        if p.is_dir():
            test_dirs.append(p)
    # Rust tests typically live inline in `mod tests {}` blocks within
    # src/**/*.rs files, in addition to (or instead of) tests/ directory.
    # If the language is Rust, also walk src/.
    if language == "rust" and (port_root / "src").is_dir():
        test_dirs.append(port_root / "src")

    if language == "python":
        return _walk_python_tests(port_root).keys() if False else (set(_walk_python_tests(port_root).keys()) if False else _scan_python_port(port_root))

    extractors = {
        "typescript": _extract_ts,
        "javascript": _extract_ts,
        "java": _extract_java,
        "csharp": _extract_csharp,
        "go": _extract_go,
        "rust": _extract_rust,
        "ruby": _extract_ruby,
        "perl": _extract_perl,
        "php": _extract_php,
        "cpp": _extract_cpp,
    }
    extractor = extractors.get(language)
    if extractor is None:
        return found

    for test_dir in test_dirs:
        for dirpath, _dirnames, filenames in os.walk(test_dir):
            for fname in filenames:
                full = Path(dirpath) / fname
                if full.suffix.lower() not in _LANG_SUFFIXES.get(language, set()):
                    continue
                try:
                    text = full.read_text(encoding="utf-8", errors="replace")
                except OSError:
                    continue
                for name in extractor(text):
                    found.add(_normalize(name))
    return found


_LANG_SUFFIXES = {
    "typescript": {".ts", ".tsx"},
    "javascript": {".js", ".jsx"},
    "java": {".java"},
    "csharp": {".cs"},
    "go": {".go"},
    "rust": {".rs"},
    "ruby": {".rb"},
    "perl": {".pl", ".pm", ".t"},
    "php": {".php"},
    "cpp": {".cpp", ".hpp", ".cc", ".h"},
}


def _scan_python_port(root: Path) -> set[str]:
    out: set[str] = set()
    test_def_re = re.compile(r"^\s*def\s+(test_\w+)\s*\(")
    for tests_dir in [root / "tests", root / "test"]:
        if not tests_dir.is_dir():
            continue
        for dirpath, _dirnames, filenames in os.walk(tests_dir):
            for fname in filenames:
                if not fname.endswith(".py"):
                    continue
                try:
                    text = (Path(dirpath) / fname).read_text(encoding="utf-8", errors="replace")
                except OSError:
                    continue
                for line in text.splitlines():
                    m = test_def_re.match(line)
                    if m:
                        out.add(_normalize(m.group(1)))
    return out


def _extract_ts(text: str) -> Iterable[str]:
    # `it('text', ...)`, `test('text', ...)`, `describe('text', ...)`
    for m in re.finditer(r"\b(?:it|test)\s*\(\s*['\"]([^'\"]+)['\"]", text):
        yield m.group(1)


def _extract_java(text: str) -> Iterable[str]:
    # JUnit test methods. Cover the four common shapes:
    #   public void testFoo()          -- explicit public modifier
    #   void testFoo()                 -- package-private (JUnit 5 idiom)
    #   public static void testFoo()   -- static (parameterized helpers)
    #   @Test\nvoid foo()              -- @Test-annotated, any name
    # The first three pattern-match the method name directly. The last is
    # tagged via @Test on the line before, so we look for the annotation.
    seen: set[str] = set()
    direct_re = re.compile(
        r"\b(?:public\s+)?(?:static\s+)?void\s+(test\w+|\w+Test)\s*\("
    )
    for m in direct_re.finditer(text):
        name = m.group(1)
        if name not in seen:
            seen.add(name)
            yield name
    # @Test-annotated methods whose name doesn't start/end with "test" --
    # JUnit 5 allows any method name; the @Test annotation is what marks it.
    annotated_re = re.compile(
        r"@Test\b[^\n]*\n\s*(?:public\s+)?(?:static\s+)?void\s+(\w+)\s*\("
    )
    for m in annotated_re.finditer(text):
        name = m.group(1)
        if name not in seen:
            seen.add(name)
            yield name
    # @ParameterizedTest is JUnit 5's parameterized variant; treat the
    # same as @Test for name extraction.
    paramized_re = re.compile(
        r"@ParameterizedTest\b[^\n]*\n\s*(?:public\s+)?(?:static\s+)?void\s+(\w+)\s*\("
    )
    for m in paramized_re.finditer(text):
        name = m.group(1)
        if name not in seen:
            seen.add(name)
            yield name
    # @DisplayName("text") -- JUnit 5 idiom for human-readable test names.
    # The audit normalizer can't compare these to Python's snake_case names
    # automatically, so callers should record DisplayName-only tests in
    # PORT_TEST_OMISSIONS.md if cross-language parity matters.


def _extract_csharp(text: str) -> Iterable[str]:
    # `public void TestFoo()` / `[Fact] public void TestFoo()`
    for m in re.finditer(r"\bpublic\s+(?:async\s+Task|void)\s+(\w+)\s*\(", text):
        name = m.group(1)
        if name.startswith("Test") or name.endswith("Test") or name.startswith("test"):
            yield name


def _extract_go(text: str) -> Iterable[str]:
    for m in re.finditer(r"^\s*func\s+(Test\w+|Benchmark\w+)\s*\(", text, flags=re.MULTILINE):
        yield m.group(1)


def _extract_rust(text: str) -> Iterable[str]:
    # Rust `#[test]\nfn name(...)`. Look at fn name; the macro line is
    # often a different line, so approximate by grabbing all fn lines
    # in test files (the file is in the tests dir or marked
    # #[cfg(test)]).
    for m in re.finditer(r"^\s*fn\s+(\w+)\s*\(", text, flags=re.MULTILINE):
        name = m.group(1)
        if name.startswith("test_") or "_test" in name:
            yield name


def _extract_ruby(text: str) -> Iterable[str]:
    for m in re.finditer(r"^\s*def\s+(test_\w+)", text, flags=re.MULTILINE):
        yield m.group(1)
    for m in re.finditer(r"\bit\s+['\"]([^'\"]+)['\"]\s+do", text):
        yield m.group(1)


def _extract_perl(text: str) -> Iterable[str]:
    for m in re.finditer(r"^\s*sub\s+(test_\w+)", text, flags=re.MULTILINE):
        yield m.group(1)
    for m in re.finditer(r"\bsubtest\s+['\"]([^'\"]+)['\"]", text):
        yield m.group(1)


def _extract_php(text: str) -> Iterable[str]:
    for m in re.finditer(r"\bpublic\s+function\s+(test\w+)\s*\(", text):
        yield m.group(1)


def _extract_cpp(text: str) -> Iterable[str]:
    for m in re.finditer(r"\bTEST(?:_F|_P)?\s*\(\s*\w+\s*,\s*(\w+)\s*\)", text):
        yield m.group(1)


# Language detection.
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
    if any((root / x).exists() for x in ["CMakeLists.txt", "Makefile"]) and (root / "include" / "signalwire").is_dir():
        return "cpp"
    if (root / "SignalWire.sln").exists() or any(p.suffix == ".csproj" for p in (root / "src").rglob("*.csproj") if (root / "src").is_dir()):
        return "csharp"
    return None


def _load_omissions(path: Path) -> set[str]:
    """Read PORT_TEST_OMISSIONS.md if present. Each list item is a
    Python test name (e.g. 'test_swml_service_invalid_route'); we
    normalize and collect."""
    if not path.exists():
        return set()
    out: set[str] = set()
    item_re = re.compile(r"^\s*[-*]\s+`?(test_\w+)`?\b")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = item_re.match(line)
        if m:
            out.add(_normalize(m.group(1)))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--root", required=True, help="Path to the port repo.")
    parser.add_argument(
        "--python",
        default=str(DEFAULT_PYTHON_REPO),
        help=f"Path to the Python reference (default: {DEFAULT_PYTHON_REPO})",
    )
    parser.add_argument("--show-found", action="store_true", help="Print every match (debug).")
    parser.add_argument("--limit", type=int, default=50, help="Cap missing-test report at this many lines.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    python_root = Path(args.python).resolve()
    if not root.is_dir():
        print(f"audit_test_parity: --root {root} is not a directory", file=sys.stderr)
        return 2
    if not python_root.is_dir():
        print(f"audit_test_parity: --python {python_root} not found", file=sys.stderr)
        return 2

    language = _detect_language(root)
    if language is None:
        print(f"audit_test_parity: could not detect language for {root}", file=sys.stderr)
        return 2

    py_tests = _walk_python_tests(python_root)
    port_tests = _walk_port_tests(root, language)

    omissions = _load_omissions(root / "PORT_TEST_OMISSIONS.md")

    missing: list[tuple[str, list[str]]] = []
    for norm, py_paths in sorted(py_tests.items()):
        if norm in port_tests:
            continue
        if norm in omissions:
            continue
        missing.append((norm, py_paths))

    if not missing:
        print(f"audit_test_parity: clean. {language}: {len(port_tests)} test(s) cover all {len(py_tests)} Python tests (modulo {len(omissions)} omissions).")
        return 0

    print(
        f"audit_test_parity: {language} is missing {len(missing)} test(s) that exist in Python.",
        file=sys.stderr,
    )
    print(
        "Each must be either ported (add an equivalent test in the port's tests dir) "
        "or recorded in PORT_TEST_OMISSIONS.md with rationale.\n",
        file=sys.stderr,
    )
    for norm, py_paths in missing[:args.limit]:
        print(f"  {norm} (defined in {py_paths[0]})", file=sys.stderr)
    if len(missing) > args.limit:
        print(f"  ... ({len(missing) - args.limit} more, raise --limit to show)", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
