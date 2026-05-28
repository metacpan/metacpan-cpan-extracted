"""Per-endpoint response overrides.

Tests can register a response override for a given ``endpoint_id``:

    POST /__mock__/scenarios/<endpoint_id>
    body: {"status": 500, "response": {"errors": [...]}}

The next request matching that endpoint consumes the override and reverts
to the default synthesized response. Multiple overrides queued on the
same endpoint are consumed FIFO. We chose consume-once semantics so tests
don't need to remember to reset between assertions; they can stage one
scenario per call.
"""

from __future__ import annotations

import threading
from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Any


@dataclass
class Scenario:
    status: int
    response: Any
    headers: dict[str, str] | None = None


class ScenarioStore:
    """FIFO queue of overrides per endpoint_id."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._queues: dict[str, deque[Scenario]] = defaultdict(deque)

    def push(self, endpoint_id: str, scenario: Scenario) -> None:
        with self._lock:
            self._queues[endpoint_id].append(scenario)

    def pop(self, endpoint_id: str) -> Scenario | None:
        with self._lock:
            q = self._queues.get(endpoint_id)
            if not q:
                return None
            scenario = q.popleft()
            if not q:
                self._queues.pop(endpoint_id, None)
            return scenario

    def list_active(self) -> dict[str, list[dict[str, Any]]]:
        with self._lock:
            return {
                eid: [
                    {"status": s.status, "response": s.response, "headers": s.headers}
                    for s in q
                ]
                for eid, q in self._queues.items()
            }

    def reset(self) -> None:
        with self._lock:
            self._queues.clear()
