#!/usr/bin/env python3
"""audit_coverage_map.py — quantify behavioral-audit coverage per port.

Phase 5 of the cross-language signature audit (see SIGNATURE_AUDIT_PLAN.md).

The 11 audits in this directory split into two groups:

  Static / structural  (every public method gets checked by definition):
    - audit_stubs                — stub markers in source
    - audit_no_cheat_tests       — test quality
    - audit_example_parity       — example completeness
    - audit_test_parity          — test completeness
    - audit_docs                 — phantom doc references
    - audit_checklist            — checklist completeness
    - diff_port_surface          — names match Python
    - diff_port_signatures       — signatures match Python

  Behavioral (only exercise specific named methods):
    - audit_http_swml            — SWMLService.handle_request (GET + POST)
    - audit_relay_handshake      — RelayClient.connect, .subscribe, .disconnect
    - audit_skills_dispatch      — six skill handlers
    - audit_rest_transport       — REST CRUD operations

For un-fixtured methods the behavioral audits are silent — the test-2-class
gap from the prior AUDIT_COVERAGE_TESTS doc. Phase 5 doesn't close that
gap; it makes it visible. Ratcheting via CI ensures coverage never
regresses on a PR.

This script:
  1. Reads ``port_signatures.json`` to get the universe of public methods.
  2. Applies the static BEHAVIORAL_COVERAGE table below to mark which
     methods are exercised by which behavioral audit.
  3. Optionally runs the behavioral audits (--run) and only counts
     coverage where the audit exit code is 0.
  4. Writes ``audit_coverage.json`` to the port root.
  5. Compares against ``audit_coverage_baseline.json`` (if present) and
     fails if covered % regressed.

Usage:
    python3 audit_coverage_map.py --root <port-dir>
    python3 audit_coverage_map.py --root <port-dir> --run
    python3 audit_coverage_map.py --root <port-dir> --update-baseline
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PSDK = HERE.parent


# ---------------------------------------------------------------------------
# Static coverage table.
#
# Each behavioral audit exercises a known set of canonical Python methods.
# The list is cross-port (the Python-canonical method name is what matters);
# whether the port has the corresponding method emitted in port_signatures.json
# is what determines if it counts toward coverage.
# ---------------------------------------------------------------------------

BEHAVIORAL_COVERAGE: dict[str, list[str]] = {
    "audit_http_swml": [
        # SWMLService HTTP entry point. Audit drives both GET (renders SWML)
        # and POST (dispatches via OnFunctionCall) — covers the dispatch path
        # plus whatever method the test SWAIG fixture invokes.
        "signalwire.core.swml_service.SWMLService.handle_request",
        "signalwire.core.swml_service.SWMLService.render_swml",
        "signalwire.core.swml_service.SWMLService.on_function_call",
    ],
    "audit_relay_handshake": [
        # RELAY connect + subscribe + (loop receives one event)
        "signalwire.relay.client.RelayClient.connect",
        "signalwire.relay.client.RelayClient.subscribe",
        "signalwire.relay.client.RelayClient.disconnect",
    ],
    "audit_skills_dispatch": [
        # Each skill's documented handler — what the Python audit's
        # SKILL_PROBES table dispatches.
        "signalwire.skills.web_search.skill.WebSearchSkill.web_search",
        "signalwire.skills.wikipedia_search.skill.WikipediaSearchSkill.search_wiki",
        "signalwire.skills.datasphere.skill.DataSphereSkill.search_knowledge",
        "signalwire.skills.spider.skill.SpiderSkill.scrape_url",
        # DataMap-based skills don't dispatch to a Python method per se;
        # the canonical surface entry is the skill's tool name handler.
        "signalwire.skills.api_ninjas_trivia.skill.ApiNinjasTriviaSkill.get_trivia",
        "signalwire.skills.weather_api.skill.WeatherApiSkill.get_weather",
    ],
    "audit_rest_transport": [
        # REST CRUD path covered by the audit's 5-operation probe (list,
        # create, fetch, update, delete on the canonical CrudResource).
        "signalwire.rest.namespaces._crud_with_addresses.CrudWithAddresses.list",
        "signalwire.rest.namespaces._crud_with_addresses.CrudWithAddresses.create",
        "signalwire.rest.namespaces._crud_with_addresses.CrudWithAddresses.fetch",
        "signalwire.rest.namespaces._crud_with_addresses.CrudWithAddresses.update",
        "signalwire.rest.namespaces._crud_with_addresses.CrudWithAddresses.delete",
    ],
}

ALL_BEHAVIORAL_METHODS = sorted({m for ms in BEHAVIORAL_COVERAGE.values() for m in ms})


# ---------------------------------------------------------------------------
# Coverage computation
# ---------------------------------------------------------------------------


def index_port_methods(port_signatures: dict) -> set[str]:
    """Flatten port_signatures.json to the set of fully-qualified method
    canonical paths."""
    out: set[str] = set()
    for mod, mod_entry in port_signatures.get("modules", {}).items():
        for cls, cls_entry in mod_entry.get("classes", {}).items():
            for method in cls_entry.get("methods", {}):
                out.add(f"{mod}.{cls}.{method}")
        for fn in mod_entry.get("functions", {}):
            out.add(f"{mod}.{fn}")
    return out


def compute_coverage(
    port_methods: set[str],
    audits_passed: set[str],
) -> dict:
    """Return a coverage report dict."""
    # Per-method: which audits exercised it
    method_to_audits: dict[str, list[str]] = {}
    for audit, methods in BEHAVIORAL_COVERAGE.items():
        if audit not in audits_passed:
            continue
        for m in methods:
            if m in port_methods:
                method_to_audits.setdefault(m, []).append(audit)

    covered_methods = sorted(method_to_audits.keys())
    total_methods = len(port_methods)
    coverage_pct = (
        len(covered_methods) / total_methods * 100.0 if total_methods > 0 else 0.0
    )

    # Per-audit summary
    per_audit: dict[str, dict] = {}
    for audit, methods in BEHAVIORAL_COVERAGE.items():
        present = [m for m in methods if m in port_methods]
        per_audit[audit] = {
            "covered_methods": present,
            "missing_methods": [m for m in methods if m not in port_methods],
            "ran_and_passed": audit in audits_passed,
        }

    return {
        "summary": {
            "total_public_methods": total_methods,
            "covered_methods": len(covered_methods),
            "coverage_pct": round(coverage_pct, 3),
            "audits_passed": sorted(audits_passed),
        },
        "per_audit": per_audit,
        "covered_method_to_audits": method_to_audits,
    }


def run_audit(audit_name: str, root: Path) -> bool:
    """Run a behavioral audit. Return True iff exit 0."""
    script = HERE / f"{audit_name}.py"
    if not script.is_file():
        return False
    cp = subprocess.run(
        [sys.executable, str(script), "--root", str(root)],
        capture_output=True, text=True, timeout=600,
    )
    return cp.returncode == 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True,
                        help="Port repo root.")
    parser.add_argument("--signatures", type=Path, default=None,
                        help="Path to port_signatures.json (default: <root>/port_signatures.json).")
    parser.add_argument("--run", action="store_true",
                        help="Run each behavioral audit and only count coverage where exit==0. "
                             "Without this, all audits in BEHAVIORAL_COVERAGE are assumed to pass.")
    parser.add_argument("--out", type=Path, default=None,
                        help="Output coverage JSON (default: <root>/audit_coverage.json).")
    parser.add_argument("--baseline", type=Path, default=None,
                        help="Baseline JSON to ratchet against (default: <root>/audit_coverage_baseline.json).")
    parser.add_argument("--update-baseline", action="store_true",
                        help="Write the current coverage as the new baseline.")
    args = parser.parse_args()

    root = args.root.resolve()
    sig_path = args.signatures or (root / "port_signatures.json")
    out_path = args.out or (root / "audit_coverage.json")
    baseline_path = args.baseline or (root / "audit_coverage_baseline.json")

    if not sig_path.is_file():
        print(f"audit_coverage_map: no port_signatures.json at {sig_path}", file=sys.stderr)
        return 2

    port_signatures = json.loads(sig_path.read_text(encoding="utf-8"))
    port_methods = index_port_methods(port_signatures)

    # Determine which audits passed
    if args.run:
        audits_passed = set()
        for audit in BEHAVIORAL_COVERAGE:
            ok = run_audit(audit, root)
            if ok:
                audits_passed.add(audit)
            print(f"  {audit}: {'PASS' if ok else 'FAIL'}", file=sys.stderr)
    else:
        audits_passed = set(BEHAVIORAL_COVERAGE.keys())

    report = compute_coverage(port_methods, audits_passed)

    out_path.write_text(json.dumps(report, indent=2, sort_keys=False) + "\n", encoding="utf-8")

    summary = report["summary"]
    print(
        f"audit_coverage_map: {summary['coverage_pct']:.2f}% behavioral coverage "
        f"({summary['covered_methods']} of {summary['total_public_methods']} "
        f"public methods exercised by ≥1 behavioral audit)"
    )

    # Ratchet
    if args.update_baseline:
        baseline_path.write_text(
            json.dumps({
                "coverage_pct": summary["coverage_pct"],
                "covered_methods": summary["covered_methods"],
                "covered_method_list": sorted(report["covered_method_to_audits"].keys()),
            }, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"  wrote new baseline: {baseline_path}")
        return 0

    if baseline_path.is_file():
        baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
        baseline_pct = baseline.get("coverage_pct", 0.0)
        baseline_methods = set(baseline.get("covered_method_list", []))
        current_methods = set(report["covered_method_to_audits"].keys())
        regressed = baseline_methods - current_methods
        if regressed:
            print(
                f"\033[31m✗\033[0m coverage regressed: {len(regressed)} method(s) "
                f"covered in baseline but not now:",
                file=sys.stderr,
            )
            for m in sorted(regressed):
                print(f"    - {m}", file=sys.stderr)
            print(
                f"  baseline coverage: {baseline_pct:.2f}%; current: {summary['coverage_pct']:.2f}%",
                file=sys.stderr,
            )
            return 1
        if summary["coverage_pct"] < baseline_pct - 0.01:
            print(
                f"\033[31m✗\033[0m coverage % regressed: baseline {baseline_pct:.2f}% "
                f"vs current {summary['coverage_pct']:.2f}%",
                file=sys.stderr,
            )
            return 1
        print(f"  baseline ratchet ok ({baseline_pct:.2f}% baseline, {summary['coverage_pct']:.2f}% current)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
