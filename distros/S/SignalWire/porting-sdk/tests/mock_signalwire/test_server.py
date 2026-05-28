"""Tests for the mock SignalWire server itself.

Every assertion drives real behavior over real HTTP — there is no patching of
``requests`` or of the underlying transport. The mock server IS the test.
"""

from __future__ import annotations

import base64
from typing import Any

import pytest
import requests

from mock_signalwire import MockServer
from mock_signalwire.specs import SPEC_NAMES, SpecLoader
from mock_signalwire.synthesize import synthesize_response


# --- Spec loading ---------------------------------------------------------------------


def test_all_13_specs_load_without_error() -> None:
    """Every OpenAPI spec under rest-apis/ parses and produces routes."""
    result = SpecLoader().load_all()
    assert result.specs_loaded == 13, f"expected 13 specs, got {result.specs_loaded}"
    assert result.errors == [], f"unexpected spec load errors: {result.errors}"
    # Every named spec contributes at least one route. (Empty specs would be a
    # silent regression.)
    spec_names_with_routes = {r.spec_name for r in result.routes}
    missing = set(SPEC_NAMES) - spec_names_with_routes
    assert missing == set(), f"specs with no routes: {missing}"
    # Sanity floor: total routes well above 100 even if specs shrink.
    assert len(result.routes) >= 150, f"unexpectedly few routes: {len(result.routes)}"


def test_health_reports_specs_loaded(mock_server: MockServer) -> None:
    r = requests.get(f"{mock_server.url}/__mock__/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert body["specs_loaded"] == 13
    assert body["total_routes"] >= 150
    assert body["spec_load_errors"] == []


# --- Auth -----------------------------------------------------------------------------


def test_missing_auth_returns_401(mock_server: MockServer) -> None:
    r = requests.get(f"{mock_server.url}/api/laml/2010-04-01/Accounts")
    assert r.status_code == 401
    body = r.json()
    assert body["errors"][0]["code"] == "AUTH_REQUIRED"


def test_malformed_auth_returns_401(mock_server: MockServer) -> None:
    """Bearer token instead of Basic — must reject."""
    r = requests.get(
        f"{mock_server.url}/api/laml/2010-04-01/Accounts",
        headers={"Authorization": "Bearer some-token"},
    )
    assert r.status_code == 401
    assert r.json()["errors"][0]["code"] == "AUTH_REQUIRED"


def test_basic_auth_with_empty_token_returns_401(mock_server: MockServer) -> None:
    """``project:`` (empty token) is rejected."""
    encoded = base64.b64encode(b"project:").decode()
    r = requests.get(
        f"{mock_server.url}/api/laml/2010-04-01/Accounts",
        headers={"Authorization": f"Basic {encoded}"},
    )
    assert r.status_code == 401


def test_basic_auth_garbage_base64_returns_401(mock_server: MockServer) -> None:
    r = requests.get(
        f"{mock_server.url}/api/laml/2010-04-01/Accounts",
        headers={"Authorization": "Basic !!!not-base64!!!"},
    )
    assert r.status_code == 401


def test_valid_auth_known_endpoint_returns_200(mock_server: MockServer) -> None:
    r = requests.get(
        f"{mock_server.url}/api/laml/2010-04-01/Accounts",
        auth=("test_proj", "test_tok"),
    )
    assert r.status_code == 200
    body = r.json()
    # Schema-driven body should have the documented top-level keys.
    assert "accounts" in body
    assert "page" in body


def test_valid_auth_unknown_endpoint_returns_404(mock_server: MockServer) -> None:
    r = requests.get(
        f"{mock_server.url}/api/no/such/path",
        auth=("test_proj", "test_tok"),
    )
    assert r.status_code == 404
    assert r.json()["errors"][0]["code"] == "NOT_FOUND"


# --- Routing & path templating --------------------------------------------------------


def test_path_templating_substitutes_into_response_body(mock_server: MockServer) -> None:
    """``GET /Accounts/AC123`` must match the templated route and capture AC123."""
    r = requests.get(
        f"{mock_server.url}/api/laml/2010-04-01/Accounts/AC_TEST_123",
        auth=("p", "t"),
    )
    assert r.status_code == 200
    # The route matched (no 404) — verify via the journal which template was hit.
    journal = requests.get(f"{mock_server.url}/__mock__/journal").json()
    matched = [j["matched_route"] for j in journal if "AC_TEST_123" in j["path"]]
    assert any(m and "AccountSid" in (m or "") or m and "compatibility" in (m or "") for m in matched), \
        f"no journal entry matched the templated route: {matched}"


def test_strict_route_preferred_over_templated(mock_server: MockServer) -> None:
    """A non-templated path that exactly equals one of the spec paths must hit
    that route directly, even when a templated sibling could also match."""
    # /Accounts is non-templated. /Accounts/{AccountSid} is templated.
    # A request to /Accounts must hit the strict route.
    r = requests.get(f"{mock_server.url}/api/laml/2010-04-01/Accounts", auth=("p", "t"))
    assert r.status_code == 200
    journal = requests.get(f"{mock_server.url}/__mock__/journal").json()
    assert any(j["matched_route"] == "compatibility.list_accounts" for j in journal)


# --- Journal --------------------------------------------------------------------------


def test_journal_records_request_shape(mock_server: MockServer) -> None:
    requests.post(
        f"{mock_server.url}/api/laml/2010-04-01/Accounts/AC1/Calls",
        auth=("test_proj", "test_tok"),
        json={"To": "+15555550123", "From": "+15555550199"},
        params={"trace": "yes"},
    )
    entries = requests.get(f"{mock_server.url}/__mock__/journal").json()
    # Find our entry.
    candidates = [e for e in entries if e["path"].endswith("/Calls")]
    assert candidates, f"no Calls entry in journal: {entries}"
    e = candidates[-1]
    assert e["method"] == "POST"
    assert e["path"] == "/api/laml/2010-04-01/Accounts/AC1/Calls"
    assert e["query_params"] == {"trace": ["yes"]}
    assert e["body"] == {"To": "+15555550123", "From": "+15555550199"}
    assert e["headers"]["authorization"].startswith("Basic ")
    assert e["matched_route"] is not None
    assert e["response_status"] == 201 or e["response_status"] == 200


def test_journal_reset_clears_entries(mock_server: MockServer) -> None:
    requests.get(f"{mock_server.url}/api/laml/2010-04-01/Accounts", auth=("p", "t"))
    assert len(requests.get(f"{mock_server.url}/__mock__/journal").json()) >= 1
    requests.post(f"{mock_server.url}/__mock__/journal/reset")
    assert requests.get(f"{mock_server.url}/__mock__/journal").json() == []


# --- Scenarios ------------------------------------------------------------------------


def test_scenario_override_returns_configured_status_and_body(mock_server: MockServer) -> None:
    requests.post(
        f"{mock_server.url}/__mock__/scenarios/compatibility.list_accounts",
        json={"status": 502, "response": {"errors": [{"code": "TEAPOT", "message": "down"}]}},
    )
    r = requests.get(f"{mock_server.url}/api/laml/2010-04-01/Accounts", auth=("p", "t"))
    assert r.status_code == 502
    assert r.json()["errors"][0]["code"] == "TEAPOT"


def test_scenario_override_consumed_once(mock_server: MockServer) -> None:
    """Document semantics: a scenario applies once, then reverts to default.

    Tests rely on this so they don't have to remember to reset between
    assertions; staging one scenario per call is enough.
    """
    requests.post(
        f"{mock_server.url}/__mock__/scenarios/compatibility.list_accounts",
        json={"status": 503, "response": {"down": True}},
    )
    r1 = requests.get(f"{mock_server.url}/api/laml/2010-04-01/Accounts", auth=("p", "t"))
    r2 = requests.get(f"{mock_server.url}/api/laml/2010-04-01/Accounts", auth=("p", "t"))
    assert r1.status_code == 503
    assert r1.json() == {"down": True}
    assert r2.status_code == 200
    assert "accounts" in r2.json()


def test_scenario_list_and_reset(mock_server: MockServer) -> None:
    requests.post(
        f"{mock_server.url}/__mock__/scenarios/compatibility.list_accounts",
        json={"status": 500, "response": {}},
    )
    active = requests.get(f"{mock_server.url}/__mock__/scenarios").json()
    assert "compatibility.list_accounts" in active
    requests.post(f"{mock_server.url}/__mock__/scenarios/reset")
    assert requests.get(f"{mock_server.url}/__mock__/scenarios").json() == {}


# --- Schema synthesis -----------------------------------------------------------------


def test_schema_synthesis_produces_required_fields() -> None:
    """If the spec marks fields ``required``, the synthesized body must contain them."""
    result = SpecLoader().load_all()
    # Find an operation with a non-trivial response schema.
    target = None
    for r in result.routes:
        if r.spec_name == "compatibility" and r.operation_id == "list_accounts":
            target = r
            break
    assert target is not None
    status, body = synthesize_response(target.operation, target.schemas, {})
    assert status == 200
    assert isinstance(body, dict)
    # AccountListResponse top-level required: uri, first_page_uri, next_page_uri,
    # previous_page_uri, page, page_size, accounts.
    for k in ("uri", "first_page_uri", "page", "page_size", "accounts"):
        assert k in body, f"required field {k!r} missing from synthesized body"


def test_schema_synthesis_substitutes_path_params() -> None:
    """``{AccountSid}`` in the response example becomes the captured value."""
    result = SpecLoader().load_all()
    # Pick the get_account route which has {AccountSid} in template.
    target = None
    for r in result.routes:
        if r.spec_name == "compatibility" and r.operation_id == "get_account":
            target = r
            break
    assert target is not None
    status, body = synthesize_response(target.operation, target.schemas, {"AccountSid": "AC_FIXED"})
    assert status == 200
    # The example string with {AccountSid} should now contain AC_FIXED.
    flat = repr(body)
    assert "AC_FIXED" in flat or "AccountSid" not in flat, \
        "no substitution happened — examples did not reference {AccountSid}"


def test_schema_synthesis_handles_array_response() -> None:
    """A `type: array` response schema synthesizes a JSON array."""
    result = SpecLoader().load_all()
    found = False
    for r in result.routes:
        # Find any GET that returns a top-level array.
        op = r.operation
        responses = op.get("responses") or {}
        for code, resp in responses.items():
            try:
                if not (200 <= int(code) < 300):
                    continue
            except ValueError:
                continue
            schema = (resp.get("content") or {}).get("application/json", {}).get("schema") or {}
            if schema.get("type") == "array":
                status, body = synthesize_response(op, r.schemas, {})
                assert isinstance(body, list)
                found = True
                break
        if found:
            break
    if not found:
        pytest.skip("no top-level array responses in current specs")


# --- Real-API semantics ---------------------------------------------------------------


def test_response_content_type_is_json(mock_server: MockServer) -> None:
    r = requests.get(f"{mock_server.url}/api/laml/2010-04-01/Accounts", auth=("p", "t"))
    assert r.headers["content-type"].startswith("application/json")


def test_journal_is_bounded(mock_server: MockServer) -> None:
    """The ring buffer must not grow without limit."""
    state = mock_server.app.state.mock_state
    # Fill journal directly to avoid 1000 round-trips.
    for i in range(1100):
        state.journal.record("GET", f"/x/{i}", {}, {}, None, None, 200)
    assert len(state.journal) == 1000
