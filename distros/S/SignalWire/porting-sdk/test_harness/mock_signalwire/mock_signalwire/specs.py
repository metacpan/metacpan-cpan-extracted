"""OpenAPI spec loader and route table builder.

Reads each SignalWire spec, resolves the server URL prefix, and produces a
flat route table:
    [(METHOD, full_path_template, RouteEntry), ...]

The server URL prefix is the path component of the first ``servers[0].url``;
everything in ``paths`` is appended to it. So the compatibility spec, with
``servers[0].url = https://{space}.signalwire.com/api/laml/2010-04-01`` and a
path ``/Accounts/{AccountSid}``, produces the route
``/api/laml/2010-04-01/Accounts/{AccountSid}``.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import urlparse

import yaml


logger = logging.getLogger(__name__)


# The 13 spec namespaces under porting-sdk/rest-apis/.
SPEC_NAMES: tuple[str, ...] = (
    "calling",
    "chat",
    "compatibility",
    "datasphere",
    "fabric",
    "fax",
    "logs",
    "message",
    "project",
    "pubsub",
    "relay-rest",
    "video",
    "voice",
)


# Default location of OpenAPI specs in this repo.
DEFAULT_SPEC_ROOT = Path(__file__).resolve().parents[3] / "rest-apis"


@dataclass
class RouteEntry:
    """A single route registered from one (METHOD, path) operation in a spec."""

    spec_name: str
    method: str  # uppercase HTTP method
    path_template: str  # e.g. "/api/laml/2010-04-01/Accounts/{AccountSid}"
    operation_id: str | None
    operation: dict[str, Any]  # the raw OpenAPI operation object
    schemas: dict[str, Any]  # components.schemas of the parent doc (for $ref resolution)
    pattern: re.Pattern[str] = field(init=False)
    param_names: tuple[str, ...] = field(init=False)

    def __post_init__(self) -> None:
        self.pattern, self.param_names = _path_template_to_regex(self.path_template)

    @property
    def endpoint_id(self) -> str:
        """Stable id used for the /__mock__/scenarios endpoint."""
        if self.operation_id:
            return f"{self.spec_name}.{self.operation_id}"
        return f"{self.method}.{self.path_template}"

    def match(self, path: str) -> dict[str, str] | None:
        """If ``path`` matches this template, return the captured params."""
        m = self.pattern.match(path)
        if not m:
            return None
        return m.groupdict()


def _path_template_to_regex(template: str) -> tuple[re.Pattern[str], tuple[str, ...]]:
    """Convert ``/foo/{bar}/baz/{qux}`` to a regex capturing each ``{name}``."""

    param_names: list[str] = []

    def replace(m: re.Match[str]) -> str:
        name = m.group(1)
        param_names.append(name)
        # OpenAPI paths don't allow slash inside a path param, so [^/]+ is correct.
        return rf"(?P<{name}>[^/]+)"

    pattern_src = re.sub(r"\{([^/{}]+)\}", replace, re.escape(template).replace(r"\{", "{").replace(r"\}", "}"))
    return re.compile(f"^{pattern_src}/?$"), tuple(param_names)


def _server_path_prefix(spec: dict[str, Any]) -> str:
    """Return the leading path component of ``servers[0].url`` (with no trailing slash)."""
    servers = spec.get("servers") or []
    if not servers:
        return ""
    url = servers[0].get("url", "")
    parsed = urlparse(url)
    prefix = parsed.path or ""
    if prefix.endswith("/") and prefix != "/":
        prefix = prefix.rstrip("/")
    return prefix


@dataclass
class SpecLoadError:
    spec_name: str
    error: str


@dataclass
class LoadResult:
    routes: list[RouteEntry]
    errors: list[SpecLoadError]
    specs_loaded: int


class SpecLoader:
    """Loads OpenAPI specs from a root directory and produces a flat route table."""

    def __init__(self, spec_root: Path | str | None = None, spec_names: Iterable[str] | None = None) -> None:
        self.spec_root = Path(spec_root) if spec_root else DEFAULT_SPEC_ROOT
        self.spec_names = tuple(spec_names) if spec_names else SPEC_NAMES

    def load_all(self) -> LoadResult:
        routes: list[RouteEntry] = []
        errors: list[SpecLoadError] = []
        loaded = 0
        for name in self.spec_names:
            try:
                spec_routes = self._load_one(name)
                routes.extend(spec_routes)
                loaded += 1
                logger.info("Loaded spec %s with %d routes", name, len(spec_routes))
            except Exception as exc:  # pragma: no cover - shouldn't happen
                logger.exception("Failed to load spec %s", name)
                errors.append(SpecLoadError(spec_name=name, error=str(exc)))
        return LoadResult(routes=routes, errors=errors, specs_loaded=loaded)

    def _load_one(self, name: str) -> list[RouteEntry]:
        spec_path = self.spec_root / name / "openapi.yaml"
        if not spec_path.exists():
            raise FileNotFoundError(f"spec not found: {spec_path}")

        with spec_path.open("r", encoding="utf-8") as f:
            doc = yaml.safe_load(f)
        if not isinstance(doc, dict):
            raise ValueError(f"spec {name} did not parse as a mapping")

        prefix = _server_path_prefix(doc)
        schemas = (doc.get("components") or {}).get("schemas") or {}

        routes: list[RouteEntry] = []
        for raw_path, ops in (doc.get("paths") or {}).items():
            if not isinstance(ops, dict):
                continue
            full_path = f"{prefix}{raw_path}" if not raw_path.startswith(prefix) else raw_path
            for method, op in ops.items():
                if method.lower() not in {"get", "post", "put", "patch", "delete", "head", "options"}:
                    continue
                if not isinstance(op, dict):
                    continue
                routes.append(
                    RouteEntry(
                        spec_name=name,
                        method=method.upper(),
                        path_template=full_path,
                        operation_id=op.get("operationId"),
                        operation=op,
                        schemas=schemas,
                    )
                )
        return routes
