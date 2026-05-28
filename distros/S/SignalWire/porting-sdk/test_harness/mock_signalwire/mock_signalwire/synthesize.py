"""Response synthesis from OpenAPI schemas.

For a given operation, pick the response code and content-type, then synthesize
a body. Preference order:

1. ``responses[code].content[application/json].example`` — single example.
2. ``responses[code].content[application/json].examples[<first>].value``.
3. The schema's own ``examples: [...]`` or ``example``.
4. Walk the schema and produce a deterministic synthetic value.

Field-level ``examples`` arrays in the schema are used for object properties.
``$ref`` references are resolved against ``components.schemas``.
"""

from __future__ import annotations

import logging
import re
from typing import Any


logger = logging.getLogger(__name__)


# Deterministic constants used when no example is present in the spec.
_FIXED_UUID = "00000000-0000-4000-8000-000000000000"
_FIXED_DATETIME = "2024-01-01T00:00:00Z"
_FIXED_DATE = "2024-01-01"
_FIXED_EMAIL = "test@example.com"
_FIXED_URI = "https://example.com/test"
_FIXED_PHONE = "+15555550100"


def pick_success_response(op: dict[str, Any]) -> tuple[int, dict[str, Any]]:
    """Return (status_code, response_object) for the success response."""
    responses = op.get("responses") or {}
    # Prefer 2xx in numeric order; fallback to 'default'.
    candidates = []
    for code in responses.keys():
        try:
            code_int = int(code)
            if 200 <= code_int < 300:
                candidates.append((code_int, responses[code]))
        except (TypeError, ValueError):
            continue
    if candidates:
        candidates.sort(key=lambda x: x[0])
        return candidates[0]
    if "default" in responses:
        return 200, responses["default"]
    return 200, {}


def synthesize_response(
    op: dict[str, Any],
    schemas: dict[str, Any],
    path_params: dict[str, str] | None = None,
) -> tuple[int, Any]:
    """Pick a 2xx response and synthesize its body.

    Returns (status_code, body). ``body`` is the JSON-serializable value
    (usually a dict, sometimes a list). Returns ``(status_code, None)`` for
    204 / empty responses.
    """
    status, response = pick_success_response(op)
    if status == 204:
        return status, None

    content = (response.get("content") or {}).get("application/json") or {}
    schema = content.get("schema") or {}

    # Direct ``example`` (singular) on the response content.
    if "example" in content:
        return status, _apply_path_params(content["example"], path_params)
    # ``examples`` (plural) -> dict[name -> {value}].
    examples = content.get("examples") or {}
    if examples:
        first = next(iter(examples.values()))
        if isinstance(first, dict) and "value" in first:
            return status, _apply_path_params(first["value"], path_params)

    body = _synthesize_from_schema(schema, schemas, set())
    return status, _apply_path_params(body, path_params)


def _synthesize_from_schema(
    schema: Any,
    schemas: dict[str, Any],
    seen_refs: set[str],
) -> Any:
    """Walk ``schema`` and synthesize a JSON value.

    ``seen_refs`` blocks recursive cycles by treating cycles as ``None``.
    """
    if not isinstance(schema, dict):
        return None

    # $ref
    ref = schema.get("$ref")
    if ref:
        if ref in seen_refs:
            return None
        target = _resolve_ref(ref, schemas)
        if target is None:
            return None
        return _synthesize_from_schema(target, schemas, seen_refs | {ref})

    # First-class examples on the schema itself
    if "example" in schema:
        return schema["example"]
    if "examples" in schema and isinstance(schema["examples"], list) and schema["examples"]:
        return schema["examples"][0]
    if "default" in schema:
        return schema["default"]

    # allOf / anyOf / oneOf — pick the first non-null branch.
    for combinator in ("allOf", "anyOf", "oneOf"):
        if combinator in schema and isinstance(schema[combinator], list) and schema[combinator]:
            if combinator == "allOf":
                # Merge all branches; later ones override.
                merged: dict[str, Any] = {}
                for branch in schema[combinator]:
                    val = _synthesize_from_schema(branch, schemas, seen_refs)
                    if isinstance(val, dict):
                        merged.update(val)
                # If merged is still empty, look at description-only branches.
                if merged:
                    return merged
                # Fall through to first branch's synthesized value.
                return _synthesize_from_schema(schema[combinator][0], schemas, seen_refs)
            else:
                # Pick the first non-null branch.
                for branch in schema[combinator]:
                    if isinstance(branch, dict) and branch.get("type") == "null":
                        continue
                    return _synthesize_from_schema(branch, schemas, seen_refs)
                return None

    typ = schema.get("type")
    fmt = schema.get("format")
    enum = schema.get("enum")

    if enum:
        return enum[0]

    if typ == "object" or "properties" in schema:
        out: dict[str, Any] = {}
        properties = schema.get("properties") or {}
        required = set(schema.get("required") or [])
        for prop_name, prop_schema in properties.items():
            # Always include required props; include the rest deterministically too
            # so SDK parsers see fully-populated objects.
            out[prop_name] = _synthesize_from_schema(prop_schema, schemas, seen_refs)
        # additionalProperties — leave empty (deterministic).
        # If there are required keys not in properties, add a placeholder.
        for k in required:
            if k not in out:
                out[k] = None
        return out

    if typ == "array":
        items = schema.get("items") or {}
        # Single representative element. Tests can override via scenarios.
        return [_synthesize_from_schema(items, schemas, seen_refs)]

    if typ == "string" or (typ is None and fmt):
        if fmt == "uuid":
            return _FIXED_UUID
        if fmt == "date-time":
            return _FIXED_DATETIME
        if fmt == "date":
            return _FIXED_DATE
        if fmt == "email":
            return _FIXED_EMAIL
        if fmt in {"uri", "url"}:
            return _FIXED_URI
        if fmt == "byte":
            return "dGVzdA=="  # base64 for "test"
        if fmt == "binary":
            return ""
        return "string"

    if typ == "integer":
        return 0
    if typ == "number":
        return 0.0
    if typ == "boolean":
        return False
    if typ == "null":
        return None

    # Untyped — best-effort empty object.
    return {}


def _resolve_ref(ref: str, schemas: dict[str, Any]) -> dict[str, Any] | None:
    """Resolve a local component schema reference."""
    prefix = "#/components/schemas/"
    if not ref.startswith(prefix):
        return None
    name = ref[len(prefix):]
    return schemas.get(name)


def _apply_path_params(value: Any, params: dict[str, str] | None) -> Any:
    """Substitute ``{name}`` tokens in any string in ``value`` with ``params[name]``."""
    if not params:
        return value
    if isinstance(value, str):
        return _substitute(value, params)
    if isinstance(value, list):
        return [_apply_path_params(v, params) for v in value]
    if isinstance(value, dict):
        return {k: _apply_path_params(v, params) for k, v in value.items()}
    return value


_TOKEN_RE = re.compile(r"\{([A-Za-z0-9_]+)\}")


def _substitute(s: str, params: dict[str, str]) -> str:
    def repl(m: re.Match[str]) -> str:
        name = m.group(1)
        return params.get(name, m.group(0))

    return _TOKEN_RE.sub(repl, s)
