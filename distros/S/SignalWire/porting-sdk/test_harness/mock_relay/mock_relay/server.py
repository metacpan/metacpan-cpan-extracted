"""Mock SignalWire RELAY WebSocket server.

The RELAY analogue of mock_signalwire's REST server. Speaks JSON-RPC 2.0
over WebSocket; loads the schemas under ``porting-sdk/relay-protocol/`` at
startup; provides an HTTP control plane on a sidecar port for tests.

Run with::

    mock-relay --ws-port 8773 --http-port 9773
    # or
    python -m mock_relay

Programmatic::

    from mock_relay import MockRelayServer
    srv = MockRelayServer().start()
    try:
        ...  # run tests
    finally:
        srv.stop()
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import socket
import threading
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

import uvicorn
import websockets
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse, Response
from starlette.routing import Route

from .auth import (
    AuthState,
    ConnectAuthResult,
    connect_result_payload,
    parse_connect_params,
    reauthenticate_result_payload,
    ERROR_AUTH_REQUIRED,
    ERROR_INVALID_PARAMS,
    ERROR_INTERNAL,
    ERROR_UNKNOWN_METHOD,
)
from .handlers import (
    jsonrpc_error,
    jsonrpc_response,
    make_signalwire_event_frame,
    synthesize_result,
    validate_params,
)
from .journal import Journal
from .scenarios import (
    DialLeg,
    DialScenario,
    MethodScenario,
    ScenarioStore,
    parse_dial_scenario,
    parse_method_scenario,
)
from .schemas import SchemaIndex, load_all


logger = logging.getLogger("mock_relay")


# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

DEFAULT_WS_PORT = int(os.environ.get("MOCK_RELAY_PORT", "8773"))
DEFAULT_HTTP_PORT = int(os.environ.get("MOCK_RELAY_HTTP_PORT", str(DEFAULT_WS_PORT + 1000)))
DEFAULT_HOST = os.environ.get("MOCK_RELAY_HOST", "127.0.0.1")


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------


@dataclass
class MockState:
    """Cross-thread mutable state; touched by both the WS server and HTTP server."""

    schemas: SchemaIndex
    journal: Journal = field(default_factory=lambda: Journal(max_entries=1000))
    auth: AuthState = field(default_factory=AuthState)
    scenarios: ScenarioStore = field(default_factory=ScenarioStore)
    sessions: "SessionRegistry" = field(default_factory=lambda: SessionRegistry())
    # Set by ``MockRelayServer.start`` so the HTTP control plane can schedule
    # sends on the WS event loop.
    ws_loop: asyncio.AbstractEventLoop | None = None


# ---------------------------------------------------------------------------
# Session registry — tracks live WebSocket connections so HTTP endpoints
# (``/__mock__/sessions``, ``/__mock__/push``, ...) can target them.
# ---------------------------------------------------------------------------


class SessionRegistry:
    """Thread-safe map of active sessions.

    Keys are server-issued session ids (UUID hex strings). Values are
    ``_Connection`` instances. The HTTP control plane reads through this
    registry to broadcast or target frames; the WS server inserts/removes
    entries on connect/disconnect.
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._by_id: dict[str, "_Connection"] = {}

    def register(self, conn: "_Connection") -> None:
        with self._lock:
            self._by_id[conn.session_id] = conn

    def unregister(self, session_id: str) -> None:
        with self._lock:
            self._by_id.pop(session_id, None)

    def get(self, session_id: str) -> "_Connection | None":
        with self._lock:
            return self._by_id.get(session_id)

    def all(self) -> list["_Connection"]:
        with self._lock:
            return list(self._by_id.values())

    def metadata(self) -> list[dict[str, Any]]:
        """Snapshot of connected sessions for HTTP exposure."""
        with self._lock:
            conns = list(self._by_id.values())
        return [c.session_metadata() for c in conns]

    def reset(self) -> None:
        """Forget every session (does not close their sockets)."""
        with self._lock:
            self._by_id.clear()


# ---------------------------------------------------------------------------
# WebSocket dispatch
# ---------------------------------------------------------------------------


class _Connection:
    """One client WebSocket. Owns the per-connection emit task pool."""

    def __init__(self, ws: websockets.WebSocketServerProtocol, state: MockState):
        self.ws = ws
        self.state = state
        self.session_id = uuid.uuid4().hex
        # Legacy ``id`` kept for backward compat with existing journal entries
        # and tests that reference ``conn-...``. Now derived from session_id.
        self.id = f"conn-{self.session_id[:12]}"
        self.connected_at = time.time()
        try:
            peer = ws.remote_address
            if peer:
                self.peer_addr = f"{peer[0]}:{peer[1]}"
            else:
                self.peer_addr = ""
        except Exception:
            self.peer_addr = ""
        # Filled in once ``signalwire.connect`` succeeds.
        self.protocol_string: str | None = None
        self._send_lock = asyncio.Lock()
        self._tasks: set[asyncio.Task] = set()

    def session_metadata(self) -> dict[str, Any]:
        """Snapshot describing this session for the HTTP control plane."""
        return {
            "id": self.session_id,
            "connection_id": self.id,
            "connected_at": self.connected_at,
            "peer_addr": self.peer_addr,
            "protocol_string": self.protocol_string,
        }

    async def send_json(self, payload: dict[str, Any]) -> None:
        """Send a JSON frame, journaling it as a 'send'."""
        async with self._send_lock:
            self.state.journal.record_send(
                self.id, payload, session_id=self.session_id
            )
            try:
                await self.ws.send(json.dumps(payload))
            except websockets.exceptions.ConnectionClosed:
                logger.debug("send aborted: connection closed (%s)", self.id)
                raise

    def schedule(self, coro) -> None:
        """Fire-and-forget a coroutine but track it so we can cancel on close."""
        task = asyncio.create_task(coro)
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)

    async def cancel_pending(self) -> None:
        for task in list(self._tasks):
            task.cancel()
        for task in list(self._tasks):
            try:
                await task
            except (asyncio.CancelledError, Exception):
                pass


async def _serve_connection(ws: websockets.WebSocketServerProtocol, state: MockState) -> None:
    """Top-level handler for a new client WebSocket."""
    conn = _Connection(ws, state)
    state.sessions.register(conn)
    logger.debug("WS connection %s opened from %s", conn.id, ws.remote_address)
    try:
        async for raw in ws:
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                logger.warning("dropped non-JSON frame from %s", conn.id)
                continue
            if not isinstance(msg, dict):
                continue
            state.journal.record_recv(conn.id, msg, session_id=conn.session_id)
            await _dispatch_frame(conn, msg)
    except websockets.exceptions.ConnectionClosed:
        pass
    except Exception:
        logger.exception("error in connection %s", conn.id)
    finally:
        state.sessions.unregister(conn.session_id)
        await conn.cancel_pending()
        logger.debug("WS connection %s closed", conn.id)


async def _dispatch_frame(conn: _Connection, msg: dict[str, Any]) -> None:
    """Route one inbound JSON-RPC frame to its handler."""
    # Responses to server-initiated frames (event ACKs, ping pongs) — just
    # ignore them silently; we only journaled them.
    if "method" not in msg:
        return

    method = msg.get("method")
    if not isinstance(method, str):
        return
    req_id = msg.get("id")
    params = msg.get("params") or {}

    if method == "signalwire.connect":
        await _handle_connect(conn, req_id, params)
        return
    if method == "signalwire.reauthenticate":
        await _handle_reauthenticate(conn, req_id, params)
        return
    if method == "signalwire.execute":
        await _handle_execute(conn, req_id, params)
        return
    if method == "signalwire.ping":
        await _handle_ping(conn, req_id)
        return
    if method == "signalwire.disconnect":
        await _handle_disconnect(conn, req_id)
        return
    if method in ("signalwire.receive", "signalwire.unreceive"):
        # These come on the protocol assigned by connect — the mock just
        # acknowledges them with a 200.
        await _send_simple_ok(conn, req_id, "OK")
        return

    # Flat-Blade legacy form: ``{"method": "calling.play", "params": {...}}``
    # without a ``signalwire.execute`` wrapper. Used by the Python SDK.
    # Treat any method starting with ``calling.`` or ``messaging.`` as an
    # implicit execute with the inner params being ``params`` itself.
    if method.startswith("calling.") or method.startswith("messaging."):
        synthetic = {
            "method": method,
            "params": params,
            # Preserve identity hints if the caller put them at the top level
            # (which the legacy form sometimes does).
            "requester_nodeid": params.get("requester_nodeid", "") if isinstance(params, dict) else "",
        }
        await _handle_execute(conn, req_id, synthetic)
        return

    if req_id is not None:
        await conn.send_json(
            jsonrpc_error(str(req_id), ERROR_UNKNOWN_METHOD, f"Unknown method {method!r}")
        )


async def _handle_connect(conn: _Connection, req_id: Any, params: Any) -> None:
    parsed = parse_connect_params(params)
    auth = conn.state.auth

    # Resume by previously-issued protocol — accepted regardless of
    # creds for this case.
    if parsed["protocol"]:
        result = auth.resume(parsed["protocol"])
        session_restored = result.ok
        if not result.ok:
            # Fall back to fresh auth, like the real server would.
            result = _fresh_auth(parsed, auth)
            session_restored = False
    else:
        result = _fresh_auth(parsed, auth)
        session_restored = False

    if req_id is None:
        return  # nothing to respond to (defensive)

    if not result.ok:
        await conn.send_json(
            jsonrpc_error(
                str(req_id),
                result.error_code or ERROR_AUTH_REQUIRED,
                result.error_message or "auth failed",
            )
        )
        return

    payload = connect_result_payload(result, parsed["contexts"], session_restored=session_restored)
    conn.protocol_string = result.protocol
    await conn.send_json(jsonrpc_response(str(req_id), payload))


def _fresh_auth(parsed: dict[str, Any], auth: AuthState) -> ConnectAuthResult:
    if parsed["jwt_token"]:
        return auth.issue_jwt(parsed["jwt_token"])
    return auth.issue(parsed["project"], parsed["token"], parsed["contexts"])


async def _handle_reauthenticate(conn: _Connection, req_id: Any, params: Any) -> None:
    """``signalwire.reauthenticate`` — the dpop variant of resume.

    The mock treats the ``authentication`` JObject as a creds bag: a
    ``project`` + ``token`` keys revalidate, anything else is treated as a
    JWT-shaped string we accept.
    """
    if not isinstance(params, dict):
        params = {}
    auth_block = params.get("authentication") or {}
    if not isinstance(auth_block, dict):
        auth_block = {}
    project = str(auth_block.get("project") or "")
    token = str(auth_block.get("token") or "")
    jwt_token = str(auth_block.get("jwt_token") or "")
    if project and token:
        result = conn.state.auth.issue(project, token, [])
    elif jwt_token:
        result = conn.state.auth.issue_jwt(jwt_token)
    else:
        result = ConnectAuthResult(
            ok=False,
            protocol=None,
            identity=None,
            error_code=ERROR_AUTH_REQUIRED,
            error_message="reauthenticate requires project+token or jwt_token",
        )

    if req_id is None:
        return
    if not result.ok:
        await conn.send_json(
            jsonrpc_error(
                str(req_id),
                result.error_code or ERROR_AUTH_REQUIRED,
                result.error_message or "auth failed",
            )
        )
        return
    conn.protocol_string = result.protocol
    payload = reauthenticate_result_payload(result)
    await conn.send_json(jsonrpc_response(str(req_id), payload))


async def _handle_execute(conn: _Connection, req_id: Any, params: Any) -> None:
    if not isinstance(params, dict):
        await conn.send_json(
            jsonrpc_error(
                str(req_id) if req_id is not None else "",
                ERROR_INVALID_PARAMS,
                "execute params must be an object",
            )
        )
        return
    method = params.get("method")
    inner = params.get("params") or {}
    if not isinstance(method, str) or not method:
        await conn.send_json(
            jsonrpc_error(
                str(req_id) if req_id is not None else "",
                ERROR_INVALID_PARAMS,
                "execute requires a 'method' field",
            )
        )
        return

    # Validate inner params against the loaded schema.
    ok, err = validate_params(method, inner, conn.state.schemas)
    if not ok:
        await conn.send_json(
            jsonrpc_error(
                str(req_id) if req_id is not None else "",
                ERROR_INVALID_PARAMS,
                err or "invalid params",
            )
        )
        return

    # Synthesize the result.
    inner_result = synthesize_result(method, inner, conn.state.schemas)

    # Wrap in ExecuteResult shape (the outer envelope expects
    # ``requester_nodeid`` + ``responder_nodeid`` + ``result``).
    requester = params.get("requester_nodeid") or params.get("requester_identity") or ""
    responder = params.get("responder_nodeid") or params.get("responder_identity") or ""
    execute_result = {
        "requester_nodeid": str(requester),
        "responder_nodeid": str(responder) or "mock-relay-node-1",
        "result": inner_result,
    }
    if req_id is None:
        return
    # SDKs differ on whether they read execute_result.result vs the bare
    # result. To make every SDK happy, we put inner_result at the TOP level
    # of the JSON-RPC `result` (so result.code / result.call_id are both at
    # the top), with the requester/responder fields siblings. This matches
    # the Python client's expectation that ``result`` is the inner dict.
    flat = dict(inner_result)
    flat.setdefault("requester_nodeid", execute_result["requester_nodeid"])
    flat.setdefault("responder_nodeid", execute_result["responder_nodeid"])
    await conn.send_json(jsonrpc_response(str(req_id), flat))

    # Schedule scripted post-RPC events.
    scenario = conn.state.scenarios.pop_method(method)
    if method == "calling.dial":
        # Dial gets special-cased; tag drives matching.
        tag = inner.get("tag") if isinstance(inner, dict) else None
        dial_scenario = conn.state.scenarios.pop_dial(tag if isinstance(tag, str) else None)
        if dial_scenario is not None:
            conn.schedule(_emit_dial_dance(conn, dial_scenario, fallback_tag=tag if isinstance(tag, str) else None))
    if scenario is not None:
        conn.schedule(_emit_method_scenario(conn, method, scenario, inner))


async def _handle_ping(conn: _Connection, req_id: Any) -> None:
    if req_id is None:
        return
    await conn.send_json(
        {
            "jsonrpc": "2.0",
            "id": str(req_id),
            "result": {"timestamp": time.time()},
        }
    )


async def _handle_disconnect(conn: _Connection, req_id: Any) -> None:
    if req_id is not None:
        await conn.send_json({"jsonrpc": "2.0", "id": str(req_id), "result": {}})
    await conn.ws.close()


async def _send_simple_ok(conn: _Connection, req_id: Any, message: str) -> None:
    if req_id is None:
        return
    await conn.send_json(
        jsonrpc_response(str(req_id), {"code": "200", "message": message})
    )


# ---------------------------------------------------------------------------
# Scripted event emission
# ---------------------------------------------------------------------------


async def _emit_method_scenario(
    conn: _Connection,
    method: str,
    scenario: MethodScenario,
    request_params: dict[str, Any],
) -> None:
    """Emit each scripted event after a delay."""
    for sevent in scenario.events:
        try:
            await asyncio.sleep(max(0.0, sevent.delay_ms / 1000.0))
            event_type = sevent.event_type or _default_event_type_for(method)
            inner = dict(sevent.payload)
            # Inject correlation hints from the request if not set.
            if "call_id" not in inner and isinstance(request_params.get("call_id"), str):
                inner["call_id"] = request_params["call_id"]
            if "control_id" not in inner and isinstance(request_params.get("control_id"), str):
                inner["control_id"] = request_params["control_id"]
            frame = make_signalwire_event_frame(event_type, inner)
            await conn.send_json(frame)
        except websockets.exceptions.ConnectionClosed:
            return
        except asyncio.CancelledError:
            return


def _default_event_type_for(method: str) -> str:
    """Pick a default event_type for a method scenario.

    Lookups follow the same convention as the production server:
    ``calling.<verb>`` → ``calling.call.<verb>`` (since events for verbs
    like ``play``, ``record`` are reported under ``calling.call.<verb>``).
    """
    if method.startswith("calling.") and method != "calling.dial":
        # Strip ``calling.`` prefix, take the leading verb up to the first dot.
        rest = method[len("calling.") :]
        head = rest.split(".", 1)[0]
        return f"calling.call.{head}"
    if method.startswith("messaging."):
        return method  # messaging.send → messaging.state, messaging.receive → messaging.receive
    return method


async def _emit_dial_dance(
    conn: _Connection,
    scenario: DialScenario,
    fallback_tag: str | None,
) -> None:
    """Emit per-leg ``calling.call.state`` events then ``calling.call.dial``."""
    tag = scenario.tag or fallback_tag or ""

    try:
        # Winner's state events.
        for state in scenario.states:
            await asyncio.sleep(scenario.delay_ms / 1000.0)
            inner = {
                "call_id": scenario.winner_call_id,
                "node_id": scenario.node_id,
                "tag": tag,
                "call_state": state,
                "direction": "outbound",
                "device": scenario.device or {},
            }
            await conn.send_json(make_signalwire_event_frame("calling.call.state", inner))

        # Losers — each gets its own state events ending in "ended".
        for leg in scenario.losers:
            for state in leg.states:
                await asyncio.sleep(leg.delay_ms / 1000.0)
                inner = {
                    "call_id": leg.call_id,
                    "node_id": scenario.node_id,
                    "tag": tag,
                    "call_state": state,
                    "direction": "outbound",
                    "device": leg.device or {},
                }
                await conn.send_json(make_signalwire_event_frame("calling.call.state", inner))

        # Final calling.call.dial event with the winner.
        await asyncio.sleep(scenario.delay_ms / 1000.0)
        dial_inner = {
            "tag": tag,
            "node_id": scenario.node_id,
            "dial_state": "answered",
            "call": {
                "call_id": scenario.winner_call_id,
                "node_id": scenario.node_id,
                "tag": tag,
                "device": scenario.device or {},
                "dial_winner": True,
            },
        }
        await conn.send_json(make_signalwire_event_frame("calling.call.dial", dial_inner))
    except websockets.exceptions.ConnectionClosed:
        return
    except asyncio.CancelledError:
        return


# ---------------------------------------------------------------------------
# Cross-thread push helpers
# ---------------------------------------------------------------------------


async def _send_to_conn_async(conn: _Connection, frame: dict[str, Any]) -> bool:
    """Send a frame to a connection, swallowing closed-socket errors.

    Runs on the WS event loop. Returns True if the send actually went out.
    """
    try:
        await conn.send_json(frame)
        return True
    except websockets.exceptions.ConnectionClosed:
        return False
    except Exception:
        logger.exception("failed to push frame to %s", conn.id)
        return False


def _schedule_send(state: MockState, conn: _Connection, frame: dict[str, Any]) -> bool:
    """Schedule ``conn.send_json(frame)`` on the WS event loop and wait briefly.

    Called from the HTTP thread. Blocks until the send either completes,
    fails, or 2s elapses (in which case we assume the queue is wedged and
    return False).
    """
    loop = state.ws_loop
    if loop is None:
        return False
    fut = asyncio.run_coroutine_threadsafe(_send_to_conn_async(conn, frame), loop)
    try:
        return bool(fut.result(timeout=2.0))
    except Exception:
        return False


def _broadcast_frame(state: MockState, frame: dict[str, Any]) -> list[str]:
    """Push ``frame`` to every active session. Returns list of session ids
    that actually received it."""
    delivered: list[str] = []
    for conn in state.sessions.all():
        if _schedule_send(state, conn, frame):
            delivered.append(conn.session_id)
    return delivered


# ---------------------------------------------------------------------------
# HTTP control plane
# ---------------------------------------------------------------------------


def build_http_app(state: MockState, ws_port: int) -> Starlette:
    """The Starlette app that exposes ``/__mock__/*`` endpoints."""

    async def health(request: Request) -> Response:
        return JSONResponse(
            {
                "status": "ok",
                "ws_port": ws_port,
                "schemas_loaded": state.schemas.total,
                "schemas_by_source": state.schemas.by_source(),
                "schema_load_errors": state.schemas.load_errors,
                "journal_entries": len(state.journal),
            }
        )

    async def journal_get(request: Request) -> Response:
        return JSONResponse([e.as_dict() for e in state.journal.all()])

    async def journal_reset(request: Request) -> Response:
        state.journal.reset()
        return JSONResponse({"status": "ok"})

    async def specs_list(request: Request) -> Response:
        return JSONResponse(
            {
                "total": state.schemas.total,
                "specs": state.schemas.list_specs(),
            }
        )

    async def scenarios_list(request: Request) -> Response:
        return JSONResponse(state.scenarios.list_active())

    async def scenarios_reset(request: Request) -> Response:
        state.scenarios.reset()
        return JSONResponse({"status": "ok"})

    async def scenario_dial(request: Request) -> Response:
        try:
            body = await request.json()
        except Exception:
            return JSONResponse({"error": "invalid_json"}, status_code=400)
        try:
            scenario = parse_dial_scenario(body)
        except ValueError as exc:
            return JSONResponse({"error": str(exc)}, status_code=400)
        state.scenarios.push_dial(scenario)
        return JSONResponse({"status": "ok", "tag": scenario.tag})

    async def sessions_list(request: Request) -> Response:
        return JSONResponse({"sessions": state.sessions.metadata()})

    async def push(request: Request) -> Response:
        """Broadcast or target a frame to active sessions.

        Body: ``{"frame": {...full JSON-RPC frame...}}``.
        Optional query string ``?session_id=<id>`` targets a single session.
        """
        try:
            body = await request.json()
        except Exception:
            return JSONResponse({"error": "invalid_json"}, status_code=400)
        if not isinstance(body, dict):
            return JSONResponse({"error": "body must be an object"}, status_code=400)
        frame = body.get("frame")
        if not isinstance(frame, dict):
            return JSONResponse(
                {"error": "missing or non-object 'frame' field"}, status_code=400
            )

        target = request.query_params.get("session_id") or body.get("session_id")
        if target:
            conn = state.sessions.get(str(target))
            if conn is None:
                return JSONResponse(
                    {"sent_to": [], "count": 0, "error": "no such session"},
                    status_code=404,
                )
            ok = _schedule_send(state, conn, frame)
            if not ok:
                return JSONResponse(
                    {"sent_to": [], "count": 0, "error": "send failed"},
                    status_code=502,
                )
            return JSONResponse({"sent_to": [str(target)], "count": 1})

        delivered = _broadcast_frame(state, frame)
        return JSONResponse({"sent_to": delivered, "count": len(delivered)})

    async def inbound_call(request: Request) -> Response:
        """Convenience helper that emits a vanilla inbound-call sequence.

        Body shape::

            {
                "session_id": "<optional>",
                "call_id": "<uuid>",
                "from_number": "+15551234567",
                "to_number": "+15559876543",
                "context": "default",
                "auto_states": ["created", "ringing"],
                "delay_ms": 50
            }
        """
        try:
            body = await request.json()
        except Exception:
            return JSONResponse({"error": "invalid_json"}, status_code=400)
        if not isinstance(body, dict):
            return JSONResponse({"error": "body must be an object"}, status_code=400)

        call_id = str(body.get("call_id") or f"inbound-{uuid.uuid4().hex[:12]}")
        from_number = str(body.get("from_number") or "")
        to_number = str(body.get("to_number") or "")
        context = str(body.get("context") or "default")
        states_raw = body.get("auto_states") or ["created"]
        if not isinstance(states_raw, list):
            return JSONResponse(
                {"error": "auto_states must be an array of strings"}, status_code=400
            )
        states = [str(s) for s in states_raw]
        delay_ms = int(body.get("delay_ms", 50))

        target = request.query_params.get("session_id") or body.get("session_id")
        if target:
            target_str = str(target)
            conn = state.sessions.get(target_str)
            if conn is None:
                return JSONResponse(
                    {"sent_to": [], "count": 0, "error": "no such session"},
                    status_code=404,
                )
            target_conns = [conn]
        else:
            target_conns = state.sessions.all()
            target_str = None

        def _build_inner(state_label: str) -> dict[str, Any]:
            return {
                "call_id": call_id,
                "node_id": "mock-relay-node-1",
                "tag": "",
                "call_state": state_label,
                "direction": "inbound",
                "device": {
                    "type": "phone",
                    "params": {
                        "from_number": from_number,
                        "to_number": to_number,
                    },
                },
                "context": context,
            }

        # First state announces the inbound call via ``calling.call.receive``
        # (the production wire shape — see ``events.md`` and the Python SDK's
        # ``EVENT_CALL_RECEIVE`` dispatch). Subsequent states are
        # ``calling.call.state`` updates routed to the existing Call.
        delivered: set[str] = set()
        for i, state_label in enumerate(states):
            if i > 0 and delay_ms > 0:
                # We are on the HTTP thread; block briefly so frames look paced
                # on the wire.
                time.sleep(delay_ms / 1000.0)
            event_type = "calling.call.receive" if i == 0 else "calling.call.state"
            frame = make_signalwire_event_frame(event_type, _build_inner(state_label))
            for conn in target_conns:
                if _schedule_send(state, conn, frame):
                    delivered.add(conn.session_id)

        return JSONResponse(
            {
                "sent_to": sorted(delivered),
                "count": len(delivered),
                "call_id": call_id,
                "states_emitted": states,
            }
        )

    async def scenario_play(request: Request) -> Response:
        """Run a scripted timeline of pushes, sleeps, and expect_recv waits.

        Body: array of ops:
        - ``{"sleep_ms": <int>}``
        - ``{"push": {"frame": {...}, "session_id": "<optional>"}}``
        - ``{"expect_recv": {"method": "<name>", "timeout_ms": <int>, "session_id": "<optional>"}}``

        Returns ``{"status": "completed", "steps": N}`` or
        ``{"status": "timeout", "at_step": N, ...}`` on expect_recv timeout.
        """
        try:
            body = await request.json()
        except Exception:
            return JSONResponse({"error": "invalid_json"}, status_code=400)
        if not isinstance(body, list):
            return JSONResponse(
                {"error": "scenario body must be an array of operations"},
                status_code=400,
            )

        steps_executed = 0
        for idx, op in enumerate(body):
            if not isinstance(op, dict):
                return JSONResponse(
                    {"error": f"step {idx} must be an object"}, status_code=400
                )

            if "sleep_ms" in op:
                try:
                    delay = float(op["sleep_ms"]) / 1000.0
                except (TypeError, ValueError):
                    return JSONResponse(
                        {"error": f"step {idx}: sleep_ms must be a number"},
                        status_code=400,
                    )
                if delay > 0:
                    await asyncio.sleep(delay)
                steps_executed += 1
                continue

            if "push" in op:
                push_spec = op["push"]
                if not isinstance(push_spec, dict):
                    return JSONResponse(
                        {"error": f"step {idx}: push must be an object"},
                        status_code=400,
                    )
                frame = push_spec.get("frame")
                if not isinstance(frame, dict):
                    return JSONResponse(
                        {"error": f"step {idx}: push needs a 'frame' object"},
                        status_code=400,
                    )
                session_id = push_spec.get("session_id")
                if session_id:
                    conn = state.sessions.get(str(session_id))
                    if conn is None:
                        return JSONResponse(
                            {
                                "status": "error",
                                "at_step": idx,
                                "error": f"no such session: {session_id}",
                            },
                            status_code=404,
                        )
                    _schedule_send(state, conn, frame)
                else:
                    _broadcast_frame(state, frame)
                steps_executed += 1
                continue

            if "expect_recv" in op:
                spec = op["expect_recv"]
                if not isinstance(spec, dict):
                    return JSONResponse(
                        {"error": f"step {idx}: expect_recv must be an object"},
                        status_code=400,
                    )
                want_method = spec.get("method")
                if not isinstance(want_method, str) or not want_method:
                    return JSONResponse(
                        {
                            "error": f"step {idx}: expect_recv requires a non-empty 'method'"
                        },
                        status_code=400,
                    )
                timeout_s = float(spec.get("timeout_ms", 5000)) / 1000.0
                want_session_id = spec.get("session_id")
                # Snapshot the journal length so we only consider frames
                # received AFTER this step was reached.
                start_len = len(state.journal)
                deadline = time.monotonic() + max(0.0, timeout_s)
                matched = None
                while time.monotonic() < deadline:
                    entries = state.journal.all()
                    for entry in entries[start_len:]:
                        if entry.direction != "recv":
                            continue
                        if entry.method != want_method:
                            continue
                        if want_session_id:
                            target_conn = state.sessions.get(str(want_session_id))
                            if target_conn and entry.connection_id != target_conn.id:
                                continue
                        matched = entry
                        break
                    if matched is not None:
                        break
                    await asyncio.sleep(0.01)
                if matched is None:
                    return JSONResponse(
                        {
                            "status": "timeout",
                            "at_step": idx,
                            "expected_method": want_method,
                            "steps_completed": steps_executed,
                        }
                    )
                steps_executed += 1
                continue

            return JSONResponse(
                {
                    "error": (
                        f"step {idx}: unknown operation; expected one of "
                        "'sleep_ms' | 'push' | 'expect_recv'"
                    )
                },
                status_code=400,
            )

        return JSONResponse({"status": "completed", "steps": steps_executed})

    async def scenario_unconditional(request: Request) -> Response:
        """Push a list of frames immediately to every connected session.

        Body shape (mirrors method scenario shape so tests using scenarios
        for both directions look uniform)::

            [{"emit": {<inner event params>}, "event_type": "<...>", "delay_ms": 0}, ...]

        Each frame is wrapped as a ``signalwire.event`` and broadcast.
        """
        try:
            body = await request.json()
        except Exception:
            return JSONResponse({"error": "invalid_json"}, status_code=400)
        try:
            scenario = parse_method_scenario(body)
        except ValueError as exc:
            return JSONResponse({"error": str(exc)}, status_code=400)

        target = request.query_params.get("session_id")
        if target:
            target_conn = state.sessions.get(str(target))
            if target_conn is None:
                return JSONResponse(
                    {"sent_to": [], "count": 0, "error": "no such session"},
                    status_code=404,
                )
            target_conns = [target_conn]
        else:
            target_conns = state.sessions.all()

        delivered: set[str] = set()
        for sevent in scenario.events:
            if sevent.delay_ms > 0:
                time.sleep(sevent.delay_ms / 1000.0)
            event_type = sevent.event_type or "signalwire.event"
            frame = make_signalwire_event_frame(event_type, dict(sevent.payload))
            for conn in target_conns:
                if _schedule_send(state, conn, frame):
                    delivered.add(conn.session_id)
        return JSONResponse(
            {
                "sent_to": sorted(delivered),
                "count": len(delivered),
                "frames": len(scenario.events),
            }
        )

    async def scenario_method(request: Request) -> Response:
        method = request.path_params.get("method", "")
        if not method:
            return JSONResponse({"error": "missing method"}, status_code=400)
        # Special-case: the underscore-prefixed sentinel is the unconditional
        # scenario endpoint, NOT a real RELAY method. Route it before falling
        # into the generic per-method branch so a stray "_unconditional"
        # doesn't get queued under that name.
        if method == "_unconditional":
            return await scenario_unconditional(request)
        try:
            body = await request.json()
        except Exception:
            return JSONResponse({"error": "invalid_json"}, status_code=400)
        try:
            scenario = parse_method_scenario(body)
        except ValueError as exc:
            return JSONResponse({"error": str(exc)}, status_code=400)
        state.scenarios.push_method(method, scenario)
        return JSONResponse({"status": "ok", "method": method, "events_queued": len(scenario.events)})

    routes = [
        Route("/__mock__/health", health),
        Route("/__mock__/journal", journal_get),
        Route("/__mock__/journal/reset", journal_reset, methods=["POST"]),
        Route("/__mock__/specs", specs_list),
        Route("/__mock__/sessions", sessions_list),
        Route("/__mock__/push", push, methods=["POST"]),
        Route("/__mock__/inbound_call", inbound_call, methods=["POST"]),
        Route("/__mock__/scenario_play", scenario_play, methods=["POST"]),
        Route("/__mock__/scenarios", scenarios_list),
        Route("/__mock__/scenarios/reset", scenarios_reset, methods=["POST"]),
        Route("/__mock__/scenarios/dial", scenario_dial, methods=["POST"]),
        Route(
            "/__mock__/scenarios/_unconditional",
            scenario_unconditional,
            methods=["POST"],
        ),
        Route("/__mock__/scenarios/{method:path}", scenario_method, methods=["POST"]),
    ]
    app = Starlette(routes=routes)
    app.state.mock_state = state
    return app


# ---------------------------------------------------------------------------
# MockRelayServer harness
# ---------------------------------------------------------------------------


class MockRelayServer:
    """Run the WebSocket + HTTP control plane in background threads.

    Usage::

        srv = MockRelayServer().start()
        try:
            ...
        finally:
            srv.stop()
    """

    def __init__(
        self,
        host: str = DEFAULT_HOST,
        ws_port: int | None = None,
        http_port: int | None = None,
        schema_root: Path | str | None = None,
        log_level: str = "warning",
    ) -> None:
        self.host = host
        self.ws_port = ws_port if ws_port is not None else DEFAULT_WS_PORT
        self.http_port = http_port if http_port is not None else DEFAULT_HTTP_PORT
        self.log_level = log_level
        self._schema_root = schema_root
        self._state: MockState | None = None
        self._ws_loop: asyncio.AbstractEventLoop | None = None
        self._ws_thread: threading.Thread | None = None
        self._ws_server: websockets.WebSocketServer | None = None
        self._ws_server_ready = threading.Event()
        self._http_server: uvicorn.Server | None = None
        self._http_thread: threading.Thread | None = None
        self._app: Starlette | None = None

    @property
    def state(self) -> MockState:
        assert self._state is not None
        return self._state

    @property
    def app(self) -> Starlette:
        assert self._app is not None
        return self._app

    @property
    def ws_url(self) -> str:
        return f"ws://{self.host}:{self.ws_port}"

    @property
    def http_url(self) -> str:
        return f"http://{self.host}:{self.http_port}"

    @property
    def relay_host(self) -> str:
        """Host:port of the WS endpoint, for SDK ``host=`` parameter use."""
        return f"{self.host}:{self.ws_port}"

    def start(self, ready_timeout: float = 10.0) -> "MockRelayServer":
        # 1. Load schemas synchronously.
        schemas = load_all(self._schema_root)
        self._state = MockState(schemas=schemas)
        self._app = build_http_app(self._state, self.ws_port)

        # 2. Start the WS server on its own thread/event loop.
        self._ws_thread = threading.Thread(
            target=self._run_ws,
            name=f"mock-relay-ws-{self.ws_port}",
            daemon=True,
        )
        self._ws_thread.start()
        if not self._ws_server_ready.wait(timeout=ready_timeout):
            raise RuntimeError(f"mock-relay WS failed to start on {self.host}:{self.ws_port}")

        # 3. Start the HTTP control plane.
        config = uvicorn.Config(
            self._app,
            host=self.host,
            port=self.http_port,
            log_level=self.log_level,
            access_log=False,
            lifespan="off",
        )
        self._http_server = uvicorn.Server(config)
        self._http_thread = threading.Thread(
            target=self._http_server.run,
            name=f"mock-relay-http-{self.http_port}",
            daemon=True,
        )
        self._http_thread.start()
        deadline = time.time() + ready_timeout
        while time.time() < deadline:
            if self._http_server.started:
                return self
            time.sleep(0.05)
        raise RuntimeError(f"mock-relay HTTP failed to start on {self.host}:{self.http_port}")

    def stop(self, timeout: float = 5.0) -> None:
        if self._ws_loop and self._ws_server is not None:
            try:
                self._ws_loop.call_soon_threadsafe(self._ws_loop.stop)
            except Exception:
                pass
        if self._ws_thread is not None:
            self._ws_thread.join(timeout=timeout)
            self._ws_thread = None
        if self._http_server is not None:
            self._http_server.should_exit = True
        if self._http_thread is not None:
            self._http_thread.join(timeout=timeout)
            self._http_thread = None

    # ----- internal --------------------------------------------------------

    def _run_ws(self) -> None:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        self._ws_loop = loop
        # Expose the loop to the HTTP control plane so it can schedule
        # ``send_json`` calls on it from the HTTP thread.
        if self._state is not None:
            self._state.ws_loop = loop
        try:
            loop.run_until_complete(self._start_ws_server())
            loop.run_forever()
        finally:
            try:
                if self._ws_server is not None:
                    self._ws_server.close()
                    loop.run_until_complete(self._ws_server.wait_closed())
            except Exception:
                pass
            loop.close()

    async def _start_ws_server(self) -> None:
        async def handler(ws):
            await _serve_connection(ws, self.state)

        self._ws_server = await websockets.serve(
            handler,
            self.host,
            self.ws_port,
            max_size=10 * 1024 * 1024,
            ping_interval=None,
        )
        self._ws_server_ready.set()


def create_server(
    host: str | None = None,
    ws_port: int | None = None,
    http_port: int | None = None,
) -> MockRelayServer:
    return MockRelayServer(
        host=host or DEFAULT_HOST,
        ws_port=ws_port if ws_port is not None else DEFAULT_WS_PORT,
        http_port=http_port if http_port is not None else DEFAULT_HTTP_PORT,
    )
