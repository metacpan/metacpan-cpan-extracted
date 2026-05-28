"""In-memory request journal — bounded ring buffer.

Records every request in the order it was received. Tests read it via
``GET /__mock__/journal`` and reset it via ``POST /__mock__/journal/reset``.
"""

from __future__ import annotations

import threading
import time
from collections import deque
from dataclasses import asdict, dataclass, field
from typing import Any, Iterable


@dataclass
class JournalEntry:
    timestamp: float
    method: str
    path: str
    query_params: dict[str, list[str]]
    headers: dict[str, str]
    body: Any
    matched_route: str | None = None
    response_status: int | None = None

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


class Journal:
    """Thread-safe ring buffer of journal entries."""

    def __init__(self, max_entries: int = 1000) -> None:
        self._max = max_entries
        self._lock = threading.Lock()
        self._buf: deque[JournalEntry] = deque(maxlen=max_entries)

    def record(
        self,
        method: str,
        path: str,
        query_params: dict[str, list[str]],
        headers: dict[str, str],
        body: Any,
        matched_route: str | None,
        response_status: int | None,
    ) -> JournalEntry:
        entry = JournalEntry(
            timestamp=time.time(),
            method=method,
            path=path,
            query_params=query_params,
            headers=headers,
            body=body,
            matched_route=matched_route,
            response_status=response_status,
        )
        with self._lock:
            self._buf.append(entry)
        return entry

    def all(self) -> list[JournalEntry]:
        with self._lock:
            return list(self._buf)

    def reset(self) -> None:
        with self._lock:
            self._buf.clear()

    def __len__(self) -> int:
        with self._lock:
            return len(self._buf)
