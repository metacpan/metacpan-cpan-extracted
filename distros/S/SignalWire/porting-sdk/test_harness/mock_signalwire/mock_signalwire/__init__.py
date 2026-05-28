"""Mock SignalWire REST API server.

A schema-driven HTTP server that loads SignalWire's 13 OpenAPI specs and
synthesizes responses from them. Used as the shared test backend for
every language port of the SignalWire SDK.
"""

from .server import build_app, create_server, MockServer
from .specs import SpecLoader, RouteEntry
from .synthesize import synthesize_response

__all__ = [
    "build_app",
    "create_server",
    "MockServer",
    "SpecLoader",
    "RouteEntry",
    "synthesize_response",
]

__version__ = "0.1.0"
