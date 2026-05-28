"""RELAY JSON-Schema loader.

Loads every ``relay-protocol/<method>.<phase>.json`` file at startup and
makes them available by ``(method, phase)`` lookup. Schemas are pre-parsed
once; per-frame we just call ``jsonschema.Draft202012Validator(schema)``
on the cached doc.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable, Iterator


# Default location of relay-protocol/ schemas in this repo.
DEFAULT_SCHEMA_ROOT = Path(__file__).resolve().parents[3] / "relay-protocol"


@dataclass
class LoadedSchema:
    """One on-disk schema, identified by ``method`` + ``phase``."""

    method: str
    phase: str  # "params" | "result" | "event"
    schema: dict[str, Any]
    source: str  # x-source: switchblade | blade | messaging-python | mod_infrastructure
    permissive: bool = False
    file: Path | None = None


@dataclass
class SchemaIndex:
    """In-memory schema index keyed by (method, phase)."""

    by_key: dict[tuple[str, str], LoadedSchema] = field(default_factory=dict)
    schema_root: Path | None = None
    load_errors: list[dict[str, str]] = field(default_factory=list)

    @property
    def total(self) -> int:
        return len(self.by_key)

    def get(self, method: str, phase: str) -> LoadedSchema | None:
        return self.by_key.get((method, phase))

    def methods(self) -> set[str]:
        return {k[0] for k in self.by_key}

    def by_source(self) -> dict[str, int]:
        counts: dict[str, int] = {}
        for s in self.by_key.values():
            counts[s.source] = counts.get(s.source, 0) + 1
        return counts

    def list_specs(self) -> list[dict[str, Any]]:
        """Summary for the ``/__mock__/specs`` debug endpoint."""
        out = []
        for (method, phase), s in sorted(self.by_key.items()):
            out.append(
                {
                    "method": method,
                    "phase": phase,
                    "source": s.source,
                    "permissive": s.permissive,
                    "required": s.schema.get("required") or [],
                }
            )
        return out


def _parse_schema_file(path: Path) -> LoadedSchema | None:
    """Load one ``<method>.<phase>.json`` file and return a LoadedSchema."""
    text = path.read_text(encoding="utf-8")
    doc = json.loads(text)
    if not isinstance(doc, dict):
        raise ValueError(f"{path} did not parse to an object")
    method = doc.get("x-method")
    phase = doc.get("x-phase")
    if not isinstance(method, str) or not isinstance(phase, str):
        # Fall back to filename: <method>.<phase>.json
        stem = path.name.rsplit(".json", 1)[0]
        if "." not in stem:
            return None
        method, _, phase = stem.rpartition(".")
    source = str(doc.get("x-source") or "unknown")
    permissive = bool(doc.get("x-permissive", False))
    return LoadedSchema(
        method=method,
        phase=phase,
        schema=doc,
        source=source,
        permissive=permissive,
        file=path,
    )


def load_all(schema_root: Path | str | None = None) -> SchemaIndex:
    """Load every schema file in ``schema_root``.

    Returns a fully-populated SchemaIndex. Failures are collected on
    ``index.load_errors`` rather than raised, so the server still starts
    when one schema file is malformed.
    """
    root = Path(schema_root) if schema_root else DEFAULT_SCHEMA_ROOT
    index = SchemaIndex(schema_root=root)
    if not root.exists():
        index.load_errors.append(
            {"file": str(root), "error": f"schema root does not exist"}
        )
        return index

    for path in sorted(root.glob("*.json")):
        try:
            entry = _parse_schema_file(path)
        except Exception as exc:
            index.load_errors.append({"file": str(path), "error": str(exc)})
            continue
        if entry is None:
            index.load_errors.append({"file": str(path), "error": "could not infer method/phase"})
            continue
        index.by_key[(entry.method, entry.phase)] = entry

    return index
