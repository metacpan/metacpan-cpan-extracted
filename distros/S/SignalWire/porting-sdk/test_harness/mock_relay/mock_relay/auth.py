"""``signalwire.connect`` / ``signalwire.reauthenticate`` handler.

The real RELAY server validates project/token via Blade auth + redirects to
the assigned signalling node. The mock just checks for the *presence* of
project + token (or a JWT) and issues a fresh protocol string. The protocol
string is journaled so reconnect-with-resume tests can verify the round-trip.
"""

from __future__ import annotations

import threading
import uuid
from dataclasses import dataclass
from typing import Any


@dataclass
class ConnectAuthResult:
    """Outcome of a ``signalwire.connect`` auth attempt."""

    ok: bool
    protocol: str | None
    identity: str | None
    error_code: str | None
    error_message: str | None


# Public RELAY error codes the mock returns. These mirror the ones the real
# server raises (see switchblade ResponseErrorCode).
ERROR_AUTH_REQUIRED = "AUTH_REQUIRED"
ERROR_INVALID_PARAMS = "INVALID_PARAMS"
ERROR_UNKNOWN_METHOD = "UNKNOWN_METHOD"
ERROR_INTERNAL = "INTERNAL_ERROR"


class AuthState:
    """Tracks issued protocol strings + their owning project for resume.

    A fresh ``signalwire.connect`` issues a new protocol string. A
    ``signalwire.reauthenticate`` (or a ``connect`` carrying a prior
    ``protocol``) checks that the string was issued by us. If so, the
    session is "restored" and the same protocol is returned. If not, the
    mock returns AUTH_REQUIRED.
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._protocols: dict[str, dict[str, Any]] = {}

    def issue(
        self,
        project: str,
        token: str,
        contexts: list[str] | None,
    ) -> ConnectAuthResult:
        """Validate creds and mint a fresh protocol string."""
        if not project:
            return ConnectAuthResult(
                ok=False,
                protocol=None,
                identity=None,
                error_code=ERROR_AUTH_REQUIRED,
                error_message="project missing",
            )
        if not token:
            return ConnectAuthResult(
                ok=False,
                protocol=None,
                identity=None,
                error_code=ERROR_AUTH_REQUIRED,
                error_message="token missing",
            )
        protocol = f"signalwire_{uuid.uuid4().hex}"
        identity = f"mock-relay-identity-{project}"
        with self._lock:
            self._protocols[protocol] = {
                "project": project,
                "token": token,
                "contexts": list(contexts or []),
                "identity": identity,
            }
        return ConnectAuthResult(
            ok=True,
            protocol=protocol,
            identity=identity,
            error_code=None,
            error_message=None,
        )

    def issue_jwt(self, jwt_token: str) -> ConnectAuthResult:
        """Accept a JWT (any non-empty string) as auth."""
        if not jwt_token:
            return ConnectAuthResult(
                ok=False,
                protocol=None,
                identity=None,
                error_code=ERROR_AUTH_REQUIRED,
                error_message="jwt_token empty",
            )
        protocol = f"signalwire_{uuid.uuid4().hex}"
        identity = "mock-relay-identity-jwt"
        with self._lock:
            self._protocols[protocol] = {
                "project": "",
                "token": jwt_token,
                "contexts": [],
                "identity": identity,
                "via_jwt": True,
            }
        return ConnectAuthResult(
            ok=True,
            protocol=protocol,
            identity=identity,
            error_code=None,
            error_message=None,
        )

    def resume(self, protocol: str) -> ConnectAuthResult:
        """Replay an existing protocol string. AUTH_REQUIRED if unknown."""
        with self._lock:
            owner = self._protocols.get(protocol)
        if not owner:
            return ConnectAuthResult(
                ok=False,
                protocol=None,
                identity=None,
                error_code=ERROR_AUTH_REQUIRED,
                error_message=f"protocol {protocol!r} not issued by this server",
            )
        return ConnectAuthResult(
            ok=True,
            protocol=protocol,
            identity=owner["identity"],
            error_code=None,
            error_message=None,
        )

    def known_protocol(self, protocol: str) -> bool:
        with self._lock:
            return protocol in self._protocols

    def reset(self) -> None:
        with self._lock:
            self._protocols.clear()


def parse_connect_params(params: Any) -> dict[str, Any]:
    """Pull the bits we care about from a ``signalwire.connect`` params object.

    Returns a dict with keys:
        project, token, jwt_token, contexts, protocol (resume), authorization_state
    Empty strings/lists/None when absent. Doesn't raise.
    """
    if not isinstance(params, dict):
        return {
            "project": "",
            "token": "",
            "jwt_token": "",
            "contexts": [],
            "protocol": "",
            "authorization_state": "",
        }
    auth = params.get("authentication") or {}
    if not isinstance(auth, dict):
        auth = {}
    contexts = params.get("contexts") or []
    if not isinstance(contexts, list):
        contexts = []
    return {
        "project": str(auth.get("project") or ""),
        "token": str(auth.get("token") or ""),
        "jwt_token": str(auth.get("jwt_token") or ""),
        "contexts": [str(c) for c in contexts],
        "protocol": str(params.get("protocol") or ""),
        "authorization_state": str(params.get("authorization_state") or ""),
    }


def connect_result_payload(
    auth: ConnectAuthResult,
    contexts: list[str],
    session_restored: bool = False,
) -> dict[str, Any]:
    """Build a ConnectResult-shaped success payload.

    Mirrors switchblade's ConnectResult: at minimum we need ``protocol``,
    ``identity``, ``sessionid``, ``nodeid``, ``master_nodeid`` and the
    ``protocols`` list (so SDKs that introspect available methods don't
    blow up).
    """
    assert auth.ok and auth.protocol is not None  # caller guards this
    sess_id = f"sess-{uuid.uuid4().hex}"
    node_id = "mock-relay-node-1"
    return {
        "session_restored": session_restored,
        "sessionid": sess_id,
        "nodeid": node_id,
        "identity": auth.identity or "",
        "master_nodeid": node_id,
        "protocol": auth.protocol,
        "protocols": [],
        "subscriptions": [
            {
                "protocol": auth.protocol,
                "channel": ctx,
                "subscribers": [node_id],
            }
            for ctx in contexts
        ],
        "ice_servers": [],
    }


def reauthenticate_result_payload(auth: ConnectAuthResult) -> dict[str, Any]:
    return {
        "authentication": auth.identity or "",
        "authorization": {},
    }
