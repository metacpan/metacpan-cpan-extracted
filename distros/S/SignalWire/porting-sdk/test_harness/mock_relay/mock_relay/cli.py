"""``mock-relay`` console-script entry point."""

from __future__ import annotations

import argparse
import logging
import os
import signal
import sys
import time
from pathlib import Path

from .server import (
    DEFAULT_HOST,
    DEFAULT_HTTP_PORT,
    DEFAULT_WS_PORT,
    MockRelayServer,
)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="mock-relay",
        description="Mock SignalWire RELAY WebSocket server (test harness for SDK ports).",
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("MOCK_RELAY_HOST", DEFAULT_HOST),
        help=f"bind host (default: {DEFAULT_HOST}, env MOCK_RELAY_HOST)",
    )
    parser.add_argument(
        "--ws-port",
        type=int,
        default=int(os.environ.get("MOCK_RELAY_PORT", DEFAULT_WS_PORT)),
        help=f"WebSocket port (default: {DEFAULT_WS_PORT}, env MOCK_RELAY_PORT)",
    )
    parser.add_argument(
        "--http-port",
        type=int,
        default=int(os.environ.get("MOCK_RELAY_HTTP_PORT", DEFAULT_HTTP_PORT)),
        help=f"HTTP control-plane port (default: {DEFAULT_HTTP_PORT}, env MOCK_RELAY_HTTP_PORT)",
    )
    parser.add_argument(
        "--schema-root",
        type=Path,
        default=None,
        help="override directory containing the relay JSON schemas (default: porting-sdk/relay-protocol/)",
    )
    parser.add_argument(
        "--log-level",
        default=os.environ.get("MOCK_RELAY_LOG_LEVEL", "info"),
        help="log level (default: info)",
    )
    args = parser.parse_args(argv)

    logging.basicConfig(level=args.log_level.upper())

    server = MockRelayServer(
        host=args.host,
        ws_port=args.ws_port,
        http_port=args.http_port,
        schema_root=args.schema_root,
        log_level=args.log_level,
    ).start()

    state = server.state
    sys.stderr.write(
        f"mock-relay: {state.schemas.total} schemas loaded "
        f"(by source: {state.schemas.by_source()}); "
        f"WS at ws://{server.host}:{server.ws_port}, "
        f"HTTP at http://{server.host}:{server.http_port}\n"
    )
    if state.schemas.load_errors:
        sys.stderr.write(f"  schema load errors: {state.schemas.load_errors}\n")

    stop_event = False

    def _shutdown(signum, frame):  # pragma: no cover
        nonlocal stop_event
        stop_event = True

    signal.signal(signal.SIGINT, _shutdown)
    signal.signal(signal.SIGTERM, _shutdown)
    try:
        while not stop_event:
            time.sleep(0.5)
    finally:
        server.stop()
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
