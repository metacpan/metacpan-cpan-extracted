#!/usr/bin/env python3
"""Run / regenerate the Python adapter golden tests.

Each fixture under tests/python_adapter/fixtures/<name>.py has a matching
golden file at tests/python_adapter/golden/<name>.json that contains the
canonical signature shape the enumerator MUST produce for that fixture.

Usage:
    python3 tests/python_adapter/run_goldens.py            # verify
    python3 tests/python_adapter/run_goldens.py --update   # regenerate goldens

The runner uses griffe directly on the fixture file, then runs the
enumerator's conversion logic over the loaded module, then byte-compares
the output JSON to the committed golden.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import griffe

HERE = Path(__file__).resolve().parent
SCRIPTS = HERE.parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS))

from enumerate_python_signatures import (  # type: ignore
    collect_module, load_aliases,
)

PSDK = HERE.parent.parent
ALIASES = load_aliases(PSDK / "type_aliases.yaml")
FIXTURES = HERE / "fixtures"
GOLDEN = HERE / "golden"


def adapt_fixture(fixture: Path) -> dict:
    loader = griffe.GriffeLoader(search_paths=[str(FIXTURES)])
    mod = loader.load(fixture.stem)
    out: dict = {}
    failures: list = []
    collect_module(mod, ALIASES, out, failures)
    if failures:
        raise SystemExit(
            f"adapter failed for {fixture.name}:\n  - " +
            "\n  - ".join(failures)
        )
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--update", action="store_true",
                        help="Regenerate goldens (use after intentional adapter change).")
    args = parser.parse_args()

    GOLDEN.mkdir(exist_ok=True)
    fixtures = sorted(FIXTURES.glob("*.py"))
    if not fixtures:
        print(f"error: no fixtures found in {FIXTURES}", file=sys.stderr)
        return 2

    failures = 0
    for fix in fixtures:
        emitted = adapt_fixture(fix)
        golden = GOLDEN / f"{fix.stem}.json"
        emitted_text = json.dumps(emitted, indent=2, sort_keys=False) + "\n"
        if args.update:
            golden.write_text(emitted_text, encoding="utf-8")
            print(f"updated {golden}")
            continue
        if not golden.exists():
            print(f"FAIL [{fix.stem}]: no golden — run with --update", file=sys.stderr)
            failures += 1
            continue
        expected_text = golden.read_text(encoding="utf-8")
        if emitted_text != expected_text:
            failures += 1
            print(f"FAIL [{fix.stem}]: emitted differs from golden", file=sys.stderr)
            # Show a small diff for debugging
            import difflib
            for line in difflib.unified_diff(
                expected_text.splitlines(keepends=True),
                emitted_text.splitlines(keepends=True),
                fromfile=f"golden/{fix.stem}.json",
                tofile=f"emitted/{fix.stem}.json",
                n=3,
            ):
                sys.stderr.write(line)
            continue
        print(f"OK   [{fix.stem}]")

    if args.update:
        return 0
    if failures:
        print(f"\n{failures} golden(s) failed", file=sys.stderr)
        return 1
    print(f"\nAll {len(fixtures)} goldens OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
