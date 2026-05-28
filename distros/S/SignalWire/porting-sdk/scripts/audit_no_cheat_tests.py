#!/usr/bin/env python3
"""
audit_no_cheat_tests.py — fail CI if a port has tests that pass without
actually doing work.

Why this exists
---------------
The Rust SDK shipped a stub `handle_swaig_request` that returned `[]`
regardless of input. The unit test for it asserted
`parsed.is_array()` — i.e. the test asserted the stub's empty array
IS an array. Test passed; production was broken. The test ratified
the stub.

This audit catches the family of tests that pass without proving
anything:

  - `assert True` / `assert(true)` / `expect(true).toBe(true)` /
    `assertEquals(1, 1)` — assertions whose result is independent of
    the code under test.
  - Empty / `pass`-bodied test functions — the test exists in name
    only.
  - Tests with NO assertion of any kind — setup-only fixtures
    masquerading as tests.
  - Tests that wrap a function and assert only that the result is
    non-null (`assertNotNull(result)`, `assert result is not None`,
    `expect(result).toBeDefined()`) — these pass against a stub that
    returns any value at all.

A test that mocks the very transport it exists to verify is also a
cheat — but that one needs cross-line awareness and I/O knowledge,
so this audit doesn't catch it. (`audit_relay_handshake.py` /
`audit_http_swml.py` / `audit_skills_dispatch.py` catch the
mocked-transport family at runtime by exercising the real path.)

Usage
-----
    python audit_no_cheat_tests.py --root <port-dir>

Allow-list (INTENTIONAL_THIN_TESTS.md, at port repo root)
---------------------------------------------------------
For legitimate thin tests (a sanity-check that a constant exports with
the right name; a smoke test that verifies a function is importable
without raising). Format mirrors INTENTIONAL_NON_IMPLEMENTATION.md:

    - <file:line> — <one-sentence justification>

Anything that's actually testing behavior should not be in here.

Exit codes
----------
    0  — clean, or every hit allow-listed.
    1  — at least one cheat-test hit is NOT allow-listed.
    2  — usage error or the port directory doesn't exist.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

# We DO scan test directories for this audit (unlike audit_stubs.py).
SOURCE_EXTENSIONS = {
    ".py", ".rb", ".pl", ".pm", ".php", ".ts", ".tsx", ".js",
    ".cs", ".java", ".go", ".rs", ".cpp", ".hpp", ".h", ".cc",
}

# Directories never scanned. We don't exclude tests/test/spec/t — they're
# the target. We exclude only build artifacts and dependency vendor dirs.
EXCLUDED_DIRS = {
    ".git", "node_modules", "vendor", "target", "build", "dist",
    "__pycache__", ".venv", "venv", ".tox", ".pytest_cache",
}

# Test-file heuristic: a file is a test file iff its path contains one
# of these directory components OR its basename starts/ends with a
# language-conventional test marker.
def looks_like_test_file(path: Path) -> bool:
    # Pytest fixture file — not a test file.
    if path.name == "conftest.py":
        return False
    parts = {p.lower() for p in path.parts}
    if any(d in parts for d in {"tests", "test", "spec", "t", "__tests__", "specs"}):
        return True
    name = path.stem.lower()
    if name.startswith("test_") or name.endswith("_test") or name.endswith(".test") or name.endswith(".spec"):
        return True
    if path.suffix.lower() in {".rs"} and name.endswith("_test"):
        return True
    return False


@dataclass(frozen=True)
class CheatPattern:
    name: str
    regex: re.Pattern
    why_it_matters: str


# Regexes are conservative — false positives go to the allow-list.
PATTERNS: tuple[CheatPattern, ...] = (
    CheatPattern(
        name="assert-tautology",
        regex=re.compile(
            # Only flag when the assertion's content is a tautology (both
            # sides literal/equal). Bare `assert(true)`, `assert!(true)`,
            # `expect(true).toBe(true)`, `assertEquals(1, 1)`. NOT
            # `assertEquals(true, someVar)` — that's a normal assertion.
            r"""
            \b(?:
                assert | assert!\s* | assertTrue | ASSERT_TRUE
            )\s*\(\s*
            (?: true | True | 1 )
            \s*\)
            |
            \bassert(?:Equals?|_eq!?)\s*\(\s*
            (?: true | True | 1 | "" | '' )
            \s*,\s*
            (?: true | True | 1 | "" | '' )
            \s*\)
            |
            \bassert\s*\(\s*
            (?: true\s*==\s*true | 1\s*==\s*1 | True\s+is\s+True )
            \s*\)
            """,
            re.VERBOSE,
        ),
        why_it_matters=(
            "Assertion always passes regardless of code under test. "
            "Replace with a content-shaped assertion that would fail if "
            "the code were broken."
        ),
    ),
    CheatPattern(
        name="expect-toBe-true",
        regex=re.compile(
            r"""\bexpect\s*\(\s*true\s*\)\s*\.\s*toBe(?:Truthy)?\s*\(\s*(?:true)?\s*\)""",
            re.IGNORECASE,
        ),
        why_it_matters="`expect(true).toBe(true)` is always green; it tests nothing.",
    ),
    CheatPattern(
        name="empty-test-body",
        regex=re.compile(
            # Test function with `pass` as the only body, or empty `{}`.
            r"""
            (?:
                def\s+test_\w+\s*\([^)]*\)\s*:\s*(?:\n\s*)+pass\s*(?:\n|$) |
                fn\s+(?:test_)?\w+\s*\([^)]*\)\s*\{\s*\} |
                (?:it|test)\s*\([^)]*\)\s*=>\s*\{\s*\} |
                public\s+void\s+test\w+\s*\(\s*\)\s*\{\s*\} |
                public\s+function\s+test\w+\s*\(\s*\)\s*:\s*void\s*\{\s*\}
            )
            """,
            re.VERBOSE,
        ),
        why_it_matters="Test body is empty / `pass` — the test exists in name only.",
    ),
)


@dataclass(frozen=True)
class Hit:
    pattern: CheatPattern
    file: Path
    line_no: int
    line: str

    def location(self, root: Path) -> str:
        try:
            return f"{self.file.relative_to(root)}:{self.line_no}"
        except ValueError:
            return f"{self.file}:{self.line_no}"


# Multi-line analyses (test-with-no-assertion, nullness-only) need to walk
# whole functions. Handled below.

_TEST_FN_PATTERNS = (
    # Python:  def test_foo(...) :   OR   async def test_foo(...) :
    re.compile(r"^\s*(?:async\s+)?def\s+(test_\w+)\s*\([^)]*\)\s*(?:->\s*[^:]+)?\s*:"),
    # Rust:    fn name(...) ... { (preceded by #[test] or #[tokio::test])
    re.compile(r"^\s*(?:pub(?:\s*\([^)]*\))?\s+)?(?:async\s+)?fn\s+(\w+)\s*\([^)]*\)"),
    # Go:      func TestFoo(t *testing.T) {
    re.compile(r"^\s*func\s+(Test\w+|Benchmark\w+)\s*\([^)]*\)\s*\{"),
    # Java:    @Test public void testFoo() { ...
    re.compile(r"^\s*public\s+void\s+(test\w+)\s*\([^)]*\)\s*(?:throws[^{]+)?\{"),
    # C# / .NET:  [Fact] public void TestFoo() { ...    OR    [TestMethod]
    re.compile(r"^\s*public\s+(?:async\s+Task|void)\s+(\w+)\s*\([^)]*\)\s*\{"),
    # JS / TS:  test('name', () => { ...  OR  it('name', () => { ...
    re.compile(r"^\s*(?:test|it)\s*\(\s*['\"]([^'\"]+)['\"]"),
    # PHP:     public function testFoo() { ...
    re.compile(r"^\s*public\s+function\s+(test\w+)\s*\([^)]*\)\s*(?::\s*\w+)?\s*\{"),
    # Ruby:    def test_foo  OR  it 'name' do
    re.compile(r"^\s*def\s+(test_\w+)\s*(?:\([^)]*\))?\s*$"),
    # Perl:    sub test_foo { ... }   OR   subtest 'name' => sub { ... }
    re.compile(r"^\s*(?:sub\s+(test_\w+)|subtest\s+['\"]([^'\"]+)['\"])"),
    # C++:     TEST(suite, name)  OR  TEST_F(...)
    re.compile(r"^\s*TEST(?:_F|_P)?\s*\(\s*\w+\s*,\s*(\w+)\s*\)\s*\{"),
)

# Recognized assertion call signatures across languages. Used to detect
# tests that contain NO assertion at all.
_ASSERT_CALL_RE = re.compile(
    r"""\b(
        assert(?:_\w+)? |          # Python / Rust / pytest assert*
        assert! |                   # Rust assert!() / assert_eq!() etc.
        debug_assert(?:_\w+)? |     # Rust debug variants
        expect |                    # JS/TS/Jest, RSpec
        ASSERT_\w+ |                # gtest / older C
        EXPECT_\w+ |                # gtest
        Assert\.\w+ |               # .NET xUnit / NUnit
        (?:assert|fail)\w* |        # JUnit / TestNG
        pytest\.raises |            # pytest exception assertion
        pytest\.warns |             # pytest warning assertion
        assertRaises\w* |           # unittest exception assertion
        assert_raises\w* |          # alternative spelling
        toThrow | toThrowError |    # JS/TS exception assertion
        \.to_raise |                # RSpec exception assertion
        \.raise_error |             # RSpec
        is\s*\( | isnt\s*\( |       # Perl Test::More
        ok\s*\( | dies_ok | lives_ok |
        is_deeply | cmp_ok |
        like\s*\( | unlike\s*\( |   # Perl Test::More like/unlike
        should\s+\w+ |              # RSpec / Chai BDD
        must_\w+ | wont_\w+ |       # Minitest must_/wont_
        refute(?:_\w+)? |           # Minitest refute/refute_equal/refute_nil
        check\s*\( | verify\s*\( |  # generic
        t\.Fatal\w* | t\.Error\w* | # Go testing.T failure calls
        t\.FailNow | t\.Fail\b      # Go testing.T fail
    )""",
    re.VERBOSE,
)

# Tests that check ONLY for nullness/existence pass against any stub.
_NULLNESS_ONLY_RE = re.compile(
    r"""\b(
        assertNotNull |
        assertNotEqual\s*\(\s*[Nn]one |
        assert\s+\w+\s+is\s+not\s+None\s*$ |
        expect\s*\([^)]+\)\s*\.\s*toBeDefined |
        expect\s*\([^)]+\)\s*\.\s*toBeTruthy |
        Assert\.NotNull
    )""",
    re.VERBOSE,
)


def _function_body_lines(lines: list[str], header_idx: int) -> list[str]:
    """Best-effort extract of a test function's body lines.

    For Python: collect lines indented deeper than the def line until a
    line at the same indent or less.
    For brace languages: walk braces from the first `{` after the
    header.
    """
    header = lines[header_idx]
    # Python case
    if re.match(r"^\s*(?:async\s+)?def\s+test_", header):
        header_indent = len(header) - len(header.lstrip())
        body: list[str] = []
        for j in range(header_idx + 1, len(lines)):
            ln = lines[j]
            if not ln.strip():
                body.append(ln)
                continue
            indent = len(ln) - len(ln.lstrip())
            if indent <= header_indent:
                break
            body.append(ln)
        return body
    # Brace case: find first `{`, walk until matching `}`.
    open_idx = -1
    for j in range(header_idx, min(header_idx + 4, len(lines))):
        if "{" in lines[j]:
            open_idx = j
            break
    if open_idx < 0:
        return []
    after = lines[open_idx][lines[open_idx].index("{") + 1:]
    depth = 1 + after.count("{") - after.count("}")
    body: list[str] = []
    if after.strip():
        body.append(after)
    if depth <= 0:
        return body
    for j in range(open_idx + 1, len(lines)):
        ln = lines[j]
        delta = ln.count("{") - ln.count("}")
        next_depth = depth + delta
        if next_depth <= 0:
            close = ln.rfind("}")
            tail = ln[:close] if close >= 0 else ln
            if tail.strip():
                body.append(tail)
            return body
        body.append(ln)
        depth = next_depth
    return body


def _body_has_real_assertion(body_lines: list[str]) -> bool:
    """True iff at least one line in body has an assertion call AND that
    assertion is not nullness-only."""
    has_any = False
    for ln in body_lines:
        if not ln.strip():
            continue
        if _ASSERT_CALL_RE.search(ln):
            has_any = True
            # Reject nullness-only bodies: if EVERY assertion line is
            # nullness-only, the body fails. We collect all and check below.
    if not has_any:
        return False
    # Check if every assertion line is a nullness-only check.
    assertion_lines = [
        ln.strip() for ln in body_lines
        if ln.strip() and _ASSERT_CALL_RE.search(ln)
    ]
    if not assertion_lines:
        return False
    if all(_NULLNESS_ONLY_RE.search(ln) for ln in assertion_lines):
        return False
    return True


def find_no_assertion_tests(path: Path, lines: list[str]) -> list[Hit]:
    """Detect test functions whose body contains no real assertion."""
    hits: list[Hit] = []
    pat = CheatPattern(
        name="test-with-no-real-assertion",
        regex=re.compile(""),  # marker
        why_it_matters=(
            "Test function body has no assertion call (or only nullness "
            "/ truthy checks). The test passes regardless of whether the "
            "code under test is correct. Add a content-shaped assertion "
            "that would fail if the code were broken."
        ),
    )
    i = 0
    while i < len(lines):
        line = lines[i]
        matched = False
        for pat_re in _TEST_FN_PATTERNS:
            m = pat_re.match(line)
            if m:
                matched = True
                body = _function_body_lines(lines, i)
                if body and not _body_has_real_assertion(body):
                    sig = line.rstrip()
                    hits.append(Hit(pat, path, i + 1, sig))
                # Skip past body to avoid re-scanning
                i += max(1, len(body))
                break
        if not matched:
            i += 1
    return hits


def iter_source_files(root: Path) -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDED_DIRS]
        for fname in filenames:
            p = Path(dirpath) / fname
            if p.suffix.lower() in SOURCE_EXTENSIONS and looks_like_test_file(p):
                yield p


def scan_file(path: Path) -> list[Hit]:
    hits: list[Hit] = []
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except (OSError, UnicodeDecodeError):
        return hits
    lines = text.splitlines()
    for line_no, line in enumerate(lines, start=1):
        stripped = line.strip()
        if not stripped:
            continue
        for pattern in PATTERNS:
            if pattern.regex.search(line):
                hits.append(Hit(pattern, path, line_no, stripped))
    hits.extend(find_no_assertion_tests(path, lines))
    return hits


# Allow-list parsing -----------------------------------------------------------

ALLOW_LINE_RE = re.compile(
    r"^\s*[-*]\s+`?([^\s`:]+:\d+)`?\s+[—\-]\s*(.+)$"
)


def load_allowlist(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = ALLOW_LINE_RE.match(line)
        if m:
            out[m.group(1)] = m.group(2).strip()
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--root", required=True, help="Path to the port repo.")
    parser.add_argument(
        "--allowlist",
        default=None,
        help="Path to INTENTIONAL_THIN_TESTS.md (default: <root>/INTENTIONAL_THIN_TESTS.md)",
    )
    parser.add_argument("--show-pattern", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"audit_no_cheat_tests: --root {root} is not a directory", file=sys.stderr)
        return 2

    allow_path = Path(args.allowlist) if args.allowlist else (root / "INTENTIONAL_THIN_TESTS.md")
    allow = load_allowlist(allow_path)

    all_hits: list[Hit] = []
    for src in iter_source_files(root):
        all_hits.extend(scan_file(src))

    unjustified = [h for h in all_hits if h.location(root) not in allow]

    if not unjustified:
        if all_hits:
            print(f"audit_no_cheat_tests: {len(all_hits)} hit(s), all justified in {allow_path.name}.")
        else:
            print("audit_no_cheat_tests: clean.")
        return 0

    print(
        f"audit_no_cheat_tests: {len(unjustified)} unjustified cheat-test hit(s) "
        f"(out of {len(all_hits)} total).",
        file=sys.stderr,
    )
    print("Each must be either fixed (replace with a content-shaped assertion) or recorded in INTENTIONAL_THIN_TESTS.md.\n", file=sys.stderr)
    for h in unjustified:
        loc = h.location(root)
        if args.show_pattern:
            print(f"  {loc}  [{h.pattern.name}]", file=sys.stderr)
        else:
            print(f"  {loc}", file=sys.stderr)
        print(f"      {h.line[:160]}", file=sys.stderr)
        print(f"      why: {h.pattern.why_it_matters}", file=sys.stderr)
        print(file=sys.stderr)

    return 1


if __name__ == "__main__":
    sys.exit(main())
