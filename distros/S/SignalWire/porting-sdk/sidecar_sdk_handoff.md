# Hosting `ai_sidecar` (and any non-agent SWML verb) in the SDK

**Status (2026-04-28):** the original draft of this doc proposed a `SidecarBase` class parallel to `AgentBase`. After review, that approach was rejected — see "Why no SidecarBase" below. The actual answer is much smaller: **lift SWAIG hosting from AgentBase down into SWMLService**, and let users build a sidecar (or any non-agent SWML service) with plain `SWMLService` code.

The Python prototype landed on `signalwire-python` main with this shape. All 10 language ports must follow the same lift; see `PORTING_GUIDE.md` → "SWMLService is the SWAIG host" for the canonical contract.

The full mod_openai-side `ai_sidecar` schema, event taxonomy, and lifecycle is at `mod_openai/ai_sidecar_schema.md` — that's the source of truth for what `ai_sidecar` does on the platform side. This doc is only about the SDK's hosting story.

---

## What the SDK needs to provide

Three capabilities, all of them already present on `SWMLService` after the lift:

1. **Emit any SWML doc, including `<ai_sidecar>`.** `SWMLService.add_section(...)` + `add_verb_to_section(...)` already accept arbitrary verb dicts. No new code.
2. **Host SWAIG callbacks at `POST /<route>/swaig`.** This is the lift: tool registration (`define_tool`), the `/swaig` route, and the dispatch handler all live on `SWMLService` now (previously only on `AgentBase`).
3. **(Optional) Host a sidecar event sink at `POST /<route>/events`.** Already supported via `SWMLService.register_routing_callback(handler, path="/events")`.

Existing `AgentBase` users see *zero* API change. `AgentBase` keeps its full surface — token validation, ephemeral dynamic config, prompt-rendered SWML on GET — by overriding two extension points exposed by `SWMLService`:

| Extension point | SWMLService default | AgentBase override |
|---|---|---|
| `_swaig_render_get_response(request, callId)` | `render_document()` | `_render_swml(callId)` (full prompt rebuild) |
| `_swaig_pre_dispatch(request, body, callId, fnName)` | `(self, null)` | session-token validation + ephemeral copy for dynamic config |

---

## How a user writes a sidecar (after the lift)

```python
from signalwire.core.swml_service import SWMLService
from signalwire.core.function_result import FunctionResult

class SalesSidecar(SWMLService):
    def __init__(self):
        super().__init__(name="sales-sidecar", route="/sales-sidecar")

        # 1. Build the SWML doc — ai_sidecar is just a verb config dict.
        self.add_section("main")
        self.add_verb_to_section("main", "answer", {})
        self.add_verb_to_section("main", "ai_sidecar", {
            "prompt": "You are a real-time sales copilot...",
            "lang": "en-US",
            "direction": ["remote-caller", "local-caller"],
            "model": "gpt-4o-mini",
            "url": "https://your-host/sales-sidecar/events",
            "SWAIG": {
                "defaults": {"web_hook_url": "https://your-host/sales-sidecar/swaig"},
                "functions": [],  # populated from define_tool below at render time, or pre-populated
            },
        })

        # 2. Register a SWAIG tool — same API agents use.
        self.define_tool(
            name="lookup_competitor",
            description="Look up competitor pricing.",
            parameters={
                "type": "object",
                "properties": {"competitor": {"type": "string"}},
                "required": ["competitor"],
            },
            handler=self.lookup_competitor,
        )

        # 3. (Optional) Register an event-sink endpoint.
        self.register_routing_callback(self.on_sidecar_event, path="/events")

    def lookup_competitor(self, args, raw_data):
        return FunctionResult(f"{args['competitor']} is $99/seat; we're $79.")

    def on_sidecar_event(self, request, body):
        if body.get("type") == "insight":
            print(f"insight: {body.get('raw')}")
        return None  # 200 OK
```

`GET /sales-sidecar` returns the SWML doc. `POST /sales-sidecar/swaig` dispatches `lookup_competitor`. `POST /sales-sidecar/events` flows into `on_sidecar_event`. No new class hierarchy required.

---

## Validation the user code should do (or the SDK should do for them)

The mod_openai side rejects bad sidecar configs at start time. The SDK *can* validate client-side to fail fast:

1. `prompt` is set and non-empty.
2. `lang` is set (BCP-47 string).
3. `direction` includes both `remote-caller` AND `local-caller` if specified.
4. No registered SWAIG function is named `sidecar_skip` (mod_openai auto-registers it as a built-in).

These can live as a small helper (e.g. `validate_ai_sidecar_verb(config)`) in each port's SDK; they're not a hard requirement of the lift.

---

## SWAIG callback contract (`POST /<route>/swaig`)

Same payload format `AgentBase` already serves — no changes for sidecar.

```json
{
  "function": "lookup_competitor",
  "argument": {"raw": "{\"competitor\":\"ACME\"}"},
  "global_data": { ... },
  "channel_data": { "call_id": "...", ... },
  "project_id": "...",
  "space_id": "..."
}
```

The handler accepts the nested `argument.raw` / `argument.parsed` shape AND a flat `arguments` dict (some external integrations send the latter). The SDK parses either into a Python `dict` and passes to the user's tool function with `(args, raw_data)`.

Response is the `FunctionResult` shape (`{"response": "...", "action": [...]}`).

---

## Sidecar event sink contract (`POST /<route>/events`)

Optional. If the user calls `register_routing_callback(handler, path="/events")` and points the sidecar's `url` field at that endpoint, mod_openai POSTs every event there:

```json
{
  "type": "insight" | "skip" | "tool_call" | "tool_result" | "action" |
          "turn" | "request" | "thought" | "global_data_change" |
          "error" | "history_pruned" | "start" | "stop" | "final",
  "ts": 1745870400123456,
  "tick_id": 7,
  "channel_data": { "call_id": "...", ... },
  ...type-specific fields...
}
```

Field shape varies per `type`. See `mod_openai/ai_sidecar_schema.md`.

The user's callback returns `None` for fire-and-forget. mod_openai doesn't act on the response body — it just needs HTTP 200. Exceptions in the user callback should be caught and 200-OK'd anyway; never let a user handler exception break event delivery.

For multi-event-type dispatch (different handlers per `type`), the user can either:
- Register a single callback that switches on `body.get("type")`, OR
- Register one callback per type at the same path (the SDK matches on `type` field) — this is convenience sugar each port can add if idiomatic.

---

## What ports must verify

Every language SDK already has both `SWMLService` and `AgentBase`. The lift is a **refactor of existing code**, not a new abstraction:

1. **Move `ToolMixin` (or equivalent — tool registration + `on_function_call` dispatch) from AgentBase composition into SWMLService.** AgentBase inherits it via SWMLService; no separate composition.
2. **Move `_handle_swaig_request` from WebMixin (or AgentBase) into SWMLService.** Mount `/swaig` GET/POST in `SWMLService.as_router()` (or your port's equivalent).
3. **Expose two extension points on SWMLService:** `_swaig_render_get_response` (default: serialize current doc) and `_swaig_pre_dispatch` (default: no-op, return `(self, null)`).
4. **Override those two extension points on AgentBase** to preserve current behavior: token validation, ephemeral dynamic config, full prompt-rendered SWML on GET.
5. **Move helpers `_check_content_type` and `_read_body_with_limit` to SWMLService** (they were on WebMixin previously) — both `/swaig` and the agent endpoints need them.

Existing AgentBase tests must pass unchanged. Add two new test groups in each port:
- `test_swml_service_swaig` — proves `define_tool` works on plain SWMLService, `/swaig` POST dispatches, `/swaig` GET returns the doc, no token validation by default.
- `sidecar pattern` test — builds a SWMLService with `ai_sidecar` verb + a tool + a routing-callback event sink; asserts all three surfaces are mounted and dispatch end-to-end.

The Python prototype landed on `signalwire-python` main with these shapes. Use it as the reference.

---

## Why no SidecarBase

The original draft proposed `SidecarBase extends SWMLService` parallel to `AgentBase extends SWMLService`. The case against:

1. **Class-level decorators don't port.** The draft's public API used `@SidecarBase.tool(...)` and `@SidecarBase.on_sidecar_event(...)`. Of the 10 language SDKs, only Python (and partially TypeScript) have native class-level decorators. Java/C# have annotations (metadata, not behavior); Go/Rust/C++ have nothing equivalent. A decorator-shaped public API would force each port to invent a different idiom, guaranteeing API drift.
2. **The duplication wasn't real.** The draft's `SidecarBase` differed from `AgentBase` only in: (a) which verb it emits, and (b) which subset of agent machinery it skips. Both are *less behavior*, not different behavior. Lifting SWAIG hosting down to SWMLService gives users the same outcome with less code and no new class.
3. **Sidecar isn't special.** Future verbs (anything that wants its own SWAIG callbacks but isn't `<ai>`) would each justify another `XBase`. Better to fix the architecture once.

Out of scope for this lift (same as the original draft):
- Multi-sidecar per call (mod_openai is single-sidecar).
- Sidecar-without-transcribe (mod_openai requires both).
- Mode-switching mid-call.
- A sidecar version of every prefab — those are agent-shaped.

---

## Cross-reference

- `mod_openai/ai_sidecar_schema.md` — full body schema, event taxonomy, lifecycle (source of truth)
- `mod_openai/sidecar_plan.md` — design rationale and decision history
- `mod_openai/docs/SIDECAR_MODE.md` — action support matrix and mode guards
- `signalwire-python` `tests/unit/core/test_swml_service_swaig.py` — reference tests for the lift; ports should write equivalents
- `PORTING_GUIDE.md` § "SWMLService is the SWAIG host" — port-side requirements
