"""Per-method result synthesis.

Given a method name + params + the loaded result schema, produce a
plausible response dict that the Python (or any port) SDK will accept.
The synthesizer is deterministic — the same inputs always produce the same
output — so tests can assert on specific values.

Two pieces:

1. ``validate_params(method, params, schemas)`` — runs the loaded JSON
   Schema for ``<method>.params`` against the given payload. Returns
   ``(ok, error_message)``.

2. ``synthesize_result(method, params, schemas)`` — returns the dict to put
   in the ``result`` field of the JSON-RPC response. Calling-API responses
   are mostly ``{"code": "200", "message": "..."}`` plus echoed
   ``call_id``/``control_id``.
"""

from __future__ import annotations

import logging
import uuid
from typing import Any

import jsonschema

from .schemas import LoadedSchema, SchemaIndex


logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Param validation
# ---------------------------------------------------------------------------


def validate_params(
    method: str,
    params: Any,
    schemas: SchemaIndex,
) -> tuple[bool, str | None]:
    """Validate the ``params`` of an execute against the cached schema.

    Returns ``(ok, error_message)``. Permissive (mod_infrastructure)
    schemas always pass.
    """
    s = schemas.get(method, "params")
    if s is None or s.permissive:
        return True, None
    try:
        validator = jsonschema.Draft202012Validator(s.schema)
        errors = sorted(validator.iter_errors(params), key=lambda e: list(e.absolute_path))
        if errors:
            err = errors[0]
            return False, f"params validation: {err.message} at /{'/'.join(str(x) for x in err.absolute_path)}"
        return True, None
    except Exception:  # pragma: no cover - safety
        logger.exception("schema validation crashed for %s", method)
        return True, None  # don't fail closed


# ---------------------------------------------------------------------------
# Result synthesis
# ---------------------------------------------------------------------------


# Most calling methods return a constant message. Mirrors the table in
# RELAY_IMPLEMENTATION_GUIDE.md ("Simple fire-and-response").
_DEFAULT_MESSAGES: dict[str, str] = {
    "calling.answer": "Answered",
    "calling.end": "Disconnecting call",
    "calling.pass": "Passing call",
    "calling.connect": "connecting",
    "calling.disconnect": "Disconnecting",
    "calling.hold": "Call on hold",
    "calling.unhold": "Call off hold",
    "calling.denoise": "Denoiser on",
    "calling.denoise.stop": "Denoiser off",
    "calling.transfer": "Transferring",
    "calling.join_conference": "Joining conference",
    "calling.leave_conference": "Leaving conference",
    "calling.echo": "Echo started",
    "calling.bind_digit": "Digit binding created",
    "calling.clear_digit_bindings": "Digit bindings cleared",
    "calling.live_transcribe": "Live transcription started",
    "calling.live_translate": "Live translation started",
    "calling.join_room": "Joining room",
    "calling.leave_room": "Leaving room",
    "calling.amazon_bedrock": "AI started",
    "calling.ai": "AI started",
    "calling.ai.stop": "AI stopped",
    "calling.ai_message": "Message sent",
    "calling.ai_hold": "AI on hold",
    "calling.ai_unhold": "AI resumed",
    "calling.user_event": "Event sent",
    "calling.queue.enter": "Entering Queue",
    "calling.queue.leave": "Leaving Queue",
    "calling.refer": "Starting SIP REFER",
    "calling.send_digits": "Sending Digits",
    "calling.dial": "Dialing",
    "calling.begin": "Call started",
    "calling.receive": "Receiving events",
    "calling.play": "Playing",
    "calling.play.stop": "Stopping",
    "calling.play.pause": "Paused",
    "calling.play.resume": "Resumed",
    "calling.play.volume": "Volume set",
    "calling.record": "Recording",
    "calling.record.stop": "Stopped recording",
    "calling.record.pause": "Recording paused",
    "calling.record.resume": "Recording resumed",
    "calling.detect": "Detect started",
    "calling.detect.stop": "Detect stopped",
    "calling.collect": "Collecting",
    "calling.collect.stop": "Collect stopped",
    "calling.collect.start_input_timers": "Started input timers",
    "calling.play_and_collect": "Playing and collecting",
    "calling.play_and_collect.stop": "Stopping play and collect",
    "calling.play_and_collect.volume": "Volume set",
    "calling.pay": "Pay started",
    "calling.pay.stop": "Pay stopped",
    "calling.send_fax": "Sending fax",
    "calling.send_fax.stop": "Fax send stopped",
    "calling.receive_fax": "Receiving fax",
    "calling.receive_fax.stop": "Fax receive stopped",
    "calling.tap": "Tap started",
    "calling.tap.stop": "Tap stopped",
    "calling.stream": "Stream started",
    "calling.stream.stop": "Stream stopped",
    "calling.transcribe": "Transcribe started",
    "calling.transcribe.stop": "Transcribe stopped",
}


def synthesize_result(
    method: str,
    params: Any,
    schemas: SchemaIndex,
) -> dict[str, Any]:
    """Build a plausible JSON-RPC ``result`` dict for the given method.

    For calling.* methods the result has ``code: "200"``, a default
    message, and any echoed identifiers (``call_id``, ``control_id``,
    ``message_id``) the schema requires.

    For unknown methods (no schema), we still return ``{"code": "200",
    "message": "OK"}``.
    """
    p = params if isinstance(params, dict) else {}

    # Special: messaging.send returns a fresh message_id.
    if method == "messaging.send":
        return {
            "code": "200",
            "message": "Message accepted",
            "message_id": str(uuid.uuid4()),
        }

    # Calling methods: standard envelope + echoed identifiers.
    if method.startswith("calling."):
        result: dict[str, Any] = {
            "code": "200",
            "message": _DEFAULT_MESSAGES.get(method, "OK"),
        }
        if method == "calling.dial":
            # No call_id in the response — that's the whole point of dial.
            return result
        if method == "calling.begin":
            # begin DOES include call_id and node_id (deprecated).
            result["call_id"] = str(uuid.uuid4())
            result["node_id"] = "mock-relay-node-1"
            return result

        # Echo node_id/call_id/control_id when the params carry them — most
        # calling-method responses re-emit them so the SDK can correlate.
        for key in ("call_id", "control_id"):
            if isinstance(p.get(key), str) and p[key]:
                result[key] = p[key]
        return result

    # Default permissive shape.
    return {"code": "200", "message": "OK"}


# ---------------------------------------------------------------------------
# Synthesizing the wire envelope (signalwire.event payloads)
# ---------------------------------------------------------------------------


def make_signalwire_event_frame(
    event_type: str,
    inner_params: dict[str, Any],
    msg_id: str | None = None,
) -> dict[str, Any]:
    """Wrap an inner event-params dict in a full ``signalwire.event`` frame."""
    return {
        "jsonrpc": "2.0",
        "id": msg_id or str(uuid.uuid4()),
        "method": "signalwire.event",
        "params": {
            "event_type": event_type,
            "params": inner_params,
        },
    }


def jsonrpc_response(req_id: str, result: dict[str, Any]) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": req_id, "result": result}


def jsonrpc_error(req_id: str, code: str, message: str) -> dict[str, Any]:
    """Return a JSON-RPC level error frame.

    RELAY uses string codes like ``AUTH_REQUIRED`` (mirroring switchblade's
    ``ResponseErrorCode``), but JSON-RPC 2.0 wants integer error codes.
    We emit an integer code (mapped from the string) plus the original code
    in ``data`` so SDKs that look there can recover it.
    """
    code_int_map = {
        "AUTH_REQUIRED": -32401,
        "INVALID_PARAMS": -32602,
        "UNKNOWN_METHOD": -32601,
        "INTERNAL_ERROR": -32603,
        "VERSION_INCOMPATIBLE": -32498,
    }
    int_code = code_int_map.get(code, -32603)
    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {
            "code": int_code,
            "message": message,
            "data": {"signalwire_error_code": code},
        },
    }
