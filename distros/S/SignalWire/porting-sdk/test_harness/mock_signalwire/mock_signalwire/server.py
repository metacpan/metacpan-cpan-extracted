"""Mock SignalWire HTTP server.

A Starlette ASGI app that:

1. Loads the 13 OpenAPI specs at startup and builds a route table.
2. Dispatches incoming requests to the longest matching route, preferring
   strict (no path-param) matches over templated ones.
3. Synthesizes a schema-conformant JSON body for each route, or applies a
   pre-staged scenario override.
4. Records every request in an in-memory journal.
5. Exposes a control plane at ``/__mock__/*`` for tests.

This is *not* a production HTTP server: there is no rate limiting, no TLS,
no real auth check. The only "validation" is that the basic-auth header
parses and contains non-empty fields.
"""

from __future__ import annotations

import json
import logging
import os
import threading
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs

import uvicorn
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse, Response
from starlette.routing import Route

from .auth import parse_basic_auth
from .journal import Journal
from .scenarios import Scenario, ScenarioStore
from .specs import RouteEntry, SpecLoader
from .synthesize import synthesize_response


logger = logging.getLogger(__name__)


# -- Default port & host configuration -------------------------------------------------

DEFAULT_PORT = int(os.environ.get("MOCK_SIGNALWIRE_PORT", "8765"))
DEFAULT_HOST = os.environ.get("MOCK_SIGNALWIRE_HOST", "127.0.0.1")


# -- Internal state container ----------------------------------------------------------


@dataclass
class _State:
    routes_by_method: dict[str, list[RouteEntry]]
    journal: Journal
    scenarios: ScenarioStore
    spec_load_errors: list[dict[str, Any]]
    specs_loaded: int

    def find_route(self, method: str, path: str) -> tuple[RouteEntry | None, dict[str, str]]:
        """Return (route, captured_path_params).

        Strict (no path-param) matches are tried first, then templated ones in
        descending specificity (longer template = more specific).
        """
        candidates = self.routes_by_method.get(method.upper(), [])
        # Normalize trailing slash.
        norm = path.rstrip("/") if path != "/" else path

        # 1. Try strict matches first (templates with no `{...}`).
        for route in candidates:
            if "{" in route.path_template:
                continue
            tpl = route.path_template.rstrip("/") if route.path_template != "/" else route.path_template
            if tpl == norm:
                return route, {}

        # 2. Templated matches; rank by number of literal segments (more = better).
        templated = [r for r in candidates if "{" in r.path_template]
        templated_sorted = sorted(
            templated,
            key=lambda r: (-len(r.path_template), -_literal_segment_count(r.path_template)),
        )
        for route in templated_sorted:
            params = route.match(norm) or route.match(path)
            if params is not None:
                return route, params

        return None, {}


def _literal_segment_count(template: str) -> int:
    return sum(1 for seg in template.split("/") if seg and not seg.startswith("{"))


# -- App factory -----------------------------------------------------------------------


def build_app(spec_root: Path | str | None = None) -> Starlette:
    """Build and return the ASGI app.

    All routing is done by ``_dispatch`` because Starlette's regex routing
    isn't expressive enough for OpenAPI templates; we want to pull the
    template from the loaded spec, not duplicate it.
    """
    loader = SpecLoader(spec_root)
    result = loader.load_all()

    routes_by_method: dict[str, list[RouteEntry]] = {}
    for r in result.routes:
        routes_by_method.setdefault(r.method, []).append(r)

    state = _State(
        routes_by_method=routes_by_method,
        journal=Journal(max_entries=1000),
        scenarios=ScenarioStore(),
        spec_load_errors=[
            {"spec": e.spec_name, "error": e.error} for e in result.errors
        ],
        specs_loaded=result.specs_loaded,
    )

    routes = [
        Route("/__mock__/health", _make_health_handler(state)),
        Route("/__mock__/journal", _make_journal_get_handler(state)),
        Route("/__mock__/journal/reset", _make_journal_reset_handler(state), methods=["POST"]),
        Route("/__mock__/scenarios", _make_scenarios_list_handler(state)),
        Route("/__mock__/scenarios/reset", _make_scenarios_reset_handler(state), methods=["POST"]),
        Route("/__mock__/scenarios/{endpoint_id:path}", _make_scenario_push_handler(state), methods=["POST"]),
        # Catch-all for everything else; must be last.
        Route("/{full_path:path}", _make_dispatch_handler(state), methods=["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]),
    ]
    app = Starlette(routes=routes)
    app.state.mock_state = state  # exposed for tests
    return app


# -- Control-plane handlers ------------------------------------------------------------


def _make_health_handler(state: _State):
    async def handler(request: Request) -> Response:
        return JSONResponse(
            {
                "status": "ok",
                "specs_loaded": state.specs_loaded,
                "spec_load_errors": state.spec_load_errors,
                "total_routes": sum(len(v) for v in state.routes_by_method.values()),
            }
        )
    return handler


def _make_journal_get_handler(state: _State):
    async def handler(request: Request) -> Response:
        return JSONResponse([e.as_dict() for e in state.journal.all()])
    return handler


def _make_journal_reset_handler(state: _State):
    async def handler(request: Request) -> Response:
        state.journal.reset()
        return JSONResponse({"status": "ok"})
    return handler


def _make_scenarios_list_handler(state: _State):
    async def handler(request: Request) -> Response:
        return JSONResponse(state.scenarios.list_active())
    return handler


def _make_scenarios_reset_handler(state: _State):
    async def handler(request: Request) -> Response:
        state.scenarios.reset()
        return JSONResponse({"status": "ok"})
    return handler


def _make_scenario_push_handler(state: _State):
    async def handler(request: Request) -> Response:
        endpoint_id = request.path_params["endpoint_id"]
        try:
            payload = await request.json()
        except Exception:
            return JSONResponse({"error": "invalid_json"}, status_code=400)
        if not isinstance(payload, dict):
            return JSONResponse({"error": "body_must_be_object"}, status_code=400)
        scenario = Scenario(
            status=int(payload.get("status", 200)),
            response=payload.get("response"),
            headers=payload.get("headers"),
        )
        state.scenarios.push(endpoint_id, scenario)
        return JSONResponse({"status": "ok", "endpoint_id": endpoint_id})
    return handler


# -- Main dispatch handler -------------------------------------------------------------


def _make_dispatch_handler(state: _State):
    async def handler(request: Request) -> Response:
        path = "/" + request.path_params.get("full_path", "")
        method = request.method.upper()

        # Auth check first: every real-API endpoint requires it.
        auth_header = request.headers.get("authorization")
        auth = parse_basic_auth(auth_header)

        # Read body / params for journal.
        query_params = {k: list(v) for k, v in parse_qs(request.url.query).items()}
        headers = {k: v for k, v in request.headers.items()}
        body: Any
        try:
            raw = await request.body()
            if raw:
                ctype = request.headers.get("content-type", "").lower()
                if "application/json" in ctype:
                    try:
                        body = json.loads(raw)
                    except Exception:
                        body = raw.decode("utf-8", errors="replace")
                elif "application/x-www-form-urlencoded" in ctype:
                    body = {k: v[0] if len(v) == 1 else v for k, v in parse_qs(raw.decode("utf-8")).items()}
                else:
                    try:
                        body = raw.decode("utf-8")
                    except Exception:
                        body = "<binary>"
            else:
                body = None
        except Exception:
            body = None

        # Reject missing/malformed auth.
        if not auth.ok:
            return _journal_and_respond(
                state, method, path, query_params, headers, body, None,
                401, {"errors": [{"code": "AUTH_REQUIRED", "message": auth.reason or "auth required"}]},
            )

        # Find route.
        route, path_params = state.find_route(method, path)
        if route is None:
            return _journal_and_respond(
                state, method, path, query_params, headers, body, None,
                404, {"errors": [{"code": "NOT_FOUND", "message": f"no route for {method} {path}"}]},
            )

        # Apply scenario override if one is queued.
        scenario = state.scenarios.pop(route.endpoint_id)
        if scenario is not None:
            extra_headers: dict[str, str] = {}
            if scenario.headers:
                extra_headers.update(scenario.headers)
            return _journal_and_respond(
                state, method, path, query_params, headers, body, route.endpoint_id,
                scenario.status, scenario.response, extra_headers=extra_headers,
            )

        # Synthesize from spec.
        try:
            status, response_body = synthesize_response(route.operation, route.schemas, path_params)
        except Exception:
            logger.exception("synthesis failed for %s", route.endpoint_id)
            return _journal_and_respond(
                state, method, path, query_params, headers, body, route.endpoint_id,
                500, {"errors": [{"code": "SYNTHESIS_FAILED", "message": "schema synthesis crashed"}]},
            )

        extra_headers: dict[str, str] = {}
        if status == 201 and isinstance(response_body, dict):
            sid = response_body.get("sid") or response_body.get("id")
            if isinstance(sid, str):
                extra_headers["Location"] = f"{path.rstrip('/')}/{sid}"

        return _journal_and_respond(
            state, method, path, query_params, headers, body, route.endpoint_id,
            status, response_body, extra_headers=extra_headers,
        )

    return handler


def _journal_and_respond(
    state: _State,
    method: str,
    path: str,
    query_params: dict[str, list[str]],
    headers: dict[str, str],
    body: Any,
    matched_route: str | None,
    status: int,
    response_body: Any,
    extra_headers: dict[str, str] | None = None,
) -> Response:
    state.journal.record(
        method=method,
        path=path,
        query_params=query_params,
        headers=headers,
        body=body,
        matched_route=matched_route,
        response_status=status,
    )
    if response_body is None and status == 204:
        resp = Response(status_code=204)
    else:
        resp = JSONResponse(response_body if response_body is not None else {}, status_code=status)
    if extra_headers:
        for k, v in extra_headers.items():
            resp.headers[k] = v
    return resp


# -- Programmatic server harness -------------------------------------------------------


class MockServer:
    """Helper to start the mock server in a background thread for tests.

    Usage::

        srv = MockServer().start()
        try:
            requests.get(srv.url + "/__mock__/health", auth=("p", "t"))
        finally:
            srv.stop()
    """

    def __init__(
        self,
        host: str = DEFAULT_HOST,
        port: int = DEFAULT_PORT,
        spec_root: Path | str | None = None,
        log_level: str = "warning",
    ) -> None:
        self.host = host
        self.port = port
        self.spec_root = spec_root
        self.log_level = log_level
        self._app = build_app(spec_root)
        self._server: uvicorn.Server | None = None
        self._thread: threading.Thread | None = None

    @property
    def url(self) -> str:
        return f"http://{self.host}:{self.port}"

    @property
    def app(self) -> Starlette:
        return self._app

    def start(self, ready_timeout: float = 10.0) -> "MockServer":
        config = uvicorn.Config(
            self._app,
            host=self.host,
            port=self.port,
            log_level=self.log_level,
            access_log=False,
            lifespan="off",
        )
        self._server = uvicorn.Server(config)
        self._thread = threading.Thread(
            target=self._server.run, name=f"mock-signalwire-{self.port}", daemon=True,
        )
        self._thread.start()
        # Wait until uvicorn marks itself started.
        deadline = time.time() + ready_timeout
        while time.time() < deadline:
            if self._server.started:
                return self
            time.sleep(0.05)
        raise RuntimeError(f"mock server failed to start within {ready_timeout}s")

    def stop(self, timeout: float = 5.0) -> None:
        if self._server is not None:
            self._server.should_exit = True
        if self._thread is not None:
            self._thread.join(timeout=timeout)
        self._server = None
        self._thread = None


def create_server(host: str | None = None, port: int | None = None) -> MockServer:
    """Convenience for the console-script entry point."""
    return MockServer(
        host=host or DEFAULT_HOST,
        port=port if port is not None else DEFAULT_PORT,
    )
