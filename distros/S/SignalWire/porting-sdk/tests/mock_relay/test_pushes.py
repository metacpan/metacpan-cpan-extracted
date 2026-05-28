"""Tests for server-initiated event pushes — the HTTP control plane endpoints
that lets a test inject frames into a connected SDK with no preceding RPC.

Pairs with the existing ``test_server.py`` (which covers SDK-initiated RPC and
post-RPC scenario events). The endpoints exercised here are:

* ``GET  /__mock__/sessions``
* ``POST /__mock__/push``
* ``POST /__mock__/push?session_id=<id>``
* ``POST /__mock__/inbound_call``
* ``POST /__mock__/scenario_play``
* ``POST /__mock__/scenarios/_unconditional``
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


# ---------------------------------------------------------------------------
# Helpers (parallel to test_server's equivalents but local so a refactor of
# either file doesn't ripple).
# ---------------------------------------------------------------------------


def _connect_params(
    project: str = "test-project",
    token: str = "test-token",
    contexts: list[str] | None = None,
    protocol: str | None = None,
) -> dict[str, Any]:
    p: dict[str, Any] = {
        "version": {"major": 2, "minor": 0, "revision": 0},
        "agent": "push-test/1.0",
        "event_acks": True,
        "authentication": {"project": project, "token": token},
    }
    if contexts:
        p["contexts"] = contexts
    if protocol:
        p["protocol"] = protocol
    return p


async def _open_authed(srv: MockRelayServer, project: str = "p", token: str = "t"):
    ws = await websockets.connect(srv.ws_url)
    req_id = str(uuid.uuid4())
    await ws.send(
        json.dumps(
            {
                "jsonrpc": "2.0",
                "id": req_id,
                "method": "signalwire.connect",
                "params": _connect_params(project=project, token=token),
            }
        )
    )
    resp = json.loads(await ws.recv())
    return ws, resp


def _http_post(
    srv: MockRelayServer, path: str, json_body: Any, **query: Any
) -> requests.Response:
    return requests.post(
        f"{srv.http_url}{path}",
        json=json_body,
        params=query if query else None,
        timeout=5,
    )


def _http_get(srv: MockRelayServer, path: str) -> requests.Response:
    return requests.get(f"{srv.http_url}{path}", timeout=5)


def _signalwire_event(event_type: str, inner: dict[str, Any]) -> dict[str, Any]:
    return {
        "jsonrpc": "2.0",
        "id": str(uuid.uuid4()),
        "method": "signalwire.event",
        "params": {"event_type": event_type, "params": inner},
    }


# ---------------------------------------------------------------------------
# /__mock__/sessions
# ---------------------------------------------------------------------------


def test_sessions_endpoint_lists_active_connections(
    mock_relay_server: MockRelayServer,
) -> None:
    """One connect → ``GET /__mock__/sessions`` shows a single active session."""
    holder: dict[str, Any] = {}

    async def go():
        ws, resp = await _open_authed(mock_relay_server)
        try:
            holder["protocol"] = resp["result"]["protocol"]
            # While the WS is still open, query sessions over HTTP.
            sess_resp = await asyncio.to_thread(
                _http_get, mock_relay_server, "/__mock__/sessions"
            )
            holder["sessions_payload"] = sess_resp.json()
            holder["status"] = sess_resp.status_code
        finally:
            await ws.close()

    asyncio.run(go())

    assert holder["status"] == 200
    payload = holder["sessions_payload"]
    sessions = payload["sessions"]
    assert len(sessions) == 1, f"expected 1 session, got {sessions}"
    s = sessions[0]
    # Every documented field is present.
    for key in ("id", "connected_at", "peer_addr", "protocol_string"):
        assert key in s, f"missing key {key!r} in session metadata: {s}"
    assert isinstance(s["id"], str) and s["id"]
    assert s["protocol_string"] == holder["protocol"]
    assert s["peer_addr"].startswith("127.0.0.1:")
    assert isinstance(s["connected_at"], (float, int))
    assert s["connected_at"] > 0


def test_sessions_endpoint_empty_when_no_connections(
    mock_relay_server: MockRelayServer,
) -> None:
    payload = _http_get(mock_relay_server, "/__mock__/sessions").json()
    assert payload == {"sessions": []}


def test_sessions_endpoint_lists_multiple_concurrent(
    mock_relay_server: MockRelayServer,
) -> None:
    """Two concurrent WS connections → both show up in sessions."""

    async def go():
        ws1, resp1 = await _open_authed(mock_relay_server, project="p1")
        ws2, resp2 = await _open_authed(mock_relay_server, project="p2")
        try:
            sess = await asyncio.to_thread(
                lambda: _http_get(mock_relay_server, "/__mock__/sessions").json()
            )
            return sess, resp1["result"]["protocol"], resp2["result"]["protocol"]
        finally:
            await ws1.close()
            await ws2.close()

    sess_payload, p1, p2 = asyncio.run(go())
    sessions = sess_payload["sessions"]
    assert len(sessions) == 2, f"expected 2 sessions, got {sessions}"
    found_protocols = {s["protocol_string"] for s in sessions}
    assert found_protocols == {p1, p2}


def test_sessions_drop_after_disconnect(mock_relay_server: MockRelayServer) -> None:
    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        await ws.close()
        # Tiny grace period — server registers unregister in the WS task's
        # finally block, which only runs after close() is observed on the
        # server side.
        await asyncio.sleep(0.05)
        return _http_get(mock_relay_server, "/__mock__/sessions").json()

    sess = asyncio.run(go())
    assert sess["sessions"] == []


# ---------------------------------------------------------------------------
# /__mock__/push (broadcast + targeted)
# ---------------------------------------------------------------------------


def test_push_broadcasts_to_all_connections(mock_relay_server: MockRelayServer) -> None:
    """Two SDKs connected; one POST to /push → both receive the frame."""
    frame = _signalwire_event(
        "calling.call.state",
        {
            "call_id": "broadcast-call",
            "call_state": "created",
            "direction": "inbound",
            "device": {"type": "phone"},
        },
    )

    async def go():
        ws1, _ = await _open_authed(mock_relay_server, project="A")
        ws2, _ = await _open_authed(mock_relay_server, project="B")
        try:
            push_resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/push", {"frame": frame}
                ).json()
            )
            evt1 = json.loads(await asyncio.wait_for(ws1.recv(), timeout=2))
            evt2 = json.loads(await asyncio.wait_for(ws2.recv(), timeout=2))
            return push_resp, evt1, evt2
        finally:
            await ws1.close()
            await ws2.close()

    push_resp, evt1, evt2 = asyncio.run(go())

    # API contract.
    assert push_resp["count"] == 2
    assert isinstance(push_resp["sent_to"], list)
    assert len(push_resp["sent_to"]) == 2
    # Both clients got the same content.
    for evt in (evt1, evt2):
        assert evt["method"] == "signalwire.event"
        assert evt["params"]["event_type"] == "calling.call.state"
        assert evt["params"]["params"]["call_id"] == "broadcast-call"
        assert evt["params"]["params"]["call_state"] == "created"


def test_push_targeted_to_one_session(mock_relay_server: MockRelayServer) -> None:
    """``?session_id=X`` only delivers to X; the other client must NOT see the frame."""
    frame = _signalwire_event(
        "calling.call.state",
        {"call_id": "targeted-1", "call_state": "ringing", "direction": "inbound"},
    )

    async def go():
        ws1, _ = await _open_authed(mock_relay_server, project="A")
        ws2, _ = await _open_authed(mock_relay_server, project="B")
        try:
            sess = await asyncio.to_thread(
                lambda: _http_get(mock_relay_server, "/__mock__/sessions").json()
            )
            sessions = sess["sessions"]
            assert len(sessions) == 2
            target_id = sessions[0]["id"]

            push_resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server,
                    "/__mock__/push",
                    {"frame": frame},
                    session_id=target_id,
                ).json()
            )

            # Both clients race to recv. Whoever the target was should get the
            # frame; the other must time out.
            recv_results: dict[str, Any] = {}

            async def race(name: str, ws):
                try:
                    payload = json.loads(await asyncio.wait_for(ws.recv(), timeout=0.6))
                    recv_results[name] = payload
                except asyncio.TimeoutError:
                    recv_results[name] = None

            await asyncio.gather(race("a", ws1), race("b", ws2))
            return push_resp, target_id, sessions, recv_results
        finally:
            await ws1.close()
            await ws2.close()

    push_resp, target_id, sessions, recv_results = asyncio.run(go())

    assert push_resp["count"] == 1
    assert push_resp["sent_to"] == [target_id]

    # Exactly one of (a, b) received the frame; the other timed out.
    received = [k for k, v in recv_results.items() if v is not None]
    assert len(received) == 1, f"expected exactly one client to get frame: {recv_results}"
    delivered_payload = recv_results[received[0]]
    assert delivered_payload["params"]["params"]["call_id"] == "targeted-1"


def test_push_targeted_to_unknown_session_404(
    mock_relay_server: MockRelayServer,
) -> None:
    frame = _signalwire_event("calling.call.state", {"call_state": "x"})
    r = _http_post(
        mock_relay_server,
        "/__mock__/push",
        {"frame": frame},
        session_id="does-not-exist",
    )
    assert r.status_code == 404
    body = r.json()
    assert body["count"] == 0
    assert body["sent_to"] == []
    assert "no such session" in body.get("error", "")


def test_push_invalid_body_400(mock_relay_server: MockRelayServer) -> None:
    """No 'frame' field → 400."""
    r = _http_post(mock_relay_server, "/__mock__/push", {"oops": "no frame"})
    assert r.status_code == 400
    body = r.json()
    assert "frame" in body.get("error", "")


def test_push_when_no_clients_returns_empty(mock_relay_server: MockRelayServer) -> None:
    """Broadcast with zero connected sessions: count=0, no error."""
    frame = _signalwire_event("calling.call.state", {"call_state": "x"})
    r = _http_post(mock_relay_server, "/__mock__/push", {"frame": frame})
    assert r.status_code == 200
    body = r.json()
    assert body == {"sent_to": [], "count": 0}


def test_push_journals_with_session_id(mock_relay_server: MockRelayServer) -> None:
    """Pushed frames appear in the journal tagged with the receiving session_id."""
    frame = _signalwire_event(
        "calling.call.state", {"call_id": "journal-test", "call_state": "answered"}
    )

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            push_resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/push", {"frame": frame}
                ).json()
            )
            await asyncio.wait_for(ws.recv(), timeout=2)
            return push_resp
        finally:
            await ws.close()

    push_resp = asyncio.run(go())
    target_session = push_resp["sent_to"][0]

    journal = _http_get(mock_relay_server, "/__mock__/journal").json()
    pushed = [
        e for e in journal
        if e["direction"] == "send"
        and e["frame"].get("method") == "signalwire.event"
        and e["frame"]["params"]["params"].get("call_id") == "journal-test"
    ]
    assert pushed, "pushed frame missing from journal"
    assert pushed[0]["session_id"] == target_session


# ---------------------------------------------------------------------------
# /__mock__/inbound_call
# ---------------------------------------------------------------------------


def test_inbound_call_default_emits_created(mock_relay_server: MockRelayServer) -> None:
    """No auto_states → defaults to a single ``created`` event."""
    body = {
        "call_id": "incoming-1",
        "from_number": "+15551234567",
        "to_number": "+15559876543",
        "context": "default",
    }

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/inbound_call", body
                ).json()
            )
            evt = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            return resp, evt
        finally:
            await ws.close()

    resp, evt = asyncio.run(go())

    assert resp["call_id"] == "incoming-1"
    assert resp["states_emitted"] == ["created"]
    assert resp["count"] == 1

    p = evt["params"]
    assert evt["method"] == "signalwire.event"
    # The first inbound state arrives as ``calling.call.receive`` (the real
    # server's wire shape — see events.md). Subsequent states would be
    # ``calling.call.state`` updates.
    assert p["event_type"] == "calling.call.receive"
    assert p["params"]["call_id"] == "incoming-1"
    assert p["params"]["call_state"] == "created"
    assert p["params"]["direction"] == "inbound"
    assert p["params"]["device"]["params"]["from_number"] == "+15551234567"
    assert p["params"]["device"]["params"]["to_number"] == "+15559876543"


def test_inbound_call_emits_state_sequence_with_paced_timing(
    mock_relay_server: MockRelayServer,
) -> None:
    """auto_states=[created, ringing, answered] emits 3 events, paced ~delay_ms apart."""
    body = {
        "call_id": "incoming-paced",
        "from_number": "+15550001111",
        "to_number": "+15552223333",
        "context": "default",
        "auto_states": ["created", "ringing", "answered"],
        "delay_ms": 50,
    }

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            t0 = time.time()
            resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/inbound_call", body
                ).json()
            )
            t1 = time.time()
            evts = []
            for _ in range(3):
                evts.append(json.loads(await asyncio.wait_for(ws.recv(), timeout=2)))
            return resp, evts, t1 - t0
        finally:
            await ws.close()

    resp, evts, elapsed = asyncio.run(go())
    assert resp["states_emitted"] == ["created", "ringing", "answered"]
    states = [e["params"]["params"]["call_state"] for e in evts]
    assert states == ["created", "ringing", "answered"]
    # First event is the inbound receive; subsequent are state updates.
    event_types = [e["params"]["event_type"] for e in evts]
    assert event_types[0] == "calling.call.receive"
    assert event_types[1:] == ["calling.call.state", "calling.call.state"]
    # 50ms between each of 3 = 100ms; allow generous slack.
    assert elapsed >= 0.08, f"sequence too fast ({elapsed:.3f}s) — pacing missing"


def test_inbound_call_targeted_session(mock_relay_server: MockRelayServer) -> None:
    """``session_id`` field targets one connected SDK; the other does not get the call."""

    async def go():
        ws1, _ = await _open_authed(mock_relay_server, project="A")
        ws2, _ = await _open_authed(mock_relay_server, project="B")
        try:
            sess = await asyncio.to_thread(
                lambda: _http_get(mock_relay_server, "/__mock__/sessions").json()
            )
            target = sess["sessions"][0]["id"]
            body = {
                "session_id": target,
                "call_id": "targeted-inbound",
                "from_number": "+15550000000",
                "to_number": "+15551111111",
            }
            resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/inbound_call", body
                ).json()
            )

            recv: dict[str, Any] = {}

            async def race(name: str, ws):
                try:
                    recv[name] = json.loads(
                        await asyncio.wait_for(ws.recv(), timeout=0.6)
                    )
                except asyncio.TimeoutError:
                    recv[name] = None

            await asyncio.gather(race("a", ws1), race("b", ws2))
            return resp, target, recv
        finally:
            await ws1.close()
            await ws2.close()

    resp, target, recv = asyncio.run(go())
    assert resp["count"] == 1
    assert resp["sent_to"] == [target]
    received = [k for k, v in recv.items() if v is not None]
    assert len(received) == 1


def test_inbound_call_unknown_session_404(mock_relay_server: MockRelayServer) -> None:
    body = {
        "session_id": "no-such-session",
        "call_id": "x",
        "from_number": "+1",
        "to_number": "+1",
    }
    r = _http_post(mock_relay_server, "/__mock__/inbound_call", body)
    assert r.status_code == 404


def test_inbound_call_generates_call_id_when_omitted(
    mock_relay_server: MockRelayServer,
) -> None:
    """Omitting call_id is allowed; the server invents one and reports it."""
    body = {"from_number": "+15550000001", "to_number": "+15550000002"}

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/inbound_call", body
                ).json()
            )
            evt = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            return resp, evt
        finally:
            await ws.close()

    resp, evt = asyncio.run(go())
    assert isinstance(resp["call_id"], str) and resp["call_id"]
    # The event carries the same call_id.
    assert evt["params"]["params"]["call_id"] == resp["call_id"]


# ---------------------------------------------------------------------------
# /__mock__/scenario_play
# ---------------------------------------------------------------------------


def test_scenario_play_executes_sleep_push_sequence(
    mock_relay_server: MockRelayServer,
) -> None:
    """sleep_ms followed by push delivers the frame after the sleep."""
    frame = _signalwire_event(
        "calling.call.state",
        {"call_id": "sp-1", "call_state": "created", "direction": "inbound"},
    )
    script = [
        {"sleep_ms": 50},
        {"push": {"frame": frame}},
    ]

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            t0 = time.time()
            resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/scenario_play", script
                ).json()
            )
            t1 = time.time()
            evt = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            return resp, evt, t1 - t0
        finally:
            await ws.close()

    resp, evt, elapsed = asyncio.run(go())
    assert resp == {"status": "completed", "steps": 2}
    assert evt["params"]["params"]["call_id"] == "sp-1"
    assert elapsed >= 0.04, f"expected scenario_play to honour 50ms sleep, got {elapsed:.3f}s"


def test_scenario_play_expect_recv_blocks_until_match(
    mock_relay_server: MockRelayServer,
) -> None:
    """expect_recv waits for the SDK to send the named method, then continues."""
    push1 = _signalwire_event(
        "calling.call.state",
        {"call_id": "ec-1", "call_state": "created", "direction": "inbound"},
    )
    push2 = _signalwire_event(
        "calling.call.state",
        {"call_id": "ec-1", "call_state": "answered", "direction": "inbound"},
    )
    script = [
        {"push": {"frame": push1}},
        {"expect_recv": {"method": "calling.answer", "timeout_ms": 3000}},
        {"push": {"frame": push2}},
    ]

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            # Drive the scenario in a thread; in this loop we receive the
            # ``created`` push, send a ``calling.answer``, then receive the
            # ``answered`` push.

            script_fut: dict[str, Any] = {}

            def run_script():
                script_fut["resp"] = _http_post(
                    mock_relay_server, "/__mock__/scenario_play", script
                ).json()

            t = asyncio.create_task(asyncio.to_thread(run_script))

            evt1 = json.loads(await asyncio.wait_for(ws.recv(), timeout=3))
            assert evt1["params"]["params"]["call_state"] == "created"

            # Echo back a calling.answer execute.
            await ws.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": str(uuid.uuid4()),
                        "method": "calling.answer",
                        "params": {"node_id": "n1", "call_id": "ec-1"},
                    }
                )
            )
            # The mock responds to the answer call.
            ans_resp = json.loads(await asyncio.wait_for(ws.recv(), timeout=3))
            assert ans_resp.get("result", {}).get("code") == "200"

            # The expect_recv should now unblock and the next push arrive.
            evt2 = json.loads(await asyncio.wait_for(ws.recv(), timeout=3))
            assert evt2["params"]["params"]["call_state"] == "answered"

            await t
            return script_fut["resp"]
        finally:
            await ws.close()

    resp = asyncio.run(go())
    assert resp == {"status": "completed", "steps": 3}


def test_scenario_play_expect_recv_timeout_aborts(
    mock_relay_server: MockRelayServer,
) -> None:
    """If the SDK never sends the expected method, expect_recv times out and
    the scenario reports the step it was on."""
    script = [
        {"push": {"frame": _signalwire_event("calling.call.state", {"x": 1})}},
        {"expect_recv": {"method": "calling.never_sent", "timeout_ms": 200}},
        {"push": {"frame": _signalwire_event("never.runs", {})}},
    ]

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server, "/__mock__/scenario_play", script
                ).json()
            )
            return resp
        finally:
            await ws.close()

    resp = asyncio.run(go())
    assert resp["status"] == "timeout"
    assert resp["at_step"] == 1
    assert resp["expected_method"] == "calling.never_sent"
    # First push was completed before the timeout step.
    assert resp["steps_completed"] == 1


def test_scenario_play_expect_recv_with_session_id_filters(
    mock_relay_server: MockRelayServer,
) -> None:
    """expect_recv with session_id only matches frames from that session."""
    script_holder: dict[str, Any] = {}

    async def go():
        ws_a, _ = await _open_authed(mock_relay_server, project="A")
        ws_b, _ = await _open_authed(mock_relay_server, project="B")
        try:
            sess = await asyncio.to_thread(
                lambda: _http_get(mock_relay_server, "/__mock__/sessions").json()
            )
            sessions = sess["sessions"]
            target = sessions[1]["id"]  # session_b
            script = [
                {"expect_recv": {"method": "calling.answer", "session_id": target, "timeout_ms": 2000}},
            ]

            async def run_script_thread():
                script_holder["resp"] = await asyncio.to_thread(
                    lambda: _http_post(
                        mock_relay_server, "/__mock__/scenario_play", script
                    ).json()
                )

            t = asyncio.create_task(run_script_thread())
            await asyncio.sleep(0.1)

            # ws_a sends calling.answer first. Should NOT satisfy the script
            # because the script is filtered to session_b.
            await ws_a.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": str(uuid.uuid4()),
                        "method": "calling.answer",
                        "params": {"node_id": "n", "call_id": "ignored"},
                    }
                )
            )
            await asyncio.wait_for(ws_a.recv(), timeout=1)  # response

            # ws_b then sends calling.answer — should unblock the script.
            await ws_b.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": str(uuid.uuid4()),
                        "method": "calling.answer",
                        "params": {"node_id": "n", "call_id": "real"},
                    }
                )
            )
            await asyncio.wait_for(ws_b.recv(), timeout=1)  # response

            await asyncio.wait_for(t, timeout=3)
            return script_holder["resp"]
        finally:
            await ws_a.close()
            await ws_b.close()

    resp = asyncio.run(go())
    assert resp == {"status": "completed", "steps": 1}


def test_scenario_play_invalid_op_returns_400(
    mock_relay_server: MockRelayServer,
) -> None:
    r = _http_post(
        mock_relay_server,
        "/__mock__/scenario_play",
        [{"unknown": "op"}],
    )
    assert r.status_code == 400


def test_scenario_play_non_array_body_400(mock_relay_server: MockRelayServer) -> None:
    r = _http_post(mock_relay_server, "/__mock__/scenario_play", {"not": "array"})
    assert r.status_code == 400


# ---------------------------------------------------------------------------
# /__mock__/scenarios/_unconditional
# ---------------------------------------------------------------------------


def test_unconditional_scenario_pushes_immediately(
    mock_relay_server: MockRelayServer,
) -> None:
    """Mirror of /push but using the existing scenario JSON shape."""
    body = [
        {"emit": {"call_id": "u1", "call_state": "created"}, "event_type": "calling.call.state", "delay_ms": 0},
        {"emit": {"call_id": "u1", "call_state": "ringing"}, "event_type": "calling.call.state", "delay_ms": 0},
    ]

    async def go():
        ws, _ = await _open_authed(mock_relay_server)
        try:
            resp = await asyncio.to_thread(
                lambda: _http_post(
                    mock_relay_server,
                    "/__mock__/scenarios/_unconditional",
                    body,
                ).json()
            )
            evt1 = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            evt2 = json.loads(await asyncio.wait_for(ws.recv(), timeout=2))
            return resp, evt1, evt2
        finally:
            await ws.close()

    resp, evt1, evt2 = asyncio.run(go())
    assert resp["frames"] == 2
    assert resp["count"] == 1  # one connected session
    assert evt1["params"]["event_type"] == "calling.call.state"
    assert evt1["params"]["params"]["call_state"] == "created"
    assert evt2["params"]["params"]["call_state"] == "ringing"


def test_unconditional_scenario_does_not_consume_method_queue(
    mock_relay_server: MockRelayServer,
) -> None:
    """Posting to /scenarios/_unconditional must NOT push into the per-method
    scenario queue — that's the whole point of the special name."""
    body = [{"emit": {"foo": "bar"}, "event_type": "x.y"}]
    _http_post(mock_relay_server, "/__mock__/scenarios/_unconditional", body)
    # Per-method scenario list should remain empty.
    listing = _http_get(mock_relay_server, "/__mock__/scenarios").json()
    assert listing["methods"] == {}


# ---------------------------------------------------------------------------
# Concurrent multi-SDK sanity check
# ---------------------------------------------------------------------------


def test_pushes_to_one_session_do_not_leak_to_other(
    mock_relay_server: MockRelayServer,
) -> None:
    """Stress: connect 3 clients, push targeted to one of them N times. The
    other two must see 0 frames."""

    async def go():
        connections: list[tuple[Any, str]] = []
        try:
            for project in ("A", "B", "C"):
                ws, resp = await _open_authed(mock_relay_server, project=project)
                connections.append((ws, resp["result"]["protocol"]))

            sess = await asyncio.to_thread(
                lambda: _http_get(mock_relay_server, "/__mock__/sessions").json()
            )
            sessions = sess["sessions"]
            assert len(sessions) == 3
            target = sessions[0]["id"]

            # Push 5 frames in a row to the target.
            for i in range(5):
                await asyncio.to_thread(
                    lambda i=i: _http_post(
                        mock_relay_server,
                        "/__mock__/push",
                        {
                            "frame": _signalwire_event(
                                "calling.call.state",
                                {"call_id": f"p-{i}", "call_state": "created"},
                            )
                        },
                        session_id=target,
                    )
                )

            # Drain whatever each ws has queued, with a short timeout.
            counts: dict[int, int] = {}
            for idx, (ws, _) in enumerate(connections):
                got = 0
                while True:
                    try:
                        await asyncio.wait_for(ws.recv(), timeout=0.4)
                        got += 1
                    except asyncio.TimeoutError:
                        break
                counts[idx] = got
            return counts, target, [s["id"] for s in sessions]
        finally:
            for ws, _ in connections:
                await ws.close()

    counts, target, all_ids = asyncio.run(go())
    target_idx = all_ids.index(target)
    # The targeted session got all 5; the other two got 0.
    assert counts[target_idx] == 5, f"target should get 5, got {counts}"
    other_total = sum(c for i, c in counts.items() if i != target_idx)
    assert other_total == 0, f"non-target sessions leaked frames: {counts}"
