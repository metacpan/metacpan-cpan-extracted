#!/usr/bin/env python3
"""
audit_stubs.py — fail CI if a port ships stub function bodies pretending to
be production code.

Why this exists
---------------
The port_surface / symbol-surface / doc-audit chain answers "do all the named
things exist?" — yes, every symbol the Python reference exposes is present.
None of those audits answers "do they actually do what their names + docs
claim?" Several ports historically shipped relay-client transports, swaig-test
CLI HTTP layers, and skill handlers that returned canned strings or feature-
gated themselves into a permanent unimplementable state — green test suites
all the way down.

This script is the gate that catches that. It greps the port's source for the
forbidden patterns listed in PORTING_GUIDE.md → "Production Code Discipline"
→ "Forbidden patterns", and fails on any hit not justified in the port's
INTENTIONAL_NON_IMPLEMENTATION.md.

Usage
-----
    python audit_stubs.py --root <port-dir>

Allow-list (INTENTIONAL_NON_IMPLEMENTATION.md, at port repo root)
-----------------------------------------------------------------
A simple Markdown file. Every entry is a list item of the form:

    - <file:line> — <one-sentence justification>

Example:

    - signalwire/__init__.py:52 — optional-extra import guard for CLI helpers
    - lib/signalwire/skills/skill_base.rb:17 — abstract method, subclass must override
    - src/livewire/index.ts:775 — LiveKit prewarm hook, SignalWire genuinely doesn't need it

Lines outside list items are ignored (so the file can have a header / context).
The script extracts `file:line` tokens from each list item; a stub whose
`file:line` matches an entry is allowed.

Exit codes
----------
    0  — clean, or every hit is allow-listed.
    1  — at least one stub hit is NOT allow-listed.
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

# Source extensions the audit looks at. The relay/CLI/skill stubs we've found
# all live in source code, not docs/tests — those are excluded by directory.
SOURCE_EXTENSIONS = {
    ".py", ".rb", ".pl", ".pm", ".php", ".ts", ".tsx", ".js",
    ".cs", ".java", ".go", ".rs", ".cpp", ".hpp", ".h", ".cc",
}

# Directories never scanned. Tests are excluded because tests asserting that
# X raises NotImplementedError on a deliberate abstract surface are fine; the
# audit's job is the production code that the test exercises.
EXCLUDED_DIRS = {
    ".git", "node_modules", "vendor", "target", "build", "dist",
    "__pycache__", ".venv", "venv", ".tox", ".pytest_cache",
    "tests", "test", "spec", "t", "Tests",
}

# The actual stub patterns. Each pattern is a regex; if it matches a non-blank
# non-test source line, it's a hit. The `name` field shows up in the report.
@dataclass(frozen=True)
class StubPattern:
    name: str
    regex: re.Pattern
    why_it_matters: str


PATTERNS: tuple[StubPattern, ...] = (
    StubPattern(
        name="canned-error-string",
        regex=re.compile(
            r"\b(transport not available|HTTP transport not available|websocket transport not available)\b",
            re.IGNORECASE,
        ),
        why_it_matters="Function returns a canned 'transport not available' string instead of doing the work.",
    ),
    StubPattern(
        name="stub-in-production-comment",
        regex=re.compile(
            r"(stub:\s*(in\s+)?production|stub for unit-testing|stub:\s*production\s+(would|writes|opens|reads)|"
            r"production\s+(implementation|writes|reads|opens|sends).{0,50}\b(would|will)\b|"
            r"\bin\s+production[,\s]\s*this\s+would\b|"
            r"\bin\s+a\s+production\s+(?:implementation|build|environment)|"
            r"\bin\s+production\s+we\s+would\b)",
            re.IGNORECASE,
        ),
        why_it_matters=(
            "A 'stub: in production this would...' or 'in production, this would...' "
            "comment confesses the body is fake (returns canned data, doesn't contact "
            "the real upstream / open the real socket / run the real workflow)."
        ),
    ),
    StubPattern(
        name="todo-fixme-implement",
        regex=re.compile(
            r"(?:^|[^A-Za-z_])(TODO|FIXME)\s*[:\s].{0,100}\b(implement|finish|port|wire|hook)\b",
            re.IGNORECASE,
        ),
        why_it_matters="An open TODO/FIXME promising future implementation is a stub on main.",
    ),
    StubPattern(
        name="rust-unimplemented-todo-macros",
        regex=re.compile(
            r"\b(unimplemented!\s*\(|todo!\s*\()",
        ),
        why_it_matters="Rust's `unimplemented!()` / `todo!()` macros are stubs by definition.",
    ),
    StubPattern(
        name="panic-not-implemented",
        regex=re.compile(
            r"""panic[!]?\s*\(\s*['"](.{0,60})\b(not implemented|unimplemented|todo)\b""",
            re.IGNORECASE,
        ),
        why_it_matters="Panicking 'not implemented' from production code is a stub.",
    ),
    StubPattern(
        name="dotnet-notimplemented",
        regex=re.compile(
            r"\bthrow\s+new\s+NotImplementedException\b",
        ),
        why_it_matters=".NET `NotImplementedException` thrown from production code is a stub.",
    ),
    StubPattern(
        name="java-unsupported-stub",
        regex=re.compile(
            r"\bthrow\s+new\s+UnsupportedOperationException\s*\(\s*['\"](.{0,80})\b(not implemented|stub|todo)\b",
            re.IGNORECASE,
        ),
        why_it_matters="Java `UnsupportedOperationException` carrying a 'not implemented' message is a stub.",
    ),
    StubPattern(
        name="python-notimplementederror-stub",
        regex=re.compile(
            r"raise\s+NotImplementedError\s*\(\s*['\"](.{0,80})\b(stub|todo|to be implemented|future|not yet)\b",
            re.IGNORECASE,
        ),
        why_it_matters="Python `NotImplementedError` carrying a 'todo/future/stub' message is a stub. (Abstract methods raising NotImplementedError WITHOUT a stub-flavored message are exempt.)",
    ),
    StubPattern(
        name="generic-throw-not-implemented",
        regex=re.compile(
            r"""throw\s+(?:new\s+)?\w*Error\s*\(\s*['"](.{0,80})\b(not implemented|stub|todo|future)\b""",
            re.IGNORECASE,
        ),
        why_it_matters="JS/TS `throw new Error('not implemented')` from production is a stub.",
    ),
    StubPattern(
        name="canned-fake-data-marker",
        regex=re.compile(
            r"#\s*(stub|fake)\s*[:-]|//\s*(stub|fake)\s*[:-]|/\*\s*(stub|fake)\s*[:-]",
            re.IGNORECASE,
        ),
        why_it_matters="A `// stub:` / `# stub:` marker on a line that's about to return data is a stub.",
    ),
)


@dataclass(frozen=True)
class Hit:
    pattern: StubPattern
    file: Path
    line_no: int
    line: str

    def location(self, root: Path) -> str:
        try:
            return f"{self.file.relative_to(root)}:{self.line_no}"
        except ValueError:
            return f"{self.file}:{self.line_no}"


def iter_source_files(root: Path) -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDED_DIRS]
        for fname in filenames:
            p = Path(dirpath) / fname
            if p.suffix.lower() in SOURCE_EXTENSIONS:
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
    # Multi-line silent-canned-data detector. See find_silent_canned_data
    # below. Reports at the function-signature line.
    hits.extend(find_silent_canned_data(path, lines))
    return hits


# ---------------------------------------------------------------------------
# Silent canned-data stub detector (the kind that has no comment marker)
# ---------------------------------------------------------------------------
#
# This is the pattern that hid the Rust SDK's handle_swaig_request stub
# until end-to-end testing surfaced it:
#
#     fn handle_swaig_request(
#         &self,
#         _request_data: &Option<Value>,
#         _headers: &HashMap<String, String>,
#     ) -> (u16, HashMap<String, String>, String) {
#         self.json_response(200, &serde_json::json!([]))
#     }
#
# All non-self/non-this/non-cls parameters are prefixed `_` (the
# Rust/Go/Python convention for "unused"), and the body is a single
# expression returning a fixed literal — `[]`, `{}`, `null`, `false`,
# 0, an empty string, or a function-call wrapping such a literal.
# Function takes inputs but ignores them and returns canned data.
#
# Detection is regex-based across language conventions. False positives
# (a legit function that genuinely takes inputs it doesn't yet need) go
# in INTENTIONAL_NON_IMPLEMENTATION.md with rationale.

# Function signature heuristic per language: matches a line that starts
# a function definition AND captures the parameter list.
_FN_SIG_PATTERNS: tuple[re.Pattern, ...] = (
    # Rust:  fn name(...) -> ... {  OR  fn name(\n
    re.compile(r"^\s*(?:pub(?:\s*\([^)]*\))?\s+)?(?:async\s+)?fn\s+(\w+)\s*\(([^)]*)\)"),
    # Go:    func (recv T) Name(...) ret {   OR   func Name(...) ret {
    re.compile(r"^\s*func(?:\s*\([^)]*\))?\s+(\w+)\s*\(([^)]*)\)"),
    # Python: def name(...):    OR    async def name(...):
    re.compile(r"^\s*(?:async\s+)?def\s+(\w+)\s*\(([^)]*)\)"),
    # TS / JS:  function name(...)   OR   name(...) {  inside a class (heuristic
    # — the class-method form is too noisy without a parser; we focus on the
    # `function` keyword form, which catches the bulk of cases).
    re.compile(r"^\s*(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)"),
    # PHP:  function name(...)    OR    public function name(...) ...
    re.compile(r"^\s*(?:public|private|protected|static|final|abstract|\s)*\s*function\s+(\w+)\s*\(([^)]*)\)"),
    # C#:  AccessModifier ReturnType Name(...)  — only catch ones with a body
    # block on the same or next line. Too noisy without a parser; skip C#
    # multi-line until we see a hit we missed.
)

# A literal we consider "fixed canned data" — empty/zero/null variants.
_LITERAL_RE = re.compile(
    r"""(?x)               # verbose mode
    (?:
        \[\s*\]             # empty array
      | \{\s*\}             # empty object/dict
      | \(\s*\)             # empty tuple
      | None | none | NULL | null | nil | undefined
      | False | false | True | true
      | 0(?:\.0)? | -1
      | ""  | ''
      | json!\(\s*(?:\[\s*\]|\{\s*\}|null)\s*\)        # Rust serde_json::json!([])
      | json:\s*\([^)]*\)                              # avoid catching real json calls; weak
    )
    """
)

# Parameter token. We strip type annotations and defaults, and look at the
# bare identifier. A parameter "_foo: &str" becomes "_foo".
_PARAM_NAME_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)")

# Names we never treat as "input that should be used":
_RECEIVER_NAMES = {"self", "this", "cls", "&self", "&mut", "mut"}


def _strip_type_annotation(token: str) -> str:
    """Best-effort strip of type-annotation / default-value noise from a
    parameter token across languages. We only need the leading identifier."""
    token = token.strip()
    # Rust/TypeScript: name: Type
    if ":" in token:
        token = token.split(":", 1)[0]
    # Go: name Type (handled by the regex below — first identifier wins)
    # Python with default: name=value
    if "=" in token:
        token = token.split("=", 1)[0]
    return token.strip()


def _split_params(param_list_text: str) -> list[str]:
    """Split a parameter list on top-level commas only, respecting nested
    `<>`, `()`, `[]`, and `{}` brackets so we don't slice generics like
    `&HashMap<String, String>` in half.
    """
    out: list[str] = []
    buf: list[str] = []
    depth_paren = 0
    depth_angle = 0
    depth_bracket = 0
    depth_brace = 0
    for ch in param_list_text:
        if ch == "(":
            depth_paren += 1
        elif ch == ")":
            depth_paren -= 1
        elif ch == "<":
            depth_angle += 1
        elif ch == ">":
            depth_angle -= 1
        elif ch == "[":
            depth_bracket += 1
        elif ch == "]":
            depth_bracket -= 1
        elif ch == "{":
            depth_brace += 1
        elif ch == "}":
            depth_brace -= 1
        if (
            ch == ","
            and depth_paren == 0
            and depth_angle == 0
            and depth_bracket == 0
            and depth_brace == 0
        ):
            out.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    if buf:
        out.append("".join(buf))
    return out


def _all_real_params_unused(param_list_text: str) -> bool:
    """True iff every non-self/non-this parameter in the list starts with `_`.

    Empty parameter list (after self/this filtered out) returns False — a
    no-arg function that returns a literal is just a constant, not a stub.
    """
    raw_params = _split_params(param_list_text)
    params: list[str] = []
    for p in raw_params:
        p = _strip_type_annotation(p)
        # Strip leading mutability / borrow markers Rust uses (`&self`, `mut x`, etc.)
        p = re.sub(r"^(?:&|mut\s+|\*\s*)+", "", p).strip()
        if not p:
            continue
        m = _PARAM_NAME_RE.match(p)
        if not m:
            continue
        name = m.group(1)
        if name in _RECEIVER_NAMES:
            continue
        params.append(name)
    if not params:
        return False
    return all(name.startswith("_") for name in params)


def _body_is_literal_only(body_lines: list[str]) -> bool:
    """True if the function body's single non-trivial line is a return of a
    literal (or a wrapper call returning a literal).

    Trivial lines (whitespace, lone `{`, lone `}`, lone `;`, comments) are
    ignored. This is a heuristic — false positives go to the allow-list.
    """
    meaningful: list[str] = []
    for ln in body_lines:
        s = ln.strip()
        if not s:
            continue
        # Skip braces / language separators on their own.
        if s in {"{", "}", ";", "(", ")", "[", "]"}:
            continue
        # Skip comments (best-effort; doesn't try to parse multi-line ones).
        if s.startswith(("//", "#", "/*", "*", "*/", "///", "--")):
            continue
        meaningful.append(s)
        if len(meaningful) > 2:
            return False  # body has real content
    if not meaningful:
        return False
    # The one (or two-with-trailing-semi) meaningful line(s) must contain a literal.
    body_text = " ".join(meaningful)
    # If there's any function call OTHER than json_response/json!/json/return-helpers,
    # we don't flag — could be doing real work.
    # We accept patterns like:
    #   self.json_response(200, &json!([]))
    #   return Ok(vec![])
    #   return None
    #   return ([], status, ...)
    # but reject patterns that obviously do work:
    #   self.handler.do_thing(args)
    #   db.query(stmt)
    # The literal regex is the discriminator: at least one of our "fixed
    # canned" forms appears AND no obvious work-doing call appears.
    if not _LITERAL_RE.search(body_text):
        return False
    # Heuristic: if the body line contains an identifier that looks like a
    # function call (`name(` where name isn't one of our wrapper helpers),
    # AND that call passes one of the unused params, it's actually using
    # input — not a stub. We don't have parameter context here, so we
    # err on the side of flagging.
    return True


# When a function signature spans multiple lines, the regex above won't
# capture all params. We do a second pass that joins continuation lines
# until we see the closing `)`.
def _gather_signature(lines: list[str], start_idx: int) -> tuple[str | None, str | None, int]:
    """Return (function_name, param_list_text, body_start_index) by joining
    multi-line signatures until the closing `)`. Returns (None, None, ...) if
    the line doesn't look like a function signature in any of our supported
    language conventions.
    """
    # Try a single-line match first.
    for pat in _FN_SIG_PATTERNS:
        m = pat.match(lines[start_idx])
        if m and ")" in lines[start_idx][m.start():]:
            # whole signature on one line
            # find the body open: same line `{` or next non-empty line `{`
            body_idx = start_idx + 1
            return m.group(1), m.group(2), body_idx

    # Multi-line signature: find a `fn name(` / `func name(` / `def name(`
    # that does NOT contain a closing `)` on the same line.
    multi_pat = re.compile(
        r"^\s*(?:pub(?:\s*\([^)]*\))?\s+)?(?:async\s+)?(?:fn|func|def|function)\s+(\w+)\s*\("
    )
    m = multi_pat.match(lines[start_idx])
    if not m:
        return None, None, start_idx
    name = m.group(1)
    # Concatenate lines until we hit the closing `)`.
    parts: list[str] = [lines[start_idx][m.end():]]
    idx = start_idx + 1
    depth = 1  # open paren count inside concatenated text
    # Compute initial depth from the same line we already consumed.
    initial = lines[start_idx][m.end():]
    depth = 1 + initial.count("(") - initial.count(")")
    while idx < len(lines) and depth > 0:
        parts.append(lines[idx])
        depth += lines[idx].count("(") - lines[idx].count(")")
        idx += 1
        if idx - start_idx > 20:  # safety cap
            return None, None, start_idx
    joined = "\n".join(parts)
    # Strip everything from the closing `)` onward.
    close = joined.find(")")
    if close < 0:
        return None, None, start_idx
    param_list = joined[:close]
    # Strip the trailing `\n` that was the original line break.
    return name, param_list, idx


def _bounded_body_lines(lines: list[str], start_idx: int) -> list[str]:
    """Collect the function body lines starting at `start_idx`, where the
    first non-empty line is expected to contain the opening `{` (or be
    on the same logical block-start). Stops at the matching `}` for
    brace languages. Returns only the lines BETWEEN the open and close
    (exclusive of both), so a one-line body returns a list of one line.

    This is brace-language only. For Python (no braces), we don't yet
    detect silent stubs — Python's `def f(self, _x, _y): return None` is
    a known surface and Python is the reference SDK; this audit is
    primarily targeting ports that copied surfaces and stubbed bodies.
    """
    # Find the opening `{` — could be on the body_start line (Rust/Go/Java
    # style: `... ) -> ... {` already consumed) OR on the next non-empty
    # line. Our caller already advanced past the signature, so we look at
    # `start_idx` and a little forward.
    open_idx = -1
    for j in range(start_idx, min(start_idx + 3, len(lines))):
        if "{" in lines[j]:
            open_idx = j
            break
    if open_idx < 0:
        return []
    # Track brace depth from the opening `{`. We start AFTER the open
    # brace, then walk lines until depth returns to zero. Strings and
    # comments are not handled — false positives end up in the allow-list
    # rather than us building a parser.
    open_line = lines[open_idx]
    after_open = open_line[open_line.index("{") + 1:]
    depth = 1 + after_open.count("{") - after_open.count("}")
    body: list[str] = []
    if after_open.strip():
        # The line containing `{` may also have content after the brace
        # (e.g., ` ... { return None }` style). Capture that as body.
        body.append(after_open)
    if depth <= 0:
        return body
    j = open_idx + 1
    while j < len(lines):
        ln = lines[j]
        delta = ln.count("{") - ln.count("}")
        next_depth = depth + delta
        if next_depth <= 0:
            # Last line — strip everything from the closing `}` onward.
            close = ln.rfind("}")
            tail = ln[:close] if close >= 0 else ln
            if tail.strip():
                body.append(tail)
            return body
        body.append(ln)
        depth = next_depth
        j += 1
    return body  # unbalanced; treat what we have as the body


def find_silent_canned_data(path: Path, lines: list[str]) -> list[Hit]:
    hits: list[Hit] = []
    pat = StubPattern(
        name="silent-canned-data",
        regex=re.compile(""),  # placeholder; we don't drive this from a single line
        why_it_matters=(
            "Function takes inputs but every non-receiver parameter is prefixed `_` "
            "(unused), and the body returns a fixed literal regardless of input. "
            "This is the silent stub pattern — no comment marker, no error string, "
            "but the function ignores its arguments and returns canned data. The "
            "Rust SDK's handle_swaig_request shipped with this exact pattern; it "
            "always returned `[]` for every POST /swaig request. If the function "
            "is genuinely a no-op (an extension hook), justify it in "
            "INTENTIONAL_NON_IMPLEMENTATION.md."
        ),
    )
    # Brace-language only for now. Python silent stubs are out of scope for
    # this pass since the Python SDK is the reference and Python files in
    # ports are rare.
    if path.suffix.lower() not in {".rs", ".go", ".java", ".cs", ".cpp", ".cc", ".hpp", ".h", ".ts", ".tsx", ".js", ".php"}:
        return hits

    i = 0
    while i < len(lines):
        name, param_text, body_start = _gather_signature(lines, i)
        if name is None or param_text is None:
            i += 1
            continue
        if not _all_real_params_unused(param_text):
            i = body_start
            continue
        body_lines = _bounded_body_lines(lines, body_start - 1 if body_start > 0 else 0)
        if not body_lines:
            i = body_start
            continue
        if _body_is_literal_only(body_lines):
            sig_line = lines[i].rstrip()
            hits.append(Hit(pat, path, i + 1, sig_line))
        i = body_start
    return hits


# Allow-list parsing -----------------------------------------------------------

ALLOW_LINE_RE = re.compile(
    r"^\s*[-*]\s+`?([^\s`:]+:\d+)`?\s+[—\-]\s*(.+)$"
)

def load_allowlist(path: Path) -> dict[str, str]:
    """Parse INTENTIONAL_NON_IMPLEMENTATION.md.

    Returns a dict of "file:line" → justification. Only Markdown list items of
    the form `- <file:line> — <justification>` are recognized; other text in
    the file is ignored, so the document can carry context.
    """
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
    parser.add_argument(
        "--root",
        required=True,
        help="Path to the port repo (the directory containing src/, examples/, etc.)",
    )
    parser.add_argument(
        "--allowlist",
        default=None,
        help="Path to INTENTIONAL_NON_IMPLEMENTATION.md (default: <root>/INTENTIONAL_NON_IMPLEMENTATION.md)",
    )
    parser.add_argument(
        "--show-pattern",
        action="store_true",
        help="Show which pattern matched each hit (useful when refining patterns).",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"audit_stubs: --root {root} is not a directory", file=sys.stderr)
        return 2

    allow_path = Path(args.allowlist) if args.allowlist else (root / "INTENTIONAL_NON_IMPLEMENTATION.md")
    allow = load_allowlist(allow_path)

    all_hits: list[Hit] = []
    for src in iter_source_files(root):
        all_hits.extend(scan_file(src))

    unjustified: list[Hit] = []
    for h in all_hits:
        if h.location(root) not in allow:
            unjustified.append(h)

    if not unjustified:
        if all_hits:
            print(f"audit_stubs: {len(all_hits)} hit(s), all justified in {allow_path.name}.")
        else:
            print("audit_stubs: clean.")
        return 0

    print(
        f"audit_stubs: {len(unjustified)} unjustified stub hit(s) "
        f"(out of {len(all_hits)} total).",
        file=sys.stderr,
    )
    print("Each must be either fixed or recorded in INTENTIONAL_NON_IMPLEMENTATION.md.\n", file=sys.stderr)
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
