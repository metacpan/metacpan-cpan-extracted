#!/usr/bin/env python3
"""audit_checklist.py — verify CHECKLIST_TEMPLATE.md matches the Python SDK.

Every port implements the Python SDK's public surface. The checklist enumerates
what each port must ship. If the Python SDK adds a skill, prefab, REST
namespace, doc, or example, the checklist must require it — otherwise ports
pass validation while being silently incomplete.

This script scans the Python SDK for concrete inventory (file lists, module
directories) and cross-references against CHECKLIST_TEMPLATE.md. Anything in
the Python SDK but not in the checklist is a drift (checklist too lax).
Anything in the checklist but not in the Python SDK is stale (renamed or
removed upstream).

Exit non-zero on any drift. Intended to run in CI on every porting-sdk PR and
nightly against the Python reference.

Usage:
    python3 scripts/audit_checklist.py
    python3 scripts/audit_checklist.py --python-sdk /path/to/signalwire-python
    python3 scripts/audit_checklist.py --json   # machine-readable
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Skip patterns. These are Python-only features that ports deliberately omit:
# search subsystem (vector models), bedrock (AWS niche), platform comparisons,
# version migration notes, pgvector/sigmond (search deps).
# Every skip here is justified by a porting-sdk decision. If a new "skip"
# category emerges, add it here AND document the decision in PORTING_GUIDE.md.
# ---------------------------------------------------------------------------
SKIP_DOC_STEMS = {
    "search_overview", "search_integration", "search_deployment",
    "search_indexing", "search_troubleshooting",
    "bedrock_agent",
    "livekit_comparison", "pipecat_comparison",
    "MIGRATION-2.0",
}
SKIP_EXAMPLE_STEMS_PREFIX = (
    "bedrock_", "search_", "pgvector_", "sigmond_", "local_search_",
)
SKIP_SKILL_NAMES = set()  # All 18+ skills are required.
SKIP_NAMESPACE_NAMES = set()
SKIP_PREFAB_NAMES = set()


@dataclass
class InventoryDrift:
    category: str
    in_python_not_in_checklist: list[str] = field(default_factory=list)
    in_checklist_not_in_python: list[str] = field(default_factory=list)

    @property
    def has_drift(self) -> bool:
        return bool(self.in_python_not_in_checklist or self.in_checklist_not_in_python)


def read_checklist(checklist_path: Path) -> str:
    return checklist_path.read_text(encoding="utf-8")


def scan_skills(python_sdk: Path) -> set[str]:
    """Skills are subdirectories of signalwire/skills/ with an __init__.py."""
    skills_dir = python_sdk / "signalwire" / "signalwire" / "skills"
    if not skills_dir.is_dir():
        return set()
    skills = set()
    for entry in skills_dir.iterdir():
        if not entry.is_dir() or entry.name.startswith("_"):
            continue
        if (entry / "__init__.py").is_file():
            skills.add(entry.name)
    return skills - SKIP_SKILL_NAMES


def scan_prefabs(python_sdk: Path) -> set[str]:
    """Prefabs are .py files in signalwire/prefabs/ except __init__.py."""
    prefabs_dir = python_sdk / "signalwire" / "signalwire" / "prefabs"
    if not prefabs_dir.is_dir():
        return set()
    return {
        p.stem for p in prefabs_dir.glob("*.py")
        if p.stem not in ("__init__",) and p.stem not in SKIP_PREFAB_NAMES
    }


def scan_rest_namespaces(python_sdk: Path) -> set[str]:
    """REST namespaces are .py files in rest/namespaces/ except __init__.py."""
    ns_dir = python_sdk / "signalwire" / "signalwire" / "rest" / "namespaces"
    if not ns_dir.is_dir():
        return set()
    return {
        p.stem for p in ns_dir.glob("*.py")
        if p.stem not in ("__init__",) and p.stem not in SKIP_NAMESPACE_NAMES
    }


def scan_docs(python_sdk: Path, subdir: str) -> set[str]:
    docs_dir = python_sdk / subdir
    if not docs_dir.is_dir():
        return set()
    return {p.stem for p in docs_dir.glob("*.md") if p.stem not in SKIP_DOC_STEMS}


def scan_examples(python_sdk: Path, subdir: str) -> set[str]:
    examples_dir = python_sdk / subdir
    if not examples_dir.is_dir():
        return set()
    return {
        p.stem for p in examples_dir.glob("*.py")
        if not p.stem.startswith(SKIP_EXAMPLE_STEMS_PREFIX)
    }


# ---------------------------------------------------------------------------
# Checklist parsers. Each scans CHECKLIST_TEMPLATE.md for the relevant
# patterns. These are heuristic (it's markdown), but they're specific enough
# that false positives and false negatives both require deliberate human
# action to suppress — they don't happen silently.
# ---------------------------------------------------------------------------

def parse_checklist_skills(checklist: str) -> set[str]:
    """Items like '  - [ ] datetime (get_current_time, get_current_date)'."""
    skills = set()
    # Find the skills block.
    m = re.search(
        r"## Phase 4: Skills System.*?## Phase 5:",
        checklist,
        re.DOTALL,
    )
    if not m:
        return skills
    block = m.group(0)
    for line in block.splitlines():
        mm = re.match(r"\s*-\s*\[\s*\]\s*([a-z_][a-z0-9_]*)\s*\(", line)
        if mm:
            skills.add(mm.group(1))
    return skills


def parse_checklist_prefabs(checklist: str) -> set[str]:
    """Prefabs are mentioned in Phase 5 by CamelCase class name."""
    m = re.search(
        r"## Phase 5: Prefab Agents.*?## Phase 6:",
        checklist,
        re.DOTALL,
    )
    if not m:
        return set()
    block = m.group(0)
    # Prefab lines look like: '- [ ] InfoGathererAgent (...)'
    # We map CamelCase class names to lowercase file stems.
    prefabs = set()
    mapping = {
        "InfoGathererAgent": "info_gatherer",
        "SurveyAgent": "survey",
        "ReceptionistAgent": "receptionist",
        "FAQBotAgent": "faq_bot",
        "ConciergeAgent": "concierge",
    }
    for line in block.splitlines():
        for class_name, file_stem in mapping.items():
            if re.search(rf"\[\s*\]\s*{re.escape(class_name)}\b", line):
                prefabs.add(file_stem)
    return prefabs


def parse_checklist_rest_namespaces(checklist: str) -> set[str]:
    """Namespaces are listed in Phase 8 by display name; map to file stems."""
    m = re.search(
        r"## Phase 8: REST Client.*?## Phase 9:",
        checklist,
        re.DOTALL,
    )
    if not m:
        return set()
    block = m.group(0)
    # Known display-name -> file-stem mapping. If the display name changes,
    # update this table — don't rely on a fuzzy match.
    mapping = {
        "Fabric": "fabric",
        "Calling": "calling",
        "PhoneNumbers": "phone_numbers",
        "Datasphere": "datasphere",
        "Video": "video",
        "Compat": "compat",
        "Compatibility": "compat",
        "Addresses": "addresses",
        "Queues": "queues",
        "Recordings": "recordings",
        "NumberGroups": "number_groups",
        "VerifiedCallers": "verified_callers",
        "SipProfile": "sip_profile",
        "Lookup": "lookup",
        "ShortCodes": "short_codes",
        "ImportedNumbers": "imported_numbers",
        "MFA": "mfa",
        "Registry": "registry",
        "Logs": "logs",
        "Project": "project",
        "PubSub": "pubsub",
        "Chat": "chat",
    }
    found = set()
    for name, stem in mapping.items():
        if re.search(rf"\b{re.escape(name)}\b", block):
            found.add(stem)
    return found


def parse_checklist_file_stems(checklist: str, pattern: str) -> set[str]:
    """Generic: pull out stems matching '- [ ] <stem>.<ext>' or '- [ ] <stem>.*'.

    ``pattern`` is a regex that matches the line content after the checkbox,
    capturing the stem as group 1.
    """
    stems = set()
    for line in checklist.splitlines():
        m = re.match(rf"\s*-\s*\[\s*\]\s*{pattern}", line)
        if m:
            stems.add(m.group(1))
    return stems


def parse_checklist_docs(checklist: str) -> set[str]:
    """Top-level docs/ — lines like '- [ ] architecture.md'."""
    return parse_checklist_file_stems(checklist, r"([a-z_][a-z0-9_-]*)\.md")


def parse_checklist_agent_examples(checklist: str) -> set[str]:
    """Agent examples — lines like '- [ ] simple_agent.*'."""
    stems = set()
    # Restrict to the Phase 11 § Agent examples/ section.
    m = re.search(
        r"### Agent examples/.*?(## Phase 12|### Commit to git)",
        checklist,
        re.DOTALL,
    )
    block = m.group(0) if m else checklist
    for line in block.splitlines():
        mm = re.match(
            r"\s*-\s*\[\s*\]\s*([a-z_][a-z0-9_]*)\.\*", line,
        )
        if mm:
            stems.add(mm.group(1))
    return stems


def parse_checklist_rest_examples(checklist: str) -> set[str]:
    """REST examples — lines like '- [ ] rest/examples/rest_manage_resources.*'."""
    stems = set()
    for line in checklist.splitlines():
        mm = re.match(
            r"\s*-\s*\[\s*\]\s*rest/examples/([a-z_][a-z0-9_]*)\.\*",
            line,
        )
        if mm:
            stems.add(mm.group(1))
    return stems


def parse_checklist_relay_examples(checklist: str) -> set[str]:
    stems = set()
    for line in checklist.splitlines():
        mm = re.match(
            r"\s*-\s*\[\s*\]\s*relay/examples/([a-z_][a-z0-9_]*)\.\*",
            line,
        )
        if mm:
            stems.add(mm.group(1))
    return stems


def parse_checklist_rest_docs(checklist: str) -> set[str]:
    stems = set()
    for line in checklist.splitlines():
        mm = re.match(
            r"\s*-\s*\[\s*\]\s*rest/docs/([a-z_][a-z0-9_-]*)\.md",
            line,
        )
        if mm:
            stems.add(mm.group(1))
    return stems


def parse_checklist_relay_docs(checklist: str) -> set[str]:
    stems = set()
    for line in checklist.splitlines():
        mm = re.match(
            r"\s*-\s*\[\s*\]\s*relay/docs/([a-z_][a-z0-9_-]*)\.md",
            line,
        )
        if mm:
            stems.add(mm.group(1))
    return stems


# ---------------------------------------------------------------------------
# Drift computation
# ---------------------------------------------------------------------------

def compute_drift(
    python_sdk: Path, checklist: str,
) -> list[InventoryDrift]:
    """Diff every category. Returns drift objects (empty drift == no diff)."""
    categories: list[InventoryDrift] = []

    def add(cat: str, actual: set[str], expected: set[str]) -> None:
        drift = InventoryDrift(
            category=cat,
            in_python_not_in_checklist=sorted(actual - expected),
            in_checklist_not_in_python=sorted(expected - actual),
        )
        categories.append(drift)

    add("Skills (signalwire/skills/)",
        scan_skills(python_sdk), parse_checklist_skills(checklist))
    add("Prefabs (signalwire/prefabs/)",
        scan_prefabs(python_sdk), parse_checklist_prefabs(checklist))
    add("REST namespaces (signalwire/rest/namespaces/)",
        scan_rest_namespaces(python_sdk), parse_checklist_rest_namespaces(checklist))
    add("Top-level docs (docs/*.md)",
        scan_docs(python_sdk, "docs"), parse_checklist_docs(checklist))
    add("Agent examples (examples/*.py)",
        scan_examples(python_sdk, "examples"), parse_checklist_agent_examples(checklist))
    add("REST docs (rest/docs/*.md)",
        scan_docs(python_sdk, "rest/docs"), parse_checklist_rest_docs(checklist))
    add("REST examples (rest/examples/*.py)",
        scan_examples(python_sdk, "rest/examples"), parse_checklist_rest_examples(checklist))
    add("RELAY docs (relay/docs/*.md)",
        scan_docs(python_sdk, "relay/docs"), parse_checklist_relay_docs(checklist))
    add("RELAY examples (relay/examples/*.py)",
        scan_examples(python_sdk, "relay/examples"), parse_checklist_relay_examples(checklist))

    return categories


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def print_human(drift_list: list[InventoryDrift]) -> bool:
    """Return True if there is any drift."""
    any_drift = False
    for d in drift_list:
        if not d.has_drift:
            print(f"\033[32m✓\033[0m {d.category}: in sync")
            continue
        any_drift = True
        print(f"\033[31m✗\033[0m {d.category}")
        if d.in_python_not_in_checklist:
            print(f"    Python has, checklist missing ({len(d.in_python_not_in_checklist)}):")
            for n in d.in_python_not_in_checklist:
                print(f"      + {n}")
        if d.in_checklist_not_in_python:
            print(f"    Checklist has, Python missing ({len(d.in_checklist_not_in_python)}):")
            for n in d.in_checklist_not_in_python:
                print(f"      - {n}")
    return any_drift


def print_json(drift_list: list[InventoryDrift]) -> bool:
    any_drift = any(d.has_drift for d in drift_list)
    payload = {
        "drift": any_drift,
        "categories": [
            {
                "category": d.category,
                "in_python_not_in_checklist": d.in_python_not_in_checklist,
                "in_checklist_not_in_python": d.in_checklist_not_in_python,
            }
            for d in drift_list
        ],
    }
    print(json.dumps(payload, indent=2))
    return any_drift


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--python-sdk",
        type=Path,
        default=Path.home() / "src" / "signalwire-python",
        help="Path to the Python reference SDK (default: ~/src/signalwire-python)",
    )
    parser.add_argument(
        "--checklist",
        type=Path,
        default=Path(__file__).parent.parent / "CHECKLIST_TEMPLATE.md",
        help="Path to CHECKLIST_TEMPLATE.md (default: porting-sdk/CHECKLIST_TEMPLATE.md)",
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Emit machine-readable JSON instead of human output",
    )
    args = parser.parse_args(argv)

    if not args.python_sdk.is_dir():
        print(f"error: python SDK not found at {args.python_sdk}", file=sys.stderr)
        return 2
    if not args.checklist.is_file():
        print(f"error: checklist not found at {args.checklist}", file=sys.stderr)
        return 2

    drift_list = compute_drift(args.python_sdk, read_checklist(args.checklist))
    emit = print_json if args.json else print_human
    any_drift = emit(drift_list)
    return 1 if any_drift else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
