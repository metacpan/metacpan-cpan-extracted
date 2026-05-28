"""Console-script entry point for ``mock-signalwire``."""

from __future__ import annotations

import argparse
import logging
import os
import signal
import sys
from pathlib import Path

import uvicorn

from .server import DEFAULT_HOST, DEFAULT_PORT, build_app


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="mock-signalwire",
        description="Mock SignalWire REST API server (test harness for SDK ports).",
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("MOCK_SIGNALWIRE_HOST", DEFAULT_HOST),
        help=f"bind host (default: {DEFAULT_HOST}, env MOCK_SIGNALWIRE_HOST)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("MOCK_SIGNALWIRE_PORT", DEFAULT_PORT)),
        help=f"bind port (default: {DEFAULT_PORT}, env MOCK_SIGNALWIRE_PORT)",
    )
    parser.add_argument(
        "--spec-root",
        type=Path,
        default=None,
        help="override directory containing the OpenAPI specs (default: porting-sdk/rest-apis)",
    )
    parser.add_argument(
        "--log-level",
        default=os.environ.get("MOCK_SIGNALWIRE_LOG_LEVEL", "info"),
        help="uvicorn log level (default: info)",
    )
    args = parser.parse_args(argv)

    logging.basicConfig(level=args.log_level.upper())

    app = build_app(args.spec_root)
    n_routes = sum(len(v) for v in app.state.mock_state.routes_by_method.values())
    sys.stderr.write(
        f"mock-signalwire: {app.state.mock_state.specs_loaded}/13 specs loaded, "
        f"{n_routes} routes registered, listening on {args.host}:{args.port}\n"
    )

    config = uvicorn.Config(
        app,
        host=args.host,
        port=args.port,
        log_level=args.log_level,
        access_log=False,
    )
    server = uvicorn.Server(config)

    def _shutdown(signum, frame):  # pragma: no cover - signal-only
        server.should_exit = True

    signal.signal(signal.SIGINT, _shutdown)
    signal.signal(signal.SIGTERM, _shutdown)

    server.run()
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
