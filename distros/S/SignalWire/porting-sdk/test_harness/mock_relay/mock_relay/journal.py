"""In-memory frame journal — bounded ring buffer.

Records every WebSocket frame, both inbound (recv) and outbound (send), for
the lifetime of one mock-relay process. Tests inspect it via the HTTP
control plane (``GET /__mock__/journal``) and reset it via
``POST /__mock__/journal/reset``.
"""

from __future__ import annotations

import threading
import time
from collections import deque
from dataclasses import asdict, dataclass
from typing import Any


@dataclass
class FrameEntry:
    """One JSON frame either received from or sent to a client."""

    timestamp: float
    direction: str  # "recv" | "send"
    method: str | None  # JSON-RPC method (or None for responses)
    request_id: str | None  # JSON-RPC id (or None for events without correlation)
    frame: dict[str, Any]
    connection_id: str
    # ``session_id`` is the server-issued UUID (no ``conn-`` prefix). Tests
    # filter the journal by it when multiple SDKs are connected concurrently.
    # Optional for backward-compat with callers that still pass only a
    # connection_id.
    session_id: str | None = None

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


class Journal:
    """Thread-safe ring buffer of journal entries."""

    def __init__(self, max_entries: int = 1000) -> None:
        self._max = max_entries
        self._lock = threading.Lock()
        self._buf: deque[FrameEntry] = deque(maxlen=max_entries)

    def record_recv(
        self,
        connection_id: str,
        frame: dict[str, Any],
        session_id: str | None = None,
    ) -> FrameEntry:
        return self._record(connection_id, "recv", frame, session_id=session_id)

    def record_send(
        self,
        connection_id: str,
        frame: dict[str, Any],
        session_id: str | None = None,
    ) -> FrameEntry:
        return self._record(connection_id, "send", frame, session_id=session_id)

    def _record(
        self,
        connection_id: str,
        direction: str,
        frame: dict[str, Any],
        session_id: str | None = None,
    ) -> FrameEntry:
        method = None
        request_id = None
        if isinstance(frame, dict):
            m = frame.get("method")
            if isinstance(m, str):
                method = m
            rid = frame.get("id")
            if isinstance(rid, (str, int, float)):
                request_id = str(rid)
        entry = FrameEntry(
            timestamp=time.time(),
            direction=direction,
            method=method,
            request_id=request_id,
            frame=frame,
            connection_id=connection_id,
            session_id=session_id,
        )
        with self._lock:
            self._buf.append(entry)
        return entry

    def all(self) -> list[FrameEntry]:
        with self._lock:
            return list(self._buf)

    def reset(self) -> None:
        with self._lock:
            self._buf.clear()

    def last_received(self, method: str | None = None) -> FrameEntry | None:
        """Return the most recent inbound frame (optionally matching ``method``)."""
        with self._lock:
            for entry in reversed(self._buf):
                if entry.direction != "recv":
                    continue
                if method is None or entry.method == method:
                    return entry
        return None

    def sent_during(self, method: str) -> list[FrameEntry]:
        """Return all outbound frames recorded after the most recent recv of *method*.

        Useful for asserting "after ``calling.play`` was called, the mock
        emitted these scripted events".
        """
        with self._lock:
            entries = list(self._buf)
        # Find last recv of method.
        anchor = None
        for i in range(len(entries) - 1, -1, -1):
            if entries[i].direction == "recv" and entries[i].method == method:
                anchor = i
                break
        if anchor is None:
            return []
        return [e for e in entries[anchor + 1 :] if e.direction == "send"]

    def __len__(self) -> int:
        with self._lock:
            return len(self._buf)
