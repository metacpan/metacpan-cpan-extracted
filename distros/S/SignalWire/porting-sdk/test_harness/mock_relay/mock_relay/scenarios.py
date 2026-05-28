"""Per-test scripted event sequences.

A test arms the mock with a list of post-RPC events for a specific method.
The next ``signalwire.execute`` of that method consumes the queue: after
sending the JSON-RPC response, the mock emits each scripted event with a
short sleep between (default 10ms) so they look real on the wire.

Two storage layouts:

* **Method scenarios** — keyed by RELAY method name (e.g. ``calling.play``).
  Body: ``[{"emit": <event_payload>, "delay_ms": 10?}, ...]``.

* **Dial scenarios** — special-cased because dial is the only method whose
  response carries no call_id. Body:
  ``{"tag": ..., "winner_call_id": ..., "states": [...]}``.

A "dial scenario" is consumed by the next ``calling.dial`` whose params'
``tag`` matches. After the response, the mock emits the listed
``calling.call.state`` events (one per state with the same tag and a fresh
call_id), then a single ``calling.call.dial`` event with
``dial_state="answered"`` and the winner.
"""

from __future__ import annotations

import threading
from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Any


@dataclass
class ScriptedEvent:
    """One scripted event to emit after a method's RPC response."""

    payload: dict[str, Any]  # the inner ``params`` of signalwire.event
    event_type: str | None = None  # if set, override payload["event_type"]
    delay_ms: int = 10  # sleep before sending


@dataclass
class MethodScenario:
    """Scripted events to emit after ONE call to a given method."""

    events: list[ScriptedEvent] = field(default_factory=list)


@dataclass
class DialLeg:
    call_id: str
    states: list[str]  # e.g. ["created", "ringing", "answered"]
    device: dict[str, Any] | None = None
    delay_ms: int = 10


@dataclass
class DialScenario:
    """Scripted dial dance: per-leg state events, then the dial event."""

    tag: str
    winner_call_id: str
    states: list[str]  # states for the winner leg
    losers: list[DialLeg] = field(default_factory=list)
    node_id: str = "node-mock-1"
    device: dict[str, Any] | None = None
    delay_ms: int = 10


class ScenarioStore:
    """Thread-safe queue of scenarios.

    Method scenarios are FIFO per method; pop one off the front for each call.
    Dial scenarios are FIFO matched by ``tag`` (or first-available if no tag
    matches).
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._method_q: dict[str, deque[MethodScenario]] = defaultdict(deque)
        self._dial_q: deque[DialScenario] = deque()
        self._dial_by_tag: dict[str, deque[DialScenario]] = defaultdict(deque)

    # -- method scenarios --------------------------------------------------

    def push_method(self, method: str, scenario: MethodScenario) -> None:
        with self._lock:
            self._method_q[method].append(scenario)

    def pop_method(self, method: str) -> MethodScenario | None:
        with self._lock:
            q = self._method_q.get(method)
            if not q:
                return None
            scenario = q.popleft()
            if not q:
                self._method_q.pop(method, None)
            return scenario

    # -- dial scenarios ----------------------------------------------------

    def push_dial(self, scenario: DialScenario) -> None:
        with self._lock:
            self._dial_q.append(scenario)
            if scenario.tag:
                self._dial_by_tag[scenario.tag].append(scenario)

    def pop_dial(self, tag: str | None) -> DialScenario | None:
        """Match by tag if provided, else FIFO global."""
        with self._lock:
            if tag:
                tagged = self._dial_by_tag.get(tag)
                if tagged:
                    scenario = tagged.popleft()
                    if not tagged:
                        self._dial_by_tag.pop(tag, None)
                    # Also remove from main queue.
                    try:
                        self._dial_q.remove(scenario)
                    except ValueError:
                        pass
                    return scenario
            if self._dial_q:
                scenario = self._dial_q.popleft()
                if scenario.tag and self._dial_by_tag.get(scenario.tag):
                    try:
                        self._dial_by_tag[scenario.tag].remove(scenario)
                    except ValueError:
                        pass
                    if not self._dial_by_tag[scenario.tag]:
                        self._dial_by_tag.pop(scenario.tag, None)
                return scenario
        return None

    # -- bulk ops ----------------------------------------------------------

    def reset(self) -> None:
        with self._lock:
            self._method_q.clear()
            self._dial_q.clear()
            self._dial_by_tag.clear()

    def list_active(self) -> dict[str, Any]:
        with self._lock:
            return {
                "methods": {
                    m: [
                        {
                            "events": [
                                {
                                    "payload": e.payload,
                                    "event_type": e.event_type,
                                    "delay_ms": e.delay_ms,
                                }
                                for e in s.events
                            ]
                        }
                        for s in q
                    ]
                    for m, q in self._method_q.items()
                },
                "dial": [
                    {
                        "tag": s.tag,
                        "winner_call_id": s.winner_call_id,
                        "states": s.states,
                        "losers": [
                            {"call_id": l.call_id, "states": l.states}
                            for l in s.losers
                        ],
                    }
                    for s in self._dial_q
                ],
            }


# ---------------------------------------------------------------------------
# JSON helpers — convert HTTP control-plane bodies into typed scenarios.
# ---------------------------------------------------------------------------


def parse_method_scenario(body: Any) -> MethodScenario:
    """Convert HTTP body into MethodScenario.

    Body shape:
        [{"emit": {...event params...}, "event_type": "...", "delay_ms": 10}, ...]
    """
    if not isinstance(body, list):
        raise ValueError("method scenario body must be a JSON array")
    events: list[ScriptedEvent] = []
    for item in body:
        if not isinstance(item, dict):
            raise ValueError("each scenario item must be an object")
        emit = item.get("emit")
        if not isinstance(emit, dict):
            raise ValueError("each scenario item needs an 'emit' object")
        events.append(
            ScriptedEvent(
                payload=emit,
                event_type=item.get("event_type"),
                delay_ms=int(item.get("delay_ms", 10)),
            )
        )
    return MethodScenario(events=events)


def parse_dial_scenario(body: Any) -> DialScenario:
    """Convert HTTP body into DialScenario.

    Body shape::

        {
            "tag": "...",
            "winner_call_id": "...",
            "states": ["created", "ringing", "answered"],
            "node_id": "...",
            "device": {"type": "phone", "params": {...}},
            "losers": [{"call_id": "...", "states": [...]}, ...],
            "delay_ms": 10
        }
    """
    if not isinstance(body, dict):
        raise ValueError("dial scenario body must be an object")
    tag = body.get("tag")
    if not isinstance(tag, str) or not tag:
        raise ValueError("dial scenario requires a non-empty 'tag' string")
    winner = body.get("winner_call_id")
    if not isinstance(winner, str) or not winner:
        raise ValueError("dial scenario requires 'winner_call_id'")
    states = body.get("states")
    if not isinstance(states, list):
        states = ["created", "ringing", "answered"]
    losers_raw = body.get("losers") or []
    losers: list[DialLeg] = []
    for l in losers_raw:
        if not isinstance(l, dict):
            continue
        losers.append(
            DialLeg(
                call_id=str(l.get("call_id", "")),
                states=list(l.get("states", ["created", "ended"])),
                device=l.get("device"),
                delay_ms=int(l.get("delay_ms", 10)),
            )
        )
    return DialScenario(
        tag=tag,
        winner_call_id=winner,
        states=states,
        losers=losers,
        node_id=str(body.get("node_id", "node-mock-1")),
        device=body.get("device"),
        delay_ms=int(body.get("delay_ms", 10)),
    )
