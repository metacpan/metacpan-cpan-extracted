#!/usr/bin/env python3
"""Conservative textual Rex review; no Perl execution and no safety certification.

Input: explicit UTF-8 files (or '-' for stdin), max 2 MiB each. Full-line comments
and POD are omitted, but this is not a lexer: strings, heredocs, aliases, generated
code, inline comments, and multiline syntax can cause false positives/negatives.
No source excerpts or captured secret values are emitted. No files are changed.
"""
from __future__ import annotations
import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import re
import sys

MAX_BYTES = 2 * 1024 * 1024
SEVERITY = {'info': 1, 'warning': 2, 'error': 3}

@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    rule: str
    severity: str
    message: str

# Rules identify review points, not all exploitable conditions.
RULES = (
    ('REX001', 'error', r'disable_strict_host_key_checking|strict_hostkeycheck\s*=>\s*0\b|StrictHostKeyChecking\s*(?:=>|=)\s*[\'\"]?(?:no|off)\b',
     'Host-key verification appears disabled; require explicit exception policy, not a troubleshooting default.'),
    ('REX002', 'warning', r'\brun\s*\(?\s*[\'\"](?:/bin/)?(?:sh|bash)\b[^\n]*[\'\"]-c[\'\"]',
     'A shell program is executed; outer argument quoting does not make the script data.'),
    ('REX003', 'warning', r'\$\?\s*(?:>>|<<)(?:=)?\s*8\b',
     'Unconditional status shifting requires a pinned effective-driver contract; preserve raw status.'),
    ('REX004', 'warning', r'\bensure\s*=>\s*[\'\"]latest[\'\"]',
     'A moving latest target needs an explicit upgrade, canary, and rollback policy.'),
    ('REX005', 'error', r'\btask\s*\(?\s*[\'\"](?:run|file|service|template|pkg|sudo|group|notify|task|user)[\'\"]',
     'Task name collides with a common Rex DSL symbol; use a distinct task name.'),
    ('REX006', 'warning', r'\buse\s+Rex::Commands::\w+\s+qw\s*[(/]',
     'Ordinary Exporter selective-import syntax is not the inspected Rex::Exporter API.'),
    ('REX007', 'info', r'\bcreates\s*=>',
     'The creates guard invokes the filesystem interface; do not assume this is an exec-only path.'),
    ('REX008', 'warning', r'Rex::Interface::Fs\s*->\s*create\s*\(\s*[\'\"]LibSSH[\'\"]',
     'Forcing Fs::LibSSH bypasses normal factory resolution; inspect the required sudo semantics.'),
    ('REX009', 'error', r'\b(?:password|sudo_password)\s*(?:=>\s*|\(\s*)?[\'\"][^\'\"\n]+[\'\"]',
     'A literal credential appears in source; remove it and use the approved secret mechanism.'),
)
COMPILED = tuple((code, severity, re.compile(pattern), message)
                 for code, severity, pattern, message in RULES)

def visible_lines(text: str):
    """Remove only full-line comments/POD, retaining source line numbers."""
    in_pod = False
    for number, line in enumerate(text.splitlines(), 1):
        if re.match(r'^=(?!cut\b)\w+', line):
            in_pod = True
        if in_pod:
            if re.match(r'^=cut\b', line):
                in_pod = False
            continue
        if line.lstrip().startswith('#'):
            continue
        yield number, line

def audit_text(text: str, path: str = '<memory>') -> list[Finding]:
    found = []
    for number, line in visible_lines(text):
        for code, severity, pattern, message in COMPILED:
            if pattern.search(line):
                found.append(Finding(path, number, code, severity, message))
    return found

def read_text(name: str) -> str:
    if name == '-':
        data = sys.stdin.buffer.read(MAX_BYTES + 1)
    else:
        with Path(name).open('rb') as handle:
            data = handle.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError('input exceeds 2 MiB limit')
    return data.decode('utf-8')

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files', nargs='+', help="Explicit files, or '-' for stdin")
    parser.add_argument('--json', action='store_true', help='Machine-readable output without source excerpts')
    parser.add_argument('--fail-on', choices=['error', 'warning', 'info', 'never'], default='error')
    args = parser.parse_args(argv)
    if args.files.count('-') > 1:
        parser.error("stdin '-' may be specified only once")
    results, errors = [], []
    for name in args.files:
        try:
            results.extend(audit_text(read_text(name), name))
        except (OSError, UnicodeError, ValueError) as exc:
            errors.append({'path': name, 'error': str(exc)})
    payload = {'schema_version': 1, 'tool': 'rex-static-review',
               'limitations': 'Text patterns only; not a Perl parser or safety certificate. No Rex code executed.',
               'findings': [asdict(f) for f in results], 'input_errors': errors}
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        for f in results:
            print(f'{f.path}:{f.line}: {f.severity} {f.rule}: {f.message}')
        for e in errors:
            print(f"{e['path']}: input error: {e['error']}", file=sys.stderr)
        print(f'{len(results)} review points; absence of findings is not evidence of safety.')
    if errors:
        return 2
    threshold = SEVERITY.get(args.fail_on, 99)
    return int(any(SEVERITY[f.severity] >= threshold for f in results))

if __name__ == '__main__':
    raise SystemExit(main())
