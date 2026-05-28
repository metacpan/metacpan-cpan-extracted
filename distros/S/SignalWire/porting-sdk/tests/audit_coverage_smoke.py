"""Smoke tests for ``scripts/audit_python_test_coverage.py``.

These tests run the actual audit against the live signalwire-python
checkout.  They are not mocks: the audit's parsers, traversal, and
classification logic all run end-to-end.  If any of these tests fail,
either:

    1. The audit has regressed on a property the gap report depends on, or
    2. The Python SDK has changed in a way that invalidates the audit
       fixtures (which means we should adjust the assertions, not the
       audit).

Run as a plain script: this file does not require pytest.

    python3 tests/audit_coverage_smoke.py
"""

from __future__ import annotations

import importlib.util
import os
import sys
from collections import defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Locate and import the audit script
# ---------------------------------------------------------------------------

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts" / "audit_python_test_coverage.py"
# CI sets PYTHON_SDK to the checkout location; locally it falls back to the
# adjacency convention (~/src/signalwire-python).
PYTHON_SDK = Path(
    os.environ.get("PYTHON_SDK") or "/home/devuser/src/signalwire-python"
)


def _import_audit():
    spec = importlib.util.spec_from_file_location(
        "audit_python_test_coverage", str(SCRIPT)
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules["audit_python_test_coverage"] = mod
    spec.loader.exec_module(mod)
    return mod


# Run the audit once and reuse across tests for speed (it parses the entire
# Python SDK source and test tree).
audit = _import_audit()
COVERAGE, SCAN, LOG = audit.run_audit(PYTHON_SDK)
print(
    f"smoke: audited {len(COVERAGE)} symbols across {SCAN.files_scanned} test files"
)


# ---------------------------------------------------------------------------
# Test 1: audit produces output without crashing
# ---------------------------------------------------------------------------


def test_audit_runs_without_crashing() -> None:
    """The audit must finish on the current Python SDK and produce a result."""
    assert COVERAGE, "audit returned no symbols — something is broken"
    assert SCAN.files_scanned > 0, "audit walked zero test files"
    # Every entry must have a status in the known set
    statuses = {entry.status() for entry in COVERAGE.values()}
    assert statuses <= {"covered", "partial", "uncovered"}, statuses


# ---------------------------------------------------------------------------
# Test 2: a known-uncovered symbol is uncovered
# ---------------------------------------------------------------------------


def test_known_partial_symbol_in_partial_list() -> None:
    """``relay.event.parse_event`` is a free function the audit's
    receiver-resolver cannot credit (free-function calls have no class
    receiver to resolve through). Real tests with content-shaped
    assertions exist in tests/unit/relay/test_event.py
    (TestParseEventBehavior + TestParseEventViaModule); the audit counts
    them as ``partial``. This test asserts the audit correctly detects
    the partial state — exercising the partial-bucket path through the
    classifier. If the audit ever credits free-function calls, swap this
    for another genuinely-partial symbol (or convert to a synthetic-input
    test like ``test_audit_handles_unparseable_test_file`` does for the
    parse-error path)."""
    target = "signalwire.relay.event.parse_event"
    entry = COVERAGE.get(target)
    assert entry is not None, f"{target} is not in the symbol index"
    assert entry.status() == "partial", (
        f"{target} expected partial but got {entry.status()}; sites="
        f"{entry.asserted!r} {entry.touched!r} {entry.referenced_only!r}"
    )


# ---------------------------------------------------------------------------
# Test 3: a known-covered symbol is covered
# ---------------------------------------------------------------------------


def test_known_covered_symbol_in_covered_list() -> None:
    """``RestClient.__init__`` is covered by every conftest.py and many
    direct constructor tests.  If this is ever uncovered, the audit's
    constructor-tracking is broken."""
    target = "signalwire.rest.client.RestClient.__init__"
    entry = COVERAGE.get(target)
    assert entry is not None, f"{target} is not in the symbol index"
    assert entry.status() == "covered", (
        f"{target} expected covered but got {entry.status()}"
    )

    # And another: CallingNamespace.dial is exercised by an
    # ``assert_called_with`` style test.
    dial = COVERAGE["signalwire.rest.namespaces.calling.CallingNamespace.dial"]
    assert dial.status() == "covered", dial.status()


# ---------------------------------------------------------------------------
# Test 4: module summary counts add up
# ---------------------------------------------------------------------------


def test_module_summary_counts_add_up() -> None:
    """For every module the per-status totals must sum to the total
    symbol count for that module."""
    by_module: dict[str, list] = defaultdict(list)
    for entry in COVERAGE.values():
        by_module[entry.module].append(entry)

    for module, entries in by_module.items():
        c = sum(1 for e in entries if e.status() == "covered")
        p = sum(1 for e in entries if e.status() == "partial")
        u = sum(1 for e in entries if e.status() == "uncovered")
        assert c + p + u == len(entries), (
            f"{module}: covered+partial+uncovered != total "
            f"({c}+{p}+{u} != {len(entries)})"
        )


# ---------------------------------------------------------------------------
# Test 5: the audit covers all the target modules listed in the spec
# ---------------------------------------------------------------------------


def test_target_modules_present() -> None:
    """Spec calls out specific modules: each must appear in the audit."""
    modules = {entry.module for entry in COVERAGE.values()}
    required = {
        "signalwire.rest._base",
        "signalwire.rest.client",
        "signalwire.rest.namespaces.calling",
        "signalwire.rest.namespaces.fabric",
        "signalwire.rest.namespaces.phone_numbers",
        "signalwire.relay.client",
        "signalwire.relay.call",
        "signalwire.relay.message",
        "signalwire.relay.event",
    }
    missing = required - modules
    assert not missing, f"audit missing target modules: {sorted(missing)}"


# ---------------------------------------------------------------------------
# Test 6: report renders without error
# ---------------------------------------------------------------------------


def test_render_report_produces_markdown() -> None:
    md = audit.render_report(COVERAGE, SCAN, LOG)
    assert md.startswith("# Python Test Coverage"), md.splitlines()[0]
    # Summary table present
    assert "| Module | Symbols | Covered | Partial | Uncovered |" in md
    # At least one section heading per module of interest
    for mod in (
        "signalwire.rest.namespaces.calling",
        "signalwire.relay.call",
        "signalwire.rest._base",
    ):
        assert f"## {mod}" in md, f"missing section for {mod}"


# ---------------------------------------------------------------------------
# Test 7: action wait/result methods on relay calls — should be partially
# or fully covered (test_call.py exercises action.wait)
# ---------------------------------------------------------------------------


def test_play_action_wait_is_covered() -> None:
    """``action.wait()`` is hit at tests/unit/relay/test_call.py:641; this
    confirms the fixture-return inference works (call -> Call -> PlayAction)."""
    entry = COVERAGE["signalwire.relay.call.PlayAction.wait"]
    # Inherits from Action; either covered or covered-via-inheritance is fine.
    assert entry.status() == "covered", (
        f"PlayAction.wait expected covered, got {entry.status()}; "
        f"asserted={entry.asserted!r}"
    )


# ---------------------------------------------------------------------------
# Test 8: integration tests are excluded
# ---------------------------------------------------------------------------


def test_integration_tests_excluded() -> None:
    """No site recorded should reference tests/integration/."""
    for entry in COVERAGE.values():
        for site in (*entry.asserted, *entry.touched, *entry.referenced_only):
            assert "/integration/" not in str(site.file), (
                f"integration test leaked into {entry.qualname}: {site.file}"
            )


def test_audit_handles_unparseable_test_file(tmp_path_factory=None) -> None:
    """The audit must not crash if a test file has a SyntaxError; the spec
    says it should "skip + log, don't crash"."""
    import tempfile
    import shutil

    # Build a tiny replica with a deliberately broken test file.
    work = Path(tempfile.mkdtemp(prefix="audit_smoke_"))
    try:
        # Minimal package skeleton
        pkg = work / "signalwire" / "signalwire"
        pkg.mkdir(parents=True)
        (pkg / "__init__.py").write_text("")
        rest_dir = pkg / "rest"
        rest_dir.mkdir()
        (rest_dir / "__init__.py").write_text("")
        (rest_dir / "_base.py").write_text(
            "class Foo:\n    def bar(self):\n        return 1\n"
        )
        relay_dir = pkg / "relay"
        relay_dir.mkdir()
        (relay_dir / "__init__.py").write_text("")
        (relay_dir / "client.py").write_text(
            "class RelayClient:\n    def connect(self):\n        return None\n"
        )

        tests = work / "tests"
        tests.mkdir()
        (tests / "broken_test.py").write_text(
            "def test_x(:\n    assert True\n"  # SyntaxError
        )
        (tests / "good_test.py").write_text(
            "from signalwire.rest._base import Foo\n"
            "def test_bar():\n"
            "    f = Foo()\n"
            "    assert f.bar() == 1\n"
        )

        coverage, scan, log = audit.run_audit(work)
        # Audit ran and recorded the broken file as a parse error
        assert any("broken_test.py" in str(p) for p in scan.parse_errors), (
            "expected broken_test.py in scan.parse_errors"
        )
        # Foo.bar from the good test should be picked up
        bar = coverage.get("signalwire.rest._base.Foo.bar")
        assert bar is not None, "Foo.bar missing from synthesized audit"
        # Either covered or partial — either is acceptable for the smoke
        assert bar.status() in ("covered", "partial"), bar.status()
    finally:
        shutil.rmtree(work, ignore_errors=True)


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------


TESTS = [
    test_audit_runs_without_crashing,
    test_known_partial_symbol_in_partial_list,
    test_known_covered_symbol_in_covered_list,
    test_module_summary_counts_add_up,
    test_target_modules_present,
    test_render_report_produces_markdown,
    test_play_action_wait_is_covered,
    test_integration_tests_excluded,
    test_audit_handles_unparseable_test_file,
]


def main() -> int:
    failures: list[tuple[str, BaseException]] = []
    for tc in TESTS:
        try:
            tc()
        except Exception as exc:  # noqa: BLE001
            failures.append((tc.__name__, exc))
            print(f"FAIL  {tc.__name__}: {exc}")
        else:
            print(f"ok    {tc.__name__}")
    if failures:
        print(f"\n{len(failures)} of {len(TESTS)} tests failed")
        return 1
    print(f"\nall {len(TESTS)} tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
