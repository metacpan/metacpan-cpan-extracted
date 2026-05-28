#!/usr/bin/env python3
"""Schema smoke test for surface_schema_v2.json.

Validates a hand-written canonical signature sample against the schema.
This is the Phase 0 done-criterion from SIGNATURE_AUDIT_PLAN.md: catch
schema bugs at design time, before any adapter is built.

Also exercises rejection cases — a sample with a missing required
property, a sample with an out-of-vocabulary type, a sample with a
malformed parameter name — to confirm the schema actually rejects them.

Usage:
    python3 tests/schema_smoke/validate.py
    # exits 0 on success, non-zero with detail on failure
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
    from jsonschema.exceptions import ValidationError
except ImportError:
    print("error: jsonschema not installed. pip install jsonschema", file=sys.stderr)
    sys.exit(2)


HERE = Path(__file__).parent
ROOT = HERE.parent.parent
SCHEMA = json.loads((ROOT / "surface_schema_v2.json").read_text())
SAMPLE = json.loads((HERE / "sample_signatures.json").read_text())


def validate_or_die(doc: dict, label: str) -> None:
    validator = Draft202012Validator(SCHEMA)
    errors = list(validator.iter_errors(doc))
    if errors:
        print(f"FAIL [{label}]: schema validation failed", file=sys.stderr)
        for err in errors[:5]:
            path = ".".join(str(p) for p in err.absolute_path) or "<root>"
            print(f"  - at {path}: {err.message}", file=sys.stderr)
        sys.exit(1)
    print(f"OK   [{label}]: schema-valid")


def expect_invalid(doc: dict, label: str, must_fail_path: str | None = None) -> None:
    validator = Draft202012Validator(SCHEMA)
    errors = list(validator.iter_errors(doc))
    if not errors:
        print(f"FAIL [{label}]: expected schema rejection, but document validated", file=sys.stderr)
        sys.exit(1)
    if must_fail_path:
        matched = any(must_fail_path in (".".join(str(p) for p in e.absolute_path)) for e in errors)
        if not matched:
            print(f"FAIL [{label}]: rejected, but no error at expected path '{must_fail_path}'", file=sys.stderr)
            for err in errors[:5]:
                print(f"  - {'.'.join(str(p) for p in err.absolute_path)}: {err.message}", file=sys.stderr)
            sys.exit(1)
    print(f"OK   [{label}]: correctly rejected ({len(errors)} error(s))")


def main() -> int:
    # 1. The hand-written happy-path sample MUST validate.
    validate_or_die(SAMPLE, "happy path sample")

    # 2. A document missing the 'version' property MUST be rejected.
    no_version = {k: v for k, v in SAMPLE.items() if k != "version"}
    expect_invalid(no_version, "missing version", must_fail_path="")

    # 3. A document with the wrong version constant MUST be rejected.
    wrong_version = {**SAMPLE, "version": "1"}
    expect_invalid(wrong_version, "wrong version constant", must_fail_path="version")

    # 4. A param with a type outside the canonical vocabulary MUST be rejected.
    bad_type = json.loads(json.dumps(SAMPLE))
    bad_type["modules"]["signalwire.core.agent_base"]["classes"]["AgentBase"]["methods"]["set_prompt"]["params"][1]["type"] = "String"  # PascalCase, not canonical
    expect_invalid(bad_type, "non-canonical type", must_fail_path="type")

    # 5. A param with a malformed name MUST be rejected.
    bad_name = json.loads(json.dumps(SAMPLE))
    bad_name["modules"]["signalwire.core.agent_base"]["classes"]["AgentBase"]["methods"]["set_prompt"]["params"][1]["name"] = "1text"  # leading digit
    expect_invalid(bad_name, "malformed param name", must_fail_path="name")

    # 6. A param with kind=positional but no type MUST be rejected.
    no_type = json.loads(json.dumps(SAMPLE))
    p = no_type["modules"]["signalwire.core.agent_base"]["classes"]["AgentBase"]["methods"]["set_prompt"]["params"][1]
    del p["type"]
    expect_invalid(no_type, "positional param without type")

    # 7. A signature missing the returns property MUST be rejected.
    no_returns = json.loads(json.dumps(SAMPLE))
    del no_returns["modules"]["signalwire.core.agent_base"]["classes"]["AgentBase"]["methods"]["set_prompt"]["returns"]
    expect_invalid(no_returns, "signature without returns")

    # 8. additionalProperties at the module-class-method level MUST be rejected.
    extra = json.loads(json.dumps(SAMPLE))
    extra["unexpected_top_level"] = 42
    expect_invalid(extra, "extra top-level property", must_fail_path="")

    print()
    print("All schema smoke tests passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
