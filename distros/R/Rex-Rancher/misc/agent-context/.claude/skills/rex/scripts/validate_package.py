#!/usr/bin/env python3
"""Offline Rex skill integrity, structure, and relative-link validator.

Does not execute Rexfiles, fetch URLs, or claim that Markdown examples are valid
Perl. MANIFEST.json verifies consistency, not publisher authenticity: keep the
release ZIP hash through a trusted channel if authenticity matters.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import sys
from urllib.parse import unquote, urlsplit

EXCLUDED = {'MANIFEST.json'}
REQUIRED = {'SKILL.md', 'README.md', 'SOURCE_LOCK.json', 'VALIDATION.md',
            'references/INDEX.md', 'examples/README.md', 'evals/cases.json',
            'scripts/audit_rexfile.py', 'scripts/inspect_rex.pl',
            'scripts/validate_package.py'}

def safe_relative(value: str) -> bool:
    p = PurePosixPath(value)
    return (bool(value) and not p.is_absolute() and '..' not in p.parts
            and '\\' not in value and ':' not in value and not any(ord(c) < 32 for c in value)
            and p.as_posix() == value and value != '.')

def inventory(root: Path) -> dict[str, str]:
    result = {}
    for p in sorted(root.rglob('*')):
        if p.is_symlink():
            raise ValueError(f'symlink not allowed: {p.relative_to(root)}')
        if p.is_file():
            rel = p.relative_to(root).as_posix()
            if rel in EXCLUDED:
                continue
            result[rel] = hashlib.sha256(p.read_bytes()).hexdigest()
    return result

def check_links(root: Path) -> list[str]:
    errors = []
    for p in sorted(root.rglob('*.md')):
        text = p.read_text(encoding='utf-8')
        # The archived baseline is evidence, not an active navigation document.
        if p.relative_to(root).as_posix() == 'audit/original-skill.md':
            continue
        for match in re.finditer(r'(?<!!)\[[^\]\n]+\]\(([^\s)]+)\)', text):
            value = match.group(1).strip('<>')
            parsed = urlsplit(value)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            target = (p.parent / unquote(parsed.path)).resolve()
            try:
                target.relative_to(root)
            except ValueError:
                errors.append(f'{p.relative_to(root)}: link escapes package: {value}')
                continue
            if not target.exists():
                errors.append(f'{p.relative_to(root)}: missing link target: {value}')
            # No internal fragment links are shipped. If added, review anchors
            # manually; this validator checks file targets, not renderer-specific IDs.
    return errors

def validate(root: Path, require_manifest: bool = True) -> tuple[list[str], dict]:
    root = root.resolve()
    errors = []
    if not root.is_dir():
        return ['package directory not found'], {}
    for name in sorted(REQUIRED):
        if not (root / name).is_file():
            errors.append(f'missing required file: {name}')
    try:
        actual = inventory(root)
    except (OSError, ValueError) as exc:
        return [str(exc)], {}
    for rel in actual:
        if not safe_relative(rel):
            errors.append(f'unsafe package path: {rel}')
    if (root / 'SKILL.md').exists():
        text = (root / 'SKILL.md').read_text(encoding='utf-8')
        front = re.match(r'\A---\n(.*?)\n---\n', text, re.S)
        if not front:
            errors.append('SKILL.md: missing frontmatter')
        else:
            keys = re.findall(r'^([\w-]+):', front.group(1), re.M)
            if len(keys) != len(set(keys)):
                errors.append('SKILL.md: duplicate frontmatter key')
            if not re.search(r'^name:\s*rex\s*$', front.group(1), re.M):
                errors.append('SKILL.md: expected name rex')
            if not re.search(r'^description:\s*\S', front.group(1), re.M):
                errors.append('SKILL.md: description missing')
    for p in root.rglob('*.json'):
        try:
            json.loads(p.read_text(encoding='utf-8'))
        except (OSError, UnicodeError, ValueError) as exc:
            errors.append(f'{p.relative_to(root)}: invalid JSON: {exc}')
    try:
        errors.extend(check_links(root))
    except (OSError, UnicodeError, ValueError) as exc:
        errors.append(f'link validation error: {exc}')
    manifest_path = root / 'MANIFEST.json'
    if manifest_path.exists():
        try:
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            expected = manifest['files']
            if not isinstance(expected, dict):
                raise ValueError('files must be an object')
            for rel, digest in expected.items():
                if not safe_relative(rel):
                    errors.append(f'manifest unsafe path: {rel}')
                if not isinstance(digest, str) or not re.fullmatch(r'[0-9a-f]{64}', digest):
                    errors.append(f'manifest invalid SHA256: {rel}')
            for rel in sorted(set(expected) - set(actual)):
                errors.append(f'manifest file missing: {rel}')
            for rel in sorted(set(actual) - set(expected)):
                errors.append(f'unmanifested file: {rel}')
            for rel in sorted(set(actual) & set(expected)):
                if actual[rel] != expected[rel]:
                    errors.append(f'hash mismatch: {rel}')
        except (OSError, UnicodeError, ValueError, KeyError, TypeError) as exc:
            errors.append(f'invalid manifest: {exc}')
    elif require_manifest:
        errors.append('MANIFEST.json is missing')
    stats = {'files_hashed': len(actual),
             'markdown_files': sum(p.endswith('.md') for p in actual),
             'reference_files': sum(p.startswith('references/') and p.endswith('.md') for p in actual),
             'skill_lines': len((root / 'SKILL.md').read_text().splitlines()) if (root / 'SKILL.md').exists() else 0}
    return errors, stats

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', nargs='?', default=str(Path(__file__).resolve().parents[1]))
    args = parser.parse_args(argv)
    try:
        errors, stats = validate(Path(args.root))
    except (OSError, UnicodeError, ValueError) as exc:
        errors, stats = [str(exc)], {}
    print(json.dumps({'ok': not errors, 'errors': errors, 'stats': stats}, indent=2))
    return int(bool(errors))

if __name__ == '__main__':
    raise SystemExit(main())
