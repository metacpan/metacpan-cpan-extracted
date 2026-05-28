"""Tests for the mock RELAY server itself.

Each test drives real WebSocket I/O over ``ws://127.0.0.1:<port>`` against
the running mock — there is no patching of the ``websockets`` library.
The mock IS the harness.
"""

from __future__ import annotations

import asyncio
import json
import time
import uuid
from typing import Any

import pytest
import requests
import websockets

from mock_relay import MockRelayServer
from mock_relay.handlers import synthesize_result
from mock_relay.scenarios import (
    DialLeg,
    DialScenario,
    MethodScenario,
    ScenarioStore,
    ScriptedEvent,
    parse_dial_scenario,
    parse_method_scenario,
)
from mock_relay.schemas import load_all
from mock_relay.auth import AuthState


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _connect_params(
    project: str = "test-project",
    token: str = "test-token",
    contexts: list[str] | None = None,
    protocol: str | None = None,
) -> dict[str, Any]:
    p: dict[str, Any] = {
        "version": {"major": 2, "minor": 0, "revision": 0},
        "agent": "self-test/1.0",
        "event_acks": True,
        "authentication": {"project": project, "token": token},
    }
    if contexts:
        p["contexts"] = contexts
    if protocol:
        p["protocol"] = protocol
    return p


async def _open_authed(srv: MockRelayServer, **kwargs):
    ws = await websockets.connect(srv.ws_url)
    req_id = str(uuid.uuid4())
    await ws.send(
        json.dumps(
            {
                "jsonrpc": "2.0",
                "id": req_id,
                "method": "signalwire.connect",
                "params": _connect_params(**kwargs),
            }
        )
    )
    resp = json.loads(await ws.recv())
    return ws, resp


async def _execute(ws, method: str, inner: dict[str, Any], protocol: str = "default") -> dict[str, Any]:
    req_id = str(uuid.uuid4())
    await ws.send(
        json.dumps(
            {
                "jsonrpc": "2.0",
                "id": req_id,
                "method": "signalwire.execute",
                "params": {"protocol": protocol, "method": method, "params": inner},
            }
        )
    )
    return json.loads(await ws.recv())


# ---------------------------------------------------------------------------
# Schema loading
# ---------------------------------------------------------------------------


def test_all_schemas_loaded() -> None:
    """The relay-protocol/ directory yields >= 100 schemas without errors."""
    idx = load_all()
    assert idx.total >= 100, f"too few schemas: {idx.total}"
    assert idx.load_errors == [], f"unexpected load errors: {idx.load_errors}"
    # Every named source category is present.
    by_src = idx.by_source()
    assert by_src.get("switchblade", 0) >= 100
    assert by_src.get("blade", 0) >= 8
    assert by_src.get("messaging-python", 0) >= 4


def test_health_reports_schemas_loaded(mock_relay_server: MockRelayServer) -> None:
    r = requests.get(f"{mock_relay_server.http_url}/__mock__/health", timeout=5)
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert body["schemas_loaded"] >= 100
    assert body["schema_load_errors"] == []
    # Every named source category is present.
    by_src = body["schemas_by_source"]
    for src in ("switchblade", "blade", "messaging-python", "mod_infrastructure"):
        assert src in by_src, f"missing source bucket {src!r}: {by_src}"


def test_specs_endpoint_lists_methods(mock_relay_server: MockRelayServer) -> None:
    r = requests.get(f"{mock_relay_server.http_url}/__mock__/specs", timeout=5)
    body = r.json()
    methods = {(s["method"], s["phase"]) for s in body["specs"]}
    # Must include core verbs.
    expected_pairs = {
        ("calling.play", "params"),
        ("calling.play", "result"),
        ("calling.dial", "params"),
        ("calling.dial", "result"),
        ("calling.answer", "params"),
        ("messaging.send", "params"),
        ("messaging.send", "result"),
        ("signalwire.connect", "params"),
        ("signalwire.connect", "result"),
    }
    missing = expected_pairs - methods
    assert not missing, f"missing core method/phase pairs: {missing}"


# ---------------------------------------------------------------------------
# signalwire.connect
# ---------------------------------------------------------------------------


def test_connect_succeeds_with_creds(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, resp = await _open_authed(mock_relay_server, project="p", token="t")
        try:
            assert "result" in resp
            assert resp["result"]["protocol"].startswith("signalwire_")
            assert resp["result"]["session_restored"] is False
            assert resp["result"]["nodeid"] == "mock-relay-node-1"
        finally:
            await ws.close()

    asyncio.run(go())


def test_connect_returns_auth_required_when_creds_empty(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws = await websockets.connect(mock_relay_server.ws_url)
        try:
            req_id = str(uuid.uuid4())
            await ws.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "method": "signalwire.connect",
                        "params": _connect_params(project="", token=""),
                    }
                )
            )
            resp = json.loads(await ws.recv())
            assert "error" in resp
            assert resp["error"]["data"]["signalwire_error_code"] == "AUTH_REQUIRED"
        finally:
            await ws.close()

    asyncio.run(go())


def test_resume_via_protocol_string(mock_relay_server: MockRelayServer) -> None:
    """Reconnecting with the previously-issued protocol string yields session_restored=True."""
    async def go():
        # First connect.
        ws, resp = await _open_authed(mock_relay_server, project="p", token="t", contexts=["c1"])
        try:
            protocol = resp["result"]["protocol"]
        finally:
            await ws.close()

        # New connection with same protocol — should restore.
        ws2 = await websockets.connect(mock_relay_server.ws_url)
        try:
            req_id = str(uuid.uuid4())
            await ws2.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "method": "signalwire.connect",
                        "params": _connect_params(project="p", token="t", protocol=protocol),
                    }
                )
            )
            resp2 = json.loads(await ws2.recv())
            assert resp2["result"]["protocol"] == protocol
            assert resp2["result"]["session_restored"] is True
        finally:
            await ws2.close()

    asyncio.run(go())


# ---------------------------------------------------------------------------
# signalwire.execute — schema validation + result synthesis
# ---------------------------------------------------------------------------


def test_execute_valid_play_returns_200(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            r = await _execute(
                ws, "calling.play",
                {
                    "node_id": "n1", "call_id": "c1", "control_id": "ctl1",
                    "play": [{"type": "tts", "params": {"text": "hi"}}],
                },
                protocol=protocol,
            )
            assert "result" in r
            assert r["result"]["code"] == "200"
            assert r["result"]["call_id"] == "c1"
            assert r["result"]["control_id"] == "ctl1"
        finally:
            await ws.close()

    asyncio.run(go())


def test_execute_missing_required_param_returns_invalid_params(mock_relay_server: MockRelayServer) -> None:
    """`calling.play` requires call_id; sending without it must reject."""
    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            r = await _execute(
                ws, "calling.play",
                {"node_id": "n1", "control_id": "ctl1", "play": [{"type": "tts", "params": {"text": "hi"}}]},
                protocol=protocol,
            )
            assert "error" in r
            assert r["error"]["data"]["signalwire_error_code"] == "INVALID_PARAMS"
        finally:
            await ws.close()

    asyncio.run(go())


def test_execute_unknown_method_passes_through_with_default_ok(mock_relay_server: MockRelayServer) -> None:
    """Methods without a schema (e.g. an FS-only verb not yet in mod_infrastructure
    too) should still get a 200 OK so SDK forward-compat doesn't break."""
    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            r = await _execute(ws, "calling.unknown_future_verb", {"foo": "bar"}, protocol=protocol)
            assert r["result"]["code"] == "200"
        finally:
            await ws.close()

    asyncio.run(go())


def test_execute_dial_response_has_no_call_id(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            r = await _execute(
                ws, "calling.dial",
                {"tag": "t1", "devices": [[{"type": "phone", "params": {"to_number": "+1", "from_number": "+1"}}]]},
                protocol=protocol,
            )
            assert r["result"]["code"] == "200"
            assert r["result"]["message"] == "Dialing"
            # No call_id in dial response — that's the whole point.
            assert "call_id" not in r["result"]
        finally:
            await ws.close()

    asyncio.run(go())


def test_execute_messaging_send_returns_message_id(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            r = await _execute(
                ws, "messaging.send",
                {
                    "context": "default",
                    "to_number": "+15551112222",
                    "from_number": "+15553334444",
                    "body": "hello",
                },
                protocol=protocol,
            )
            assert r["result"]["code"] == "200"
            assert "message_id" in r["result"]
            assert isinstance(r["result"]["message_id"], str)
            assert len(r["result"]["message_id"]) > 0
        finally:
            await ws.close()

    asyncio.run(go())


# ---------------------------------------------------------------------------
# Scenarios — scripted events
# ---------------------------------------------------------------------------


def test_method_scenario_emits_scripted_events(mock_relay_server: MockRelayServer) -> None:
    """Queue a play scenario; after the RPC, the events arrive in order."""
    requests.post(
        f"{mock_relay_server.http_url}/__mock__/scenarios/calling.play",
        json=[
            {"emit": {"state": "playing"}, "delay_ms": 1},
            {"emit": {"state": "finished"}, "delay_ms": 1},
        ],
        timeout=5,
    )

    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            r = await _execute(
                ws, "calling.play",
                {
                    "node_id": "n1", "call_id": "c1", "control_id": "ctl1",
                    "play": [{"type": "tts", "params": {"text": "hi"}}],
                },
                protocol=protocol,
            )
            assert r["result"]["code"] == "200"
            # Read the two scripted events.
            evt1 = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            evt2 = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            assert evt1["method"] == "signalwire.event"
            assert evt1["params"]["event_type"] == "calling.call.play"
            assert evt1["params"]["params"]["state"] == "playing"
            # call_id was injected from request params.
            assert evt1["params"]["params"]["call_id"] == "c1"
            assert evt1["params"]["params"]["control_id"] == "ctl1"
            assert evt2["params"]["params"]["state"] == "finished"
        finally:
            await ws.close()

    asyncio.run(go())


def test_dial_scenario_emits_state_events_then_dial_event(mock_relay_server: MockRelayServer) -> None:
    """Queue a dial scenario; after the dial RPC, the state events + dial event arrive."""
    requests.post(
        f"{mock_relay_server.http_url}/__mock__/scenarios/dial",
        json={
            "tag": "dial-tag-1",
            "winner_call_id": "winner-call-1",
            "states": ["created", "ringing", "answered"],
            "node_id": "node-mock-1",
            "device": {"type": "phone", "params": {"to_number": "+1", "from_number": "+1"}},
            "delay_ms": 1,
        },
        timeout=5,
    )

    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            r = await _execute(
                ws, "calling.dial",
                {
                    "tag": "dial-tag-1",
                    "devices": [[{"type": "phone", "params": {"to_number": "+1", "from_number": "+1"}}]],
                },
                protocol=protocol,
            )
            assert r["result"]["code"] == "200"
            # 3 state events + 1 dial event.
            evts: list[dict[str, Any]] = []
            for _ in range(4):
                evt = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
                evts.append(evt)

            state_events = [e for e in evts if e["params"]["event_type"] == "calling.call.state"]
            dial_events = [e for e in evts if e["params"]["event_type"] == "calling.call.dial"]
            assert len(state_events) == 3
            assert len(dial_events) == 1

            # State events carry the tag and winner call_id.
            for e in state_events:
                p = e["params"]["params"]
                assert p["tag"] == "dial-tag-1"
                assert p["call_id"] == "winner-call-1"

            # Dial event has no top-level call_id; it's nested inside .call.
            dp = dial_events[0]["params"]["params"]
            assert "call_id" not in dp
            assert dp["dial_state"] == "answered"
            assert dp["call"]["call_id"] == "winner-call-1"
            assert dp["call"]["dial_winner"] is True
            assert dp["call"]["tag"] == "dial-tag-1"
        finally:
            await ws.close()

    asyncio.run(go())


def test_method_scenario_consumed_once(mock_relay_server: MockRelayServer) -> None:
    """A scenario fires once, then reverts to default synthesis."""
    requests.post(
        f"{mock_relay_server.http_url}/__mock__/scenarios/calling.echo",
        json=[{"emit": {"state": "echoing", "call_id": "c1"}, "delay_ms": 1}],
        timeout=5,
    )

    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        protocol = resp["result"]["protocol"]
        try:
            # First execute consumes the scenario — receives RPC + 1 event.
            await _execute(ws, "calling.echo", {"node_id": "n1", "call_id": "c1"}, protocol=protocol)
            evt = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            assert evt["method"] == "signalwire.event"

            # Second execute — receives only the RPC, no event.
            r2 = await _execute(ws, "calling.echo", {"node_id": "n1", "call_id": "c1"}, protocol=protocol)
            assert r2["result"]["code"] == "200"
            # No further frame should arrive within a short window.
            try:
                stale = await asyncio.wait_for(ws.recv(), timeout=0.2)
                # Anything that arrives must NOT be a scripted event.
                payload = json.loads(stale)
                assert payload.get("method") != "signalwire.event", \
                    f"unexpected scripted event after scenario consumed: {payload}"
            except asyncio.TimeoutError:
                pass  # expected — no stray events
        finally:
            await ws.close()

    asyncio.run(go())


def test_scenarios_reset_drains_queue(mock_relay_server: MockRelayServer) -> None:
    requests.post(
        f"{mock_relay_server.http_url}/__mock__/scenarios/calling.play",
        json=[{"emit": {"state": "playing"}, "delay_ms": 1}],
        timeout=5,
    )
    body = requests.get(f"{mock_relay_server.http_url}/__mock__/scenarios", timeout=5).json()
    assert "calling.play" in body["methods"]
    requests.post(f"{mock_relay_server.http_url}/__mock__/scenarios/reset", timeout=5)
    body2 = requests.get(f"{mock_relay_server.http_url}/__mock__/scenarios", timeout=5).json()
    assert body2["methods"] == {}
    assert body2["dial"] == []


# ---------------------------------------------------------------------------
# Journal
# ---------------------------------------------------------------------------


def test_journal_records_recv_and_send(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            await _execute(ws, "calling.answer", {"node_id": "n1", "call_id": "c1"}, protocol="ignored")
        finally:
            await ws.close()

    asyncio.run(go())

    j = requests.get(f"{mock_relay_server.http_url}/__mock__/journal", timeout=5).json()
    methods_recv = [e for e in j if e["direction"] == "recv"]
    methods_send = [e for e in j if e["direction"] == "send"]
    # We sent: connect + execute (2). We received responses to both.
    assert len(methods_recv) >= 2
    assert len(methods_send) >= 2
    # Connect frame is journaled.
    connect_frames = [e for e in methods_recv if e["method"] == "signalwire.connect"]
    assert connect_frames
    assert connect_frames[0]["frame"]["params"]["authentication"]["project"] == "test-project"


def test_journal_reset_clears_entries(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            await asyncio.sleep(0.05)
        finally:
            await ws.close()

    asyncio.run(go())
    pre = requests.get(f"{mock_relay_server.http_url}/__mock__/journal", timeout=5).json()
    assert len(pre) >= 1
    requests.post(f"{mock_relay_server.http_url}/__mock__/journal/reset", timeout=5)
    post = requests.get(f"{mock_relay_server.http_url}/__mock__/journal", timeout=5).json()
    assert post == []


def test_journal_is_bounded(mock_relay_server: MockRelayServer) -> None:
    """The ring buffer must not grow without limit."""
    j = mock_relay_server.state.journal
    j.reset()
    for i in range(1100):
        j.record_recv("conn-x", {"id": str(i), "method": "x.y", "params": {"i": i}})
    assert len(j) == 1000


def test_journal_last_received_filters_by_method(mock_relay_server: MockRelayServer) -> None:
    j = mock_relay_server.state.journal
    j.reset()
    j.record_recv("c", {"method": "calling.play", "id": "1"})
    j.record_recv("c", {"method": "calling.record", "id": "2"})
    j.record_recv("c", {"method": "calling.play", "id": "3"})
    last_play = j.last_received("calling.play")
    assert last_play is not None
    assert last_play.request_id == "3"
    last_any = j.last_received()
    assert last_any.request_id == "3"


def test_journal_sent_during_returns_post_recv_sends(mock_relay_server: MockRelayServer) -> None:
    j = mock_relay_server.state.journal
    j.reset()
    j.record_recv("c", {"method": "calling.play", "id": "1"})
    j.record_send("c", {"id": "1", "result": {"code": "200"}})
    j.record_send("c", {"method": "signalwire.event", "params": {"event_type": "calling.call.play"}})
    sent = j.sent_during("calling.play")
    # Both the response and the event were sent after the recv.
    assert len(sent) == 2
    assert sent[0].request_id == "1"
    assert sent[1].method == "signalwire.event"

    # Anchor moves to the most-recent recv: a later record call resets it.
    j.record_recv("c", {"method": "calling.record", "id": "2"})
    j.record_send("c", {"id": "2", "result": {"code": "200"}})
    # Asking again about play picks up everything since the (still earlier) play recv.
    sent_play = j.sent_during("calling.play")
    assert len(sent_play) == 3  # play response + event + record response
    sent_record = j.sent_during("calling.record")
    assert len(sent_record) == 1


# ---------------------------------------------------------------------------
# Ping
# ---------------------------------------------------------------------------


def test_ping_returns_timestamp(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            req_id = str(uuid.uuid4())
            await ws.send(json.dumps({
                "jsonrpc": "2.0", "id": req_id, "method": "signalwire.ping", "params": {}
            }))
            r = json.loads(await ws.recv())
            assert "result" in r
            assert "timestamp" in r["result"]
            assert r["result"]["timestamp"] > 0
        finally:
            await ws.close()

    asyncio.run(go())


# ---------------------------------------------------------------------------
# AuthState unit tests (unit-level, no WS)
# ---------------------------------------------------------------------------


class TestAuthState:
    def test_issue_returns_protocol(self):
        s = AuthState()
        r = s.issue("p", "t", ["default"])
        assert r.ok
        assert r.protocol and r.protocol.startswith("signalwire_")
        assert s.known_protocol(r.protocol)

    def test_issue_rejects_empty(self):
        s = AuthState()
        assert not s.issue("", "t", []).ok
        assert not s.issue("p", "", []).ok

    def test_resume_known_protocol(self):
        s = AuthState()
        first = s.issue("p", "t", [])
        assert first.ok
        second = s.resume(first.protocol)
        assert second.ok
        assert second.protocol == first.protocol

    def test_resume_unknown_protocol(self):
        s = AuthState()
        r = s.resume("signalwire_does_not_exist")
        assert not r.ok
        assert r.error_code == "AUTH_REQUIRED"


# ---------------------------------------------------------------------------
# Scenarios unit tests
# ---------------------------------------------------------------------------


class TestScenarioStore:
    def test_method_scenarios_fifo(self):
        store = ScenarioStore()
        s1 = MethodScenario(events=[ScriptedEvent(payload={"a": 1})])
        s2 = MethodScenario(events=[ScriptedEvent(payload={"b": 2})])
        store.push_method("calling.play", s1)
        store.push_method("calling.play", s2)
        assert store.pop_method("calling.play") is s1
        assert store.pop_method("calling.play") is s2
        assert store.pop_method("calling.play") is None

    def test_dial_scenarios_match_by_tag(self):
        store = ScenarioStore()
        d1 = DialScenario(tag="t1", winner_call_id="c1", states=["answered"])
        d2 = DialScenario(tag="t2", winner_call_id="c2", states=["answered"])
        store.push_dial(d1)
        store.push_dial(d2)
        # Pop by exact tag.
        assert store.pop_dial("t2") is d2
        # Untagged pop returns first remaining.
        assert store.pop_dial(None) is d1
        assert store.pop_dial(None) is None

    def test_parse_method_scenario_validates_shape(self):
        with pytest.raises(ValueError):
            parse_method_scenario({"not": "an array"})
        with pytest.raises(ValueError):
            parse_method_scenario([{"no": "emit field"}])
        ok = parse_method_scenario([{"emit": {"state": "x"}, "delay_ms": 5}])
        assert len(ok.events) == 1
        assert ok.events[0].payload == {"state": "x"}
        assert ok.events[0].delay_ms == 5

    def test_parse_dial_scenario_requires_tag_and_winner(self):
        with pytest.raises(ValueError):
            parse_dial_scenario({"winner_call_id": "x"})
        with pytest.raises(ValueError):
            parse_dial_scenario({"tag": "t"})
        ok = parse_dial_scenario({
            "tag": "t", "winner_call_id": "w",
            "states": ["created", "answered"],
            "losers": [{"call_id": "l1", "states": ["created", "ended"]}],
        })
        assert ok.tag == "t"
        assert ok.winner_call_id == "w"
        assert ok.losers[0].call_id == "l1"


# ---------------------------------------------------------------------------
# Synthesizer unit tests
# ---------------------------------------------------------------------------


class TestSynthesizer:
    def test_dial_response_omits_call_id(self):
        idx = load_all()
        r = synthesize_result("calling.dial", {"tag": "t", "devices": []}, idx)
        assert r["code"] == "200"
        assert r["message"] == "Dialing"
        assert "call_id" not in r

    def test_play_response_echoes_call_and_control_ids(self):
        idx = load_all()
        r = synthesize_result(
            "calling.play",
            {"node_id": "n", "call_id": "abc", "control_id": "ctl"},
            idx,
        )
        assert r["code"] == "200"
        assert r["call_id"] == "abc"
        assert r["control_id"] == "ctl"

    def test_messaging_send_response_has_message_id(self):
        idx = load_all()
        r = synthesize_result("messaging.send", {"to_number": "+1", "from_number": "+1", "body": "x"}, idx)
        assert "message_id" in r and r["message_id"]


# ---------------------------------------------------------------------------
# Performance: server starts in <5s
# ---------------------------------------------------------------------------


def test_server_starts_in_under_5_seconds() -> None:
    """Boot a fresh server and measure startup time."""
    import socket
    s = socket.socket(); s.bind(("127.0.0.1", 0)); ws_p = s.getsockname()[1]; s.close()
    s = socket.socket(); s.bind(("127.0.0.1", 0)); http_p = s.getsockname()[1]; s.close()
    t0 = time.time()
    srv = MockRelayServer(host="127.0.0.1", ws_port=ws_p, http_port=http_p, log_level="error").start()
    elapsed = time.time() - t0
    try:
        assert elapsed < 5.0, f"slow startup: {elapsed:.2f}s"
    finally:
        srv.stop()
