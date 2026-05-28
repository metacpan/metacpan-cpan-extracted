"""Mock SignalWire RELAY WebSocket server.

A schema-driven mock RELAY server. Loads the JSON schemas under
``porting-sdk/relay-protocol/`` (extracted from switchblade C# Params/Result
classes via ``scripts/extract_relay_schemas.py``) and synthesizes responses
from them. Same role for RELAY as ``mock_signalwire`` plays for REST.
"""

from .server import (
    MockRelayServer,
    MockState,
    SessionRegistry,
    build_http_app,
    create_server,
    DEFAULT_HOST,
    DEFAULT_WS_PORT,
    DEFAULT_HTTP_PORT,
)
from .schemas import LoadedSchema, SchemaIndex, load_all
from .scenarios import (
    DialLeg,
    DialScenario,
    MethodScenario,
    ScenarioStore,
    ScriptedEvent,
)
from .journal import FrameEntry, Journal


__all__ = [
    "MockRelayServer",
    "MockState",
    "SessionRegistry",
    "build_http_app",
    "create_server",
    "DEFAULT_HOST",
    "DEFAULT_WS_PORT",
    "DEFAULT_HTTP_PORT",
    "LoadedSchema",
    "SchemaIndex",
    "load_all",
    "DialLeg",
    "DialScenario",
    "MethodScenario",
    "ScenarioStore",
    "ScriptedEvent",
    "FrameEntry",
    "Journal",
]


__version__ = "0.1.0"
