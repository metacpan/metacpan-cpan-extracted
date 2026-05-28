#!/usr/bin/env python3
"""Extract JSON-Schema 2020-12 wire shapes for the SignalWire RELAY protocol.

Sources, in priority order:

* **switchblade C# Params/Result** — the C# server is the canonical schema
  authority for almost every calling method. Each ``PublicCall<Name>Params.cs``
  / ``PublicCall<Name>Result.cs`` file is parsed line-by-line for
  ``[JsonProperty("...")]`` attributes; the Newtonsoft semantics
  (``Required = Required.Always`` vs ``NullValueHandling = NullValueHandling.Ignore``)
  determine the schema's ``required`` array. Nested types like ``CallDevice``
  are followed and emitted as separate schemas.

* **switchblade Messages/** — the Blade envelope frames (``signalwire.connect``,
  ``signalwire.execute``, ``signalwire.ping``, ``signalwire.disconnect``,
  ``signalwire.reauthenticate``).

* **mod_infrastructure relay.c** — scanned for
  ``swclt_sess_register_protocol_method(session, RELAY_CALLING_PROTOCOL,
  "<method>", ...)`` callsites. Methods registered here but absent from
  switchblade get a permissive placeholder schema marked with
  ``"x-source": "mod_infrastructure"``.

* **Python SDK ``signalwire/relay/client.py``** — used as a fallback for
  ``messaging.send`` (switchblade has no ``PublicMessage*`` classes; the
  C# handler just forwards a ``JObject`` to the messaging gateway).

Outputs go to ``porting-sdk/relay-protocol/<method>.<phase>.json`` where
``<phase>`` is ``params``, ``result``, or ``event`` (events are envelope
shapes for ``signalwire.event`` payloads). The script is idempotent — same
inputs → byte-identical output.

Usage::

    python3 scripts/extract_relay_schemas.py            # write
    python3 scripts/extract_relay_schemas.py --check    # exit 1 on drift
    python3 scripts/extract_relay_schemas.py --verbose  # log stats
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable


# ---------------------------------------------------------------------------
# Filesystem layout
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = REPO_ROOT / "relay-protocol"

# Source repos we read.
SWITCHBLADE_ROOT = Path("/home/devuser/src/switchblade")
SWITCHBLADE_CALLING = SWITCHBLADE_ROOT / "RelayPlugin" / "Calling"
SWITCHBLADE_MESSAGES = SWITCHBLADE_ROOT / "switchblade" / "Messages"
SWITCHBLADE_PUBLIC_STD_RESULT = SWITCHBLADE_ROOT / "RelayPlugin" / "PublicStandardResult.cs"
MOD_INFRASTRUCTURE_RELAY_C = Path("/home/devuser/src/mod_infrastructure/relay.c")

JSON_SCHEMA_VERSION = "https://json-schema.org/draft/2020-12/schema"


# ---------------------------------------------------------------------------
# Newtonsoft.JSON parsing
# ---------------------------------------------------------------------------

# Match a [JsonProperty("...", ...)] attribute on its own line. Property names
# can contain underscores, digits, dots, and (via ``PropertyName = "..."``) any
# string literal Newtonsoft accepts. Both ``[JsonProperty("foo", ...)]`` and
# ``[JsonProperty(PropertyName = "foo", ...)]`` forms are used.
_JSONPROP_RE = re.compile(
    r"""\[\s*JsonProperty\s*\(
        \s*
        (?:                                    # match either form
            "(?P<name1>[^"]+)"                 #   "foo"
            |
            PropertyName\s*=\s*"(?P<name2>[^"]+)"
        )
        (?P<rest>[^\]]*)                       # any other args
        \)\s*\]""",
    re.VERBOSE,
)

# Match the property declaration that follows: e.g. ``public string Foo { get;``.
# We capture (modifiers) (type) (name).
_PROPERTY_DECL_RE = re.compile(
    r"""^\s*public\s+
        (?:sealed\s+|virtual\s+|override\s+|static\s+|readonly\s+)*
        (?P<type>[\w<>\[\]\.,\s]+?\??)
        \s+
        (?P<name>\w+)
        \s*\{""",
    re.VERBOSE,
)

# Class declaration. Captures name and (optional) base type.
_CLASS_DECL_RE = re.compile(
    r"""^\s*public\s+(?:sealed\s+|abstract\s+|static\s+)*
        class\s+(?P<name>\w+)
        (?:\s*:\s*(?P<base>[\w\.]+))?
        \s*$""",
    re.VERBOSE,
)


@dataclass
class JsonField:
    """One ``[JsonProperty]`` annotated property parsed from a C# class."""

    json_name: str
    csharp_type: str
    csharp_property: str
    required_always: bool = False
    nullable: bool = False  # ``int?`` / ``bool?`` → True
    null_value_ignore: bool = False


@dataclass
class CSharpClass:
    name: str
    base_type: str | None = None
    fields: list[JsonField] = field(default_factory=list)
    nested_classes: dict[str, "CSharpClass"] = field(default_factory=dict)
    parent_class: str | None = None  # for nested classes, the outer class name


def _parse_csharp_file(path: Path) -> dict[str, CSharpClass]:
    """Return a map of class name → CSharpClass for every ``public class`` in *path*.

    Nested classes are flattened into the same map but tagged with
    ``parent_class`` so we can reach them by qualified name.
    """
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    classes: dict[str, CSharpClass] = {}
    class_stack: list[CSharpClass] = []
    pending_jsonprops: list[tuple[str, str]] = []  # [(json_name, attr_args)]

    brace_depth = 0
    class_brace_depths: list[int] = []  # brace depth where each class started

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Track brace depth
        # (Crude but adequate: this code base uses one-line braces only inside
        # property accessors; we only care about class boundaries.)
        # Class starts on the line CONTAINING `class Foo` plus the opening `{`
        # which is usually on the next line. Track the brace depth where each
        # class block opens, then close the class when brace_depth drops back to
        # that value.
        m_class = _CLASS_DECL_RE.match(line)
        if m_class:
            cname = m_class.group("name")
            base = m_class.group("base")
            cls = CSharpClass(name=cname, base_type=base)
            if class_stack:
                cls.parent_class = class_stack[-1].name
                class_stack[-1].nested_classes[cname] = cls
            classes[cname] = cls
            class_stack.append(cls)
            # The opening { is on this line or the next.
            class_brace_depths.append(brace_depth)
            # If `{` is on this line, count it
            if "{" in line:
                brace_depth += line.count("{") - line.count("}")
                i += 1
                continue
            # else we'll see the `{` on the next iteration
            i += 1
            continue

        # JsonProperty attribute (may span lines, but in practice all on one line)
        m_attr = _JSONPROP_RE.search(line)
        if m_attr:
            json_name = m_attr.group("name1") or m_attr.group("name2")
            rest = m_attr.group("rest") or ""
            pending_jsonprops.append((json_name, rest))
            # Brace tracking for this line
            brace_depth += line.count("{") - line.count("}")
            i += 1
            continue

        # Property declaration that consumes pending [JsonProperty]
        m_prop = _PROPERTY_DECL_RE.match(line)
        if m_prop and pending_jsonprops and class_stack:
            csharp_type = m_prop.group("type").strip()
            csharp_name = m_prop.group("name")
            json_name, rest = pending_jsonprops.pop(0)
            field = JsonField(
                json_name=json_name,
                csharp_type=csharp_type,
                csharp_property=csharp_name,
                required_always="Required.Always" in rest,
                nullable=csharp_type.endswith("?"),
                null_value_ignore="NullValueHandling.Ignore" in rest,
            )
            class_stack[-1].fields.append(field)
            brace_depth += line.count("{") - line.count("}")
            i += 1
            continue

        # Plain brace counting
        opens = line.count("{")
        closes = line.count("}")
        brace_depth += opens - closes

        # Check whether we just closed a class
        while class_stack and class_brace_depths and brace_depth <= class_brace_depths[-1]:
            class_stack.pop()
            class_brace_depths.pop()

        i += 1

    return classes


# ---------------------------------------------------------------------------
# C# type → JSON schema
# ---------------------------------------------------------------------------

# Map of C# scalar/collection types to JSON-Schema fragments.
# Note: we deliberately keep schemas permissive — the mock validates only the
# property names + presence, not the nested values, so a matching shape is
# enough.

_PRIMITIVE_TYPE_TO_SCHEMA: dict[str, dict[str, Any]] = {
    "string": {"type": "string"},
    "int": {"type": "integer"},
    "long": {"type": "integer"},
    "short": {"type": "integer"},
    "uint": {"type": "integer", "minimum": 0},
    "ulong": {"type": "integer", "minimum": 0},
    "byte": {"type": "integer", "minimum": 0, "maximum": 255},
    "double": {"type": "number"},
    "float": {"type": "number"},
    "decimal": {"type": "number"},
    "bool": {"type": "boolean"},
    "boolean": {"type": "boolean"},
    "DateTime": {"type": "string", "format": "date-time"},
    "Guid": {"type": "string", "format": "uuid"},
    "object": {},
    "JObject": {"type": "object"},
    "JToken": {},
    "JArray": {"type": "array"},
}


def _csharp_type_to_schema(
    csharp_type: str,
    classes: dict[str, CSharpClass],
    seen: set[str] | None = None,
) -> dict[str, Any]:
    """Translate a C# type expression to a JSON-Schema 2020-12 fragment.

    Recurses into custom classes via ``classes``. ``seen`` blocks cycles.
    """
    seen = seen or set()
    t = csharp_type.strip()
    if t.endswith("?"):
        t = t[:-1].strip()

    # Container: List<X>
    m_list = re.match(r"^List<(.+)>$", t)
    if m_list:
        inner = m_list.group(1).strip()
        return {
            "type": "array",
            "items": _csharp_type_to_schema(inner, classes, seen),
        }
    # Container: Dictionary<K, V>
    m_dict = re.match(r"^Dictionary<\s*\w+\s*,\s*(.+)>$", t)
    if m_dict:
        return {
            "type": "object",
            "additionalProperties": _csharp_type_to_schema(m_dict.group(1).strip(), classes, seen),
        }
    # Array T[]
    if t.endswith("[]"):
        inner = t[:-2].strip()
        return {
            "type": "array",
            "items": _csharp_type_to_schema(inner, classes, seen),
        }

    # Primitive
    if t in _PRIMITIVE_TYPE_TO_SCHEMA:
        return dict(_PRIMITIVE_TYPE_TO_SCHEMA[t])

    # Newtonsoft enum-as-string converters: any enum type becomes string.
    if t.endswith("DeviceType") or t.endswith("PlayType") or "DetectType" in t or "AudioDirection" in t or "RecordType" in t:
        return {"type": "string"}

    # Local class lookup (custom DTO, possibly nested)
    if t in classes:
        if t in seen:
            return {"type": "object"}  # break cycle
        return _class_to_schema(classes[t], classes, seen | {t})

    # Unknown — permissive
    return {}


def _class_to_schema(
    cls: CSharpClass,
    classes: dict[str, CSharpClass],
    seen: set[str] | None = None,
) -> dict[str, Any]:
    """Build a JSON-Schema object schema from a parsed C# class."""
    seen = seen or set()
    properties: dict[str, Any] = {}
    required: list[str] = []
    for field in cls.fields:
        sub = _csharp_type_to_schema(field.csharp_type, classes, seen)
        # Mark nullable types explicitly.
        if field.nullable:
            # JSON-Schema 2020-12: type can be array including "null"
            if isinstance(sub.get("type"), str):
                sub = dict(sub)
                sub["type"] = [sub["type"], "null"]
        properties[field.json_name] = sub
        if field.required_always:
            required.append(field.json_name)
    schema: dict[str, Any] = {"type": "object", "properties": properties}
    if required:
        schema["required"] = required
    # We allow additional fields — many params are forward-compat.
    schema["additionalProperties"] = True
    return schema


def _root_schema(
    title: str,
    description: str,
    payload_schema: dict[str, Any],
    extra_meta: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Wrap an inner payload schema in a top-level JSON-Schema document."""
    out: dict[str, Any] = {
        "$schema": JSON_SCHEMA_VERSION,
        "title": title,
        "description": description,
    }
    if extra_meta:
        out.update(extra_meta)
    # Fold the payload into the root schema.
    for k, v in payload_schema.items():
        out[k] = v
    return out


# ---------------------------------------------------------------------------
# Method-name mapping (CSharp class basename → RELAY method)
# ---------------------------------------------------------------------------


# Sub-command suffixes that produce dotted method names (e.g.
# ``PublicCallPlayPause`` → ``calling.play.pause``). Listed longest-first so
# ``StartInputTimers`` beats ``Stop``.
_SUBCOMMAND_SUFFIXES: tuple[str, ...] = (
    "StartInputTimers",
    "Resume",
    "Pause",
    "Stop",
    "Volume",
)

# Hard-coded base names for dotted methods where the base is itself a
# multi-word camel chunk (e.g. ``PublicCallPlayAndCollect`` → ``play_and_collect``,
# whose stop becomes ``play_and_collect.stop``).
_KNOWN_BASE_METHODS: tuple[str, ...] = (
    "PlayAndCollect",
    "Play",
    "Record",
    "Detect",
    "Collect",
    "Pay",
    "SendFax",
    "ReceiveFax",
    "Tap",
    "Stream",
    "Transcribe",
    "Ai",
    "Denoise",
    "Queue",
)

# Methods whose suffix doesn't actually mean "sub-command" — they're just
# normal methods that happen to end in a sub-command-looking word.
# Here ``PublicCallReceiveFax`` is a real method (``calling.receive_fax``), not
# the ``stop`` of anything; it's the multi-word ``ReceiveFax`` base.
# Add overrides if the heuristic disagrees with the real method.
_NAME_OVERRIDES: dict[str, str] = {
    "PublicCallAmazonBedrock": "calling.amazon_bedrock",
    "PublicCallAiHold": "calling.ai_hold",
    "PublicCallAiUnhold": "calling.ai_unhold",
    "PublicCallAiMessage": "calling.ai_message",
    "PublicCallSendDigits": "calling.send_digits",
    "PublicCallBindDigit": "calling.bind_digit",
    "PublicCallClearDigitBindings": "calling.clear_digit_bindings",
    "PublicCallSendFax": "calling.send_fax",
    "PublicCallReceiveFax": "calling.receive_fax",
    "PublicCallJoinConference": "calling.join_conference",
    "PublicCallLeaveConference": "calling.leave_conference",
    "PublicCallJoinRoom": "calling.join_room",
    "PublicCallLeaveRoom": "calling.leave_room",
    "PublicCallLiveTranscribe": "calling.live_transcribe",
    "PublicCallLiveTranslate": "calling.live_translate",
    "PublicCallUserEvent": "calling.user_event",
    "PublicCallPlayAndCollect": "calling.play_and_collect",
    "PublicCallQueueEnter": "calling.queue.enter",
    "PublicCallQueueLeave": "calling.queue.leave",
    "PublicCallPlayAndCollectStop": "calling.play_and_collect.stop",
    "PublicCallPlayAndCollectVolume": "calling.play_and_collect.volume",
    "PublicCallSendFaxStop": "calling.send_fax.stop",
    "PublicCallReceiveFaxStop": "calling.receive_fax.stop",
    "PublicCallCollectStartInputTimers": "calling.collect.start_input_timers",
}


def _camel_to_snake(name: str) -> str:
    """Convert ``CamelCase`` to ``snake_case``."""
    # Insert underscore before any uppercase letter that follows a lowercase
    # letter or digit (and isn't at the start).
    out = re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", name)
    return out.lower()


def class_basename_to_method(basename: str) -> str:
    """Map e.g. ``PublicCallPlayPause`` → ``calling.play.pause``.

    The basename has ``Params``/``Result`` already stripped.
    """
    full = "PublicCall" + basename
    if full in _NAME_OVERRIDES:
        return _NAME_OVERRIDES[full]
    # Generic: split into <Base><Suffix> when suffix is a known sub-command.
    for suffix in _SUBCOMMAND_SUFFIXES:
        if basename.endswith(suffix) and basename != suffix:
            head = basename[: -len(suffix)]
            return f"calling.{_camel_to_snake(head)}.{_camel_to_snake(suffix)}"
    return f"calling.{_camel_to_snake(basename)}"


# ---------------------------------------------------------------------------
# Loading switchblade classes
# ---------------------------------------------------------------------------


def _load_calling_classes() -> dict[str, CSharpClass]:
    """Parse every C# file under switchblade's RelayPlugin/Calling/ + the
    PublicStandardResult helper so cross-class references resolve.
    """
    classes: dict[str, CSharpClass] = {}
    files = sorted(SWITCHBLADE_CALLING.glob("*.cs"))
    for f in files:
        classes.update(_parse_csharp_file(f))
    if SWITCHBLADE_PUBLIC_STD_RESULT.exists():
        classes.update(_parse_csharp_file(SWITCHBLADE_PUBLIC_STD_RESULT))
    return classes


def _load_envelope_classes() -> dict[str, CSharpClass]:
    """Parse every C# file under switchblade/switchblade/Messages/."""
    classes: dict[str, CSharpClass] = {}
    files = sorted(SWITCHBLADE_MESSAGES.glob("*.cs"))
    for f in files:
        classes.update(_parse_csharp_file(f))
    return classes


# Standard "code/message/data" base — when a Result extends ``PublicStandardResult``
# we inject those fields.
def _public_standard_result_fields() -> list[JsonField]:
    return [
        JsonField(
            json_name="code",
            csharp_type="string",
            csharp_property="Code",
            required_always=True,
        ),
        JsonField(
            json_name="message",
            csharp_type="string",
            csharp_property="Message",
            null_value_ignore=True,
        ),
        JsonField(
            json_name="data",
            csharp_type="JToken",
            csharp_property="Data",
            null_value_ignore=True,
        ),
    ]


def _expand_with_base(cls: CSharpClass) -> CSharpClass:
    """If a class extends ``PublicStandardResult``, prepend its base fields."""
    if cls.base_type == "PublicStandardResult":
        # Prepend code/message/data so Result schemas always reflect the wire.
        merged = CSharpClass(name=cls.name, base_type=cls.base_type)
        existing_names = {f.json_name for f in cls.fields}
        for f in _public_standard_result_fields():
            if f.json_name not in existing_names:
                merged.fields.append(f)
        merged.fields.extend(cls.fields)
        merged.nested_classes = cls.nested_classes
        return merged
    return cls


# ---------------------------------------------------------------------------
# mod_infrastructure scanning
# ---------------------------------------------------------------------------


_REGISTER_METHOD_RE = re.compile(
    r"swclt_sess_register_protocol_method\s*\(\s*[^,]+,\s*[A-Z_]+,\s*\"(?P<method>[^\"]+)\"\s*,",
)


def _load_mod_infrastructure_methods() -> set[str]:
    """Scan relay.c for `swclt_sess_register_protocol_method(..., "method", ...)`.

    Returns the set of method names (e.g. ``{"call"}``).
    """
    if not MOD_INFRASTRUCTURE_RELAY_C.exists():
        return set()
    try:
        text = MOD_INFRASTRUCTURE_RELAY_C.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return set()
    return set(_REGISTER_METHOD_RE.findall(text))


# ---------------------------------------------------------------------------
# Schema emission
# ---------------------------------------------------------------------------


@dataclass
class EmittedSchema:
    method: str
    phase: str  # "params" | "result" | "event"
    schema: dict[str, Any]
    source: str  # "switchblade" | "messaging-python" | "mod_infrastructure" | "blade"


def _emit_calling_method_schemas(
    classes: dict[str, CSharpClass],
) -> list[EmittedSchema]:
    """For every PublicCall<Name>Params.cs / Result.cs class, emit one schema."""
    out: list[EmittedSchema] = []
    seen_methods: set[tuple[str, str]] = set()
    for name, cls in sorted(classes.items()):
        if not name.startswith("PublicCall"):
            continue
        for suffix in ("Params", "Result"):
            if name.endswith(suffix):
                basename = name[len("PublicCall") : -len(suffix)]
                method = class_basename_to_method(basename)
                phase = "params" if suffix == "Params" else "result"
                key = (method, phase)
                if key in seen_methods:
                    continue
                expanded = _expand_with_base(cls)
                inner = _class_to_schema(expanded, classes)
                doc = _root_schema(
                    title=f"{method} {phase}",
                    description=(
                        f"Wire schema for the JSON payload of `{method}` ({phase}). "
                        f"Extracted from switchblade `{name}.cs`."
                    ),
                    payload_schema=inner,
                    extra_meta={
                        "x-source": "switchblade",
                        "x-source-file": f"RelayPlugin/Calling/{name}.cs",
                        "x-method": method,
                        "x-phase": phase,
                    },
                )
                out.append(EmittedSchema(method, phase, doc, "switchblade"))
                seen_methods.add(key)
                break
    return out


def _emit_envelope_schemas(
    envelope_classes: dict[str, CSharpClass],
) -> list[EmittedSchema]:
    """Emit Blade envelope schemas (signalwire.connect, .ping, .execute, .reauthenticate, .disconnect)."""
    out: list[EmittedSchema] = []
    pairs = (
        ("signalwire.connect", "params", "ConnectParams"),
        ("signalwire.connect", "result", "ConnectResult"),
        ("signalwire.reauthenticate", "params", "ReauthenticateParams"),
        ("signalwire.reauthenticate", "result", "ReauthenticateResult"),
        ("signalwire.execute", "params", "ExecuteParams"),
        ("signalwire.execute", "result", "ExecuteResult"),
        ("signalwire.ping", "params", "PingParams"),
        ("signalwire.ping", "result", "PingResult"),
        ("signalwire.disconnect", "params", "DisconnectParams"),
        ("signalwire.disconnect", "result", "DisconnectResult"),
    )
    for method, phase, classname in pairs:
        cls = envelope_classes.get(classname)
        if not cls:
            continue
        inner = _class_to_schema(cls, envelope_classes)
        doc = _root_schema(
            title=f"{method} {phase}",
            description=(
                f"Wire schema for the Blade envelope `{method}` ({phase}). "
                f"Extracted from switchblade `Messages/{classname}.cs`."
            ),
            payload_schema=inner,
            extra_meta={
                "x-source": "blade",
                "x-source-file": f"switchblade/Messages/{classname}.cs",
                "x-method": method,
                "x-phase": phase,
            },
        )
        out.append(EmittedSchema(method, phase, doc, "blade"))
    return out


def _emit_messaging_schemas() -> list[EmittedSchema]:
    """Permissive schemas for the messaging namespace.

    Source: ``signalwire/relay/client.py:send_message`` (the Python client is
    the schema authority because switchblade has no PublicMessage classes).
    """
    out: list[EmittedSchema] = []

    send_params = {
        "type": "object",
        "properties": {
            "context": {"type": "string"},
            "to_number": {"type": "string"},
            "from_number": {"type": "string"},
            "body": {"type": "string"},
            "media": {"type": "array", "items": {"type": "string"}},
            "tags": {"type": "array", "items": {"type": "string"}},
            "region": {"type": "string"},
        },
        "required": ["context", "to_number", "from_number"],
        # body OR media required. We can't express that with required[]; document
        # in description.
        "additionalProperties": True,
    }
    out.append(
        EmittedSchema(
            method="messaging.send",
            phase="params",
            schema=_root_schema(
                title="messaging.send params",
                description=(
                    "Permissive schema for the messaging.send RPC params. "
                    "Switchblade forwards the JObject as-is to the messaging "
                    "gateway, so the schema is derived from the Python relay "
                    "client (``signalwire/relay/client.py:send_message``). "
                    "At least one of `body` or `media` is required."
                ),
                payload_schema=send_params,
                extra_meta={
                    "x-source": "messaging-python",
                    "x-source-file": "signalwire/relay/client.py",
                    "x-method": "messaging.send",
                    "x-phase": "params",
                },
            ),
            source="messaging-python",
        )
    )

    send_result = {
        "type": "object",
        "properties": {
            "code": {"type": "string"},
            "message": {"type": "string"},
            "message_id": {"type": "string"},
        },
        "required": ["code", "message_id"],
        "additionalProperties": True,
    }
    out.append(
        EmittedSchema(
            method="messaging.send",
            phase="result",
            schema=_root_schema(
                title="messaging.send result",
                description=(
                    "Permissive schema for the messaging.send RPC response. "
                    "The message_id from the response is used to route "
                    "subsequent messaging.state events."
                ),
                payload_schema=send_result,
                extra_meta={
                    "x-source": "messaging-python",
                    "x-source-file": "signalwire/relay/client.py",
                    "x-method": "messaging.send",
                    "x-phase": "result",
                },
            ),
            source="messaging-python",
        )
    )

    receive_event = {
        "type": "object",
        "properties": {
            "message_id": {"type": "string"},
            "context": {"type": "string"},
            "direction": {"type": "string", "enum": ["inbound"]},
            "from_number": {"type": "string"},
            "to_number": {"type": "string"},
            "body": {"type": "string"},
            "media": {"type": "array", "items": {"type": "string"}},
            "segments": {"type": "integer"},
            "message_state": {"type": "string", "enum": ["received"]},
            "tags": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["message_id", "direction", "message_state"],
        "additionalProperties": True,
    }
    out.append(
        EmittedSchema(
            method="messaging.receive",
            phase="event",
            schema=_root_schema(
                title="messaging.receive event payload",
                description=(
                    "Schema for the inner params of a `messaging.receive` "
                    "signalwire.event."
                ),
                payload_schema=receive_event,
                extra_meta={
                    "x-source": "messaging-python",
                    "x-source-file": "signalwire/relay/client.py",
                    "x-method": "messaging.receive",
                    "x-phase": "event",
                },
            ),
            source="messaging-python",
        )
    )

    state_event = {
        "type": "object",
        "properties": {
            "message_id": {"type": "string"},
            "context": {"type": "string"},
            "direction": {"type": "string", "enum": ["outbound"]},
            "from_number": {"type": "string"},
            "to_number": {"type": "string"},
            "body": {"type": "string"},
            "media": {"type": "array", "items": {"type": "string"}},
            "segments": {"type": "integer"},
            "message_state": {
                "type": "string",
                "enum": [
                    "queued", "initiated", "sent",
                    "delivered", "undelivered", "failed",
                ],
            },
            "reason": {"type": "string"},
            "tags": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["message_id", "direction", "message_state"],
        "additionalProperties": True,
    }
    out.append(
        EmittedSchema(
            method="messaging.state",
            phase="event",
            schema=_root_schema(
                title="messaging.state event payload",
                description=(
                    "Schema for the inner params of a `messaging.state` "
                    "signalwire.event."
                ),
                payload_schema=state_event,
                extra_meta={
                    "x-source": "messaging-python",
                    "x-source-file": "signalwire/relay/client.py",
                    "x-method": "messaging.state",
                    "x-phase": "event",
                },
            ),
            source="messaging-python",
        )
    )

    return out


def _emit_mod_infrastructure_placeholders(
    methods: set[str],
    already_have: set[str],
) -> list[EmittedSchema]:
    """For every protocol method registered in mod_infrastructure that doesn't
    have a switchblade Params class, emit a permissive placeholder.

    These are FreeSWITCH-side methods (``signalwire.calling`` protocol)
    consumed by mod_infrastructure but not exposed as a managed Params class
    in switchblade. The mock should accept any payload for them.
    """
    out: list[EmittedSchema] = []
    for raw_method in sorted(methods):
        full_method = f"calling.{raw_method}"
        if full_method in already_have:
            continue
        for phase in ("params", "result"):
            doc = _root_schema(
                title=f"{full_method} {phase}",
                description=(
                    f"Placeholder schema for the FreeSWITCH-side "
                    f"`{full_method}` method. Registered via "
                    f"`swclt_sess_register_protocol_method(..., \"{raw_method}\", ...)` "
                    f"in mod_infrastructure/relay.c but not exposed as a "
                    f"switchblade Params/Result class. The mock accepts any "
                    f"payload for this method."
                ),
                payload_schema={
                    "type": "object",
                    "additionalProperties": True,
                },
                extra_meta={
                    "x-source": "mod_infrastructure",
                    "x-source-file": "mod_infrastructure/relay.c",
                    "x-method": full_method,
                    "x-phase": phase,
                    "x-permissive": True,
                },
            )
            out.append(
                EmittedSchema(
                    method=full_method,
                    phase=phase,
                    schema=doc,
                    source="mod_infrastructure",
                )
            )
    return out


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def _filename_for(s: EmittedSchema) -> Path:
    return OUTPUT_DIR / f"{s.method}.{s.phase}.json"


def _serialize(schema: dict[str, Any]) -> str:
    """Deterministic JSON: sorted keys, 2-space indent, trailing newline."""
    return json.dumps(schema, indent=2, sort_keys=True) + "\n"


def write_schemas(schemas: list[EmittedSchema], check: bool = False) -> tuple[int, int]:
    """Write the schemas to disk (or compare).

    Returns ``(written_or_changed_count, total)``.
    """
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    changed = 0
    expected_files: set[str] = set()
    for s in schemas:
        path = _filename_for(s)
        expected_files.add(path.name)
        text = _serialize(s.schema)
        if path.exists():
            existing = path.read_text(encoding="utf-8")
            if existing == text:
                continue
        if check:
            print(f"DRIFT: {path.relative_to(REPO_ROOT)} would change", file=sys.stderr)
        else:
            path.write_text(text, encoding="utf-8")
        changed += 1

    # Cleanup stale schemas (only files we own — *.params.json, *.result.json,
    # *.event.json that don't match an expected name).
    for existing in OUTPUT_DIR.glob("*.json"):
        if existing.name not in expected_files:
            if check:
                print(f"DRIFT: {existing.relative_to(REPO_ROOT)} is stale", file=sys.stderr)
                changed += 1
            else:
                existing.unlink()
                changed += 1

    return changed, len(schemas)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero if on-disk schemas differ from what we would emit.",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Print per-source counts.",
    )
    args = parser.parse_args(argv)

    if not SWITCHBLADE_CALLING.exists():
        print(
            f"ERROR: switchblade source not found at {SWITCHBLADE_CALLING}",
            file=sys.stderr,
        )
        return 2

    # 1. Calling methods.
    calling_classes = _load_calling_classes()
    calling_schemas = _emit_calling_method_schemas(calling_classes)

    # 2. Blade envelope frames.
    envelope_classes = _load_envelope_classes()
    envelope_schemas = _emit_envelope_schemas(envelope_classes)

    # 3. Messaging.
    messaging_schemas = _emit_messaging_schemas()

    # 4. mod_infrastructure placeholders.
    mod_methods = _load_mod_infrastructure_methods()
    methods_already = {s.method for s in calling_schemas}
    mod_schemas = _emit_mod_infrastructure_placeholders(mod_methods, methods_already)

    all_schemas = calling_schemas + envelope_schemas + messaging_schemas + mod_schemas

    if args.verbose:
        print(f"calling C# schemas:       {len(calling_schemas)}")
        print(f"blade envelope schemas:   {len(envelope_schemas)}")
        print(f"messaging python schemas: {len(messaging_schemas)}")
        print(f"mod_infrastructure stubs: {len(mod_schemas)}")
        print(f"total:                    {len(all_schemas)}")

    changed, total = write_schemas(all_schemas, check=args.check)

    if args.check:
        if changed:
            print(
                f"DRIFT: {changed} of {total} schemas would change. "
                f"Run scripts/extract_relay_schemas.py to update.",
                file=sys.stderr,
            )
            return 1
        print(f"OK: {total} relay schemas in sync.")
        return 0

    print(f"Wrote {changed} of {total} schemas to {OUTPUT_DIR}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
