"""HTTP Basic Auth verification.

The real SignalWire API requires ``Authorization: Basic <base64(project:token)>``.
The mock accepts any non-empty project + non-empty token.
"""

from __future__ import annotations

import base64
from dataclasses import dataclass


@dataclass
class AuthResult:
    ok: bool
    project: str | None
    token: str | None
    reason: str | None


def parse_basic_auth(authorization_header: str | None) -> AuthResult:
    """Parse and validate an ``Authorization: Basic ...`` header.

    Returns ``ok=True`` only when the header is present, well-formed, and
    contains a non-empty project and non-empty token.
    """
    if not authorization_header:
        return AuthResult(False, None, None, "missing_authorization_header")
    if not authorization_header.lower().startswith("basic "):
        return AuthResult(False, None, None, "not_basic_auth")
    encoded = authorization_header.split(None, 1)[1].strip()
    try:
        decoded = base64.b64decode(encoded).decode("utf-8")
    except Exception:
        return AuthResult(False, None, None, "malformed_base64")
    if ":" not in decoded:
        return AuthResult(False, None, None, "missing_colon")
    project, _, token = decoded.partition(":")
    if not project or not token:
        return AuthResult(False, None, None, "empty_project_or_token")
    return AuthResult(True, project, token, None)
