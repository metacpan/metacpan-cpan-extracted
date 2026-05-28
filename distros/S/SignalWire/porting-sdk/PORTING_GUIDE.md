# SignalWire AI Agents SDK — Porting Guide

This document captures everything needed to port the SignalWire AI Agents SDK to a new language. It was derived from porting Python → TypeScript → Go, including architectural decisions, gotchas, and the optimal build order.

---

## Table of Contents

1. [Philosophy](#philosophy)
2. [Build Order](#build-order)
3. [Module Layout](#module-layout)
4. [SWML Core](#swml-core)
5. [Agent Core](#agent-core)
6. [SwaigFunctionResult](#swaigfunctionresult)
7. [DataMap](#datamap)
8. [Contexts & Steps](#contexts--steps)
9. [Skills System](#skills-system)
10. [Prefab Agents](#prefab-agents)
11. [AgentServer](#agentserver)
12. [RELAY Client](#relay-client)
13. [REST Client](#rest-client)
14. [Security](#security)
15. [Serverless Support](#serverless-support)
16. [CLI Tools](#cli-tools)
17. [What to Skip](#what-to-skip)
18. [Language-Specific Patterns](#language-specific-patterns)
19. [Testing Strategy](#testing-strategy)
20. [LiveKit Compatibility Shim](#livekit-compatibility-shim)

---

## Philosophy

The SignalWire AI Agents SDK generates SWML documents that tell the SignalWire platform how to run AI agents. **The platform handles the entire AI pipeline** (STT, LLM, TTS, VAD, media) — the SDK just configures it. This is the key architectural insight:

- The agent defines: prompts, tools, voice/language config, call flow verbs
- The agent serves: an HTTP endpoint that returns SWML JSON
- The platform calls: the agent's `/swaig` endpoint when tools are invoked
- The agent returns: `SwaigFunctionResult` with response text and actions

This means a port does NOT need to implement any AI pipeline, audio processing, or media handling. It just needs to generate correct SWML JSON and handle HTTP webhooks.

### Quality Standards for AI-Assisted Porting

If you are using AI coding agents to build the port:

- **Never accept partial or incomplete results.** If a sub-agent stops early, returns truncated output, or fails to complete its task, re-run it until you get complete results. Do not proceed with partial data — it leads to missing features and incorrect implementations.
- **Verify every agent's output.** Compile the code, run the tests, and check that the output matches what was requested. Do not trust that it's correct without verification.
- **Don't skip research.** Before building, thoroughly read the Python SDK source code, the TypeScript port, and this guide. Incomplete understanding leads to incomplete ports.
- **Audit when complete.** After the port is done, run the completeness and security audits described in the Final Audit section. Fix everything found — do not ship with known gaps.
- **Don't overlook details.** Every method, every parameter, every edge case matters. A port that's 90% complete is not shippable — the missing 10% is what users will hit first.
- **Commit to git after every phase.** Initialize the repo at the start (`main` branch), and commit after each completed phase with a descriptive message. This gives you rollback points, makes progress visible, and ensures nothing is lost if a session ends unexpectedly. Run all tests before each commit.

### Production Code Discipline (READ THIS FIRST)

**Every line of code in every SDK is production code.** There is no "example-only" or "demo-only" tier. Every file ships to users. The example a user copies on day one and the CLI they run to debug their agent are both production. Skills, transports, prefabs, CLI HTTP layers — all production.

Stubs are bugs. Always. No exceptions for "I'll come back to it" or "feature-gate it for now."

#### Forbidden patterns (a green test suite does NOT excuse these)

A function body is a stub — i.e., a bug — if any of these are true:

1. It returns a string like `"would call X in production"`, `"stub: this would..."`, `"not implemented"`, `"transport not available"`.
2. It returns canned/hardcoded data shaped to *look* like a real upstream response without actually contacting the upstream (e.g., a `web_search` skill that returns `["fake result 1", "fake result 2"]` regardless of query).
3. It carries a comment like `// Stub: in production this would...`, `# Stub:`, `/* stub */`, `// TODO: implement`, `// FIXME: implement`.
4. It calls `panic!("not implemented")`, `unimplemented!()`, `todo!()`, `throw new NotImplementedException(...)`, `raise NotImplementedError(...)` to *cover for missing implementation* (as opposed to legitimate abstract-method or optional-extra patterns — see allow-list below).
5. It is feature-gated such that the default build excludes the real implementation (e.g., `#[cfg(feature = "ureq")]` where the `ureq` feature is not declared in `Cargo.toml`, or where it's declared but disabled by default and there's no non-feature-gated fallback that works).
6. An example file in `examples/` exits early, prints "would do X", or skips the call it advertises in its docstring/header.
7. A skill that names an upstream service (Google CSE, Wikipedia, DataSphere, MCP gateway, etc.) returns a response without actually contacting that upstream.
8. A relay/WebSocket transport does not actually open a socket and run the handshake.

A test is itself a violation if it codifies any of the above:

- `assert err.contains("not available")` — wrong; the function should *not* return that.
- `assert response == "stub: would call API"` — wrong; the response should be the real API result or, in a recorded fixture, the recorded real result.
- A test that mocks a transport away in a way that *removes the requirement that the transport exists at all* — wrong; the transport's existence and basic correctness must be tested separately.

If you find a test asserting a stub, the test is wrong, not the production code.

#### Multi-pass implementation is fine; merged stubs are not

A real port of a complex feature (relay WebSocket transport, full ContextBuilder DSL, every skill's upstream integration) may take several commits across several sessions. Each commit must be *honest*:

- **OK:** WIP branch with the implementation in progress, tests pending. Not merged to `main`.
- **OK:** A merged commit that ports a *subset* of a feature, with the remaining surface clearly absent (no stub function exists where the missing surface would be).
- **NOT OK:** A merged commit that ports a *symbol* of a feature with a stub body, presented as complete on the checklist.

The rule: if the symbol exists, the body is real. If the body isn't real yet, the symbol doesn't exist yet.

#### Allow-list: legitimate non-implementation patterns

These are NOT stubs and are explicitly allowed. Each must be justified in `INTENTIONAL_NON_IMPLEMENTATION.md` so `audit_stubs.py` doesn't flag it:

- **Optional-extra import guards.** E.g. `raise NotImplementedError("CLI helpers not available")` when an optional dependency isn't installed. The error message must clearly direct the user to install the extra.
- **Abstract methods** in base classes whose subclasses MUST override (e.g., Ruby `SkillBase#name` raising `NotImplementedError`).
- **Documented platform/API restrictions** where the upstream service genuinely doesn't support the operation (e.g., "cXML applications cannot be created via this API" for a service-side limitation).
- **Genuine no-op shims** for cross-API compatibility (e.g., the LiveKit shim's `prewarm` hook, where SignalWire genuinely doesn't need that lifecycle stage). These must be documented as no-ops in their docstring AND in `INTENTIONAL_NON_IMPLEMENTATION.md`.

Anything else is a stub.

#### What examples must do

Every file in `examples/` is required to *do the thing it advertises*. The header docstring is a contract. If the example says "this serves a SWAIG endpoint and dispatches `lookup_competitor`," then running the example must serve `/swaig` and dispatch `lookup_competitor`. If the example says "this connects to RELAY and places a call," then running it must connect via WebSocket and place a call.

Examples are part of the public API surface. A user adopting the SDK will start with the closest-matching example. A broken example is a broken first impression and a broken proof of the SDK.

#### What unit tests must do

Unit tests prove that production code does its real job end-to-end. Tests target *behavior*, not *shape*:

- **Wrong:** "the symbol exists" → `assert callable(svc.define_tool)`.
- **Right:** "the symbol does its job" → `define_tool + dispatch via /swaig + assert real response`.

Where the real upstream is a network endpoint (Google CSE, DataSphere, MCP gateway, Relay WebSocket, etc.), tests must use one of:

- A live call gated by an env var (e.g., `SWSDK_LIVE_TESTS=1`), with an offline test that uses a recorded HTTP/WS cassette of the real endpoint's response.
- A protocol-level test double that simulates the upstream wire format faithfully (NOT a mock that skips the transport entirely).

A test that mocks `requests.post` to return a hardcoded dict, where the production function only does `requests.post`, has tested nothing.

#### What the audit pipeline must do

The verification pipeline is a set of runnable programs in `porting-sdk/scripts/`. Each one exits 0 on success and non-zero with a list of failures. Every per-language convention is hard-coded *inside* the audit program — there's nothing to install per port. An agent fixing a port runs the relevant audits as the FINAL receipt, and pastes exit codes in its report. The main session re-runs them to verify; agents are not believed without a green program output.

The full suite (all must be clean before any port is "complete"):

| Program | What it proves |
|---|---|
| `audit_stubs.py` | No stub function bodies — neither commented stubs (`// stub: in production...`) nor silent canned-data stubs (functions whose params are all prefixed `_` and whose body is one literal return). Allow-list lives in port's `INTENTIONAL_NON_IMPLEMENTATION.md`. |
| `audit_http_swml.py` | Each port's example services bind a real socket, return a real SWML doc on `GET <route>`, and route `POST <route>/swaig` through to the registered handler with the documented response. Catches dispatcher stubs that return canned `[]` regardless of input. |
| `audit_relay_handshake.py` | Each port's RELAY client opens a real WSS connection (against a local WS fixture bound on `127.0.0.1:0` that speaks JSON-RPC 2.0 and the `signalwire.connect` handshake), parses auth response, subscribes contexts, dispatches inbound events to callbacks. Catches stub WS transports. |
| `audit_rest_transport.py` | Each port's REST namespaces issue real HTTP requests with the documented method/path/headers and parse real-shape responses (against a local HTTP fixture). Proves transport + serialization, not third-party reachability. |
| `audit_skills_dispatch.py` | Each skill that names an upstream service issues a real outbound HTTP request against a local fixture (proving the skill is wired to a real transport, not returning canned data) and parses a recorded real-shape response correctly. Does NOT require live credentials — the fixture stands in for the upstream, but the SKD's transport layer must be real. |
| `audit_test_parity.py` | Every Python test (minus the documented skip list) has a behavior-equivalent in the port. Walks Python's `tests/` and the port's tests, maps by target symbol, fails on missing tests AND on tests whose body doesn't actually drive the symbol. |
| `audit_example_parity.py` | Every Python example (minus skip list) has a port-equivalent with the same documented contract. Encoded mapping per language. |
| `audit_no_cheat_tests.py` | No test cheats. Forbidden: `assert true`, empty/`pass`-bodied tests, no-assertion tests, tests that mock the very transport they exist to verify, tests that only assert nullness without checking content. Allow-list in port's `INTENTIONAL_THIN_TESTS.md`. |
| `audit_docs.py` (existing) | Every method referenced in port's docs/examples resolves in `port_surface.json`. |
| `diff_port_surface.py` (existing) | Symbol-level parity vs Python (minus `PORT_OMISSIONS.md`). |
| `audit_checklist.py` (existing) | Counts (41 SwaigFunctionResult action methods, 38 SWML verbs, 17 skills, etc.) match Python reference. |

These 11 programs are the gate. The first three answer "do all the named things exist?" (already had those). The middle five answer "do they actually work as advertised on real sockets, with real bytes on the wire?" — that's the gap that let stubs ship. The last three answer "is what's tested actually tested, and does the surface match Python?"

A port that passes the existing three but fails any of the new five is not complete. An agent that reports "fixed" without all 11 returning 0 is not done.

#### Skill audits use fixtures, not live keys

The skill upstream-call audit (`audit_skills_dispatch.py`) deliberately does NOT require live credentials for Google CSE / Wikipedia / DataSphere / MCP gateway / etc. Reaching the real upstream from CI is not the bar — the bar is "the SDK's skill handler issues a real outbound HTTP request against a fixture, and parses a recorded real-shape response correctly." That proves the SDK's transport and serialization are real (catches the "Stub: in production this would call..." kind), without requiring keys we won't have in CI.

If you want to test against the live upstream, gate it with an env var (e.g., `SWSDK_LIVE_TESTS=1`) and provide credentials separately. The fixture-based audit is the always-on baseline; live testing is a bonus.

#### Engineer's job

When you see a stub, the only acceptable resolutions are:
- **Implement it.** Pull the real library, write the real call, port the real semantics, run live or against a recorded fixture, and prove it works.
- **Delete the symbol.** If the feature was abandoned, remove the stub *and* remove its mention from docs/checklist/audits. The SDK shouldn't claim a surface it doesn't ship.

"Document it as a stub and move on" is not on the table.

---

## Build Order

Port in this exact order. Each phase depends on the previous ones.

### Phase 1: Foundation
- Logging system (levels, suppression, env var config)
- Configuration (env vars, defaults)
- Project structure, build tooling, test framework

### Phase 2: SWML Core
- Document model (sections, verbs, JSON rendering)
- Schema loading (embed `schema.json` from the Python SDK)
- **Auto-vivified verb methods from schema** (critical — see below)
- HTTP server with basic auth, security headers, health endpoints
- **SWMLService base class/struct** — independently runnable. Hosts SWAIG: tool registry, `define_tool(...)`, `register_swaig_function(...)`, `on_function_call(...)`, `GET/POST {route}/swaig`, routing-callback hooks. A user must be able to instantiate `SWMLService` directly, register a tool, emit any verb (including `ai_sidecar`), and serve `/` + `/swaig` without ever touching `AgentBase`. Phase 2 is not done until that works end-to-end with tests.

### Phase 3: Agent Core (largest phase)
- SwaigFunctionResult (41 action methods)
- SessionManager (HMAC-SHA256 tool tokens)
- DataMap builder (server-side tools)
- Contexts & Steps (workflow system)
- **AgentBase** — inherits from `SWMLService` (extends / `:public` / struct-embedding / `Deref`, whichever the language uses). AgentBase adds prompts, AI config, skills, dynamic config, `/post_prompt`, `/check_for_input`, `/debug_events`, `/mcp`, and overrides two SWMLService extension points (`_swaig_render_get_response`, `_swaig_pre_dispatch`). It does **not** redeclare the tool registry, `/swaig` route, name/route/host/port fields, or HTTP app — those are inherited.

### Phase 4: Skills & Prefabs
- SkillBase interface + SkillManager + Registry
- All 17 built-in skills (port the ones Python and TS have in common)
- 5 prefab agents (InfoGatherer, Survey, Receptionist, FAQ, Concierge)
- AgentServer (multi-agent hosting)

### Phase 5: RELAY Client
- WebSocket connection (Blade/JSON-RPC 2.0)
- Authentication (project/token and JWT)
- Call object (57+ methods)
- Action objects (11 types)
- Event system (22 types)
- Messaging (SMS/MMS)

### Phase 6: REST Client
- HTTP client with Basic Auth
- CrudResource pattern
- Pagination
- 18+ API namespaces

### Phase 7: Polish
- Serverless adapters (Lambda, Cloud Functions, Azure, CGI)
- CLI tools (swaig-test)
- Documentation — **100% of Python SDK docs** (except search-related). Every doc the Python SDK has, the port has.
- Examples — **100% of Python SDK examples** (except search-related). Every example proves a feature works.
- Tests — **100% of Python SDK test coverage** (except search-related). Every tested behavior in Python is tested in the port.

---

## Module Layout

There are TWO kinds of directories in every SDK port:
1. **Source packages** — the actual code
2. **Top-level user-facing directories** — each with README.md, docs/, and examples/

### Source Package Layout

```
sdk-root/
├── core/                  # Source packages (language-specific location)
│   ├── swml/              # SWML document model, builder, schema, SWMLService (tool registry + /swaig)
│   ├── agent/             # AgentBase (extends SWMLService), prompts, AI config
│   ├── swaig/             # SwaigFunctionResult (return-value action methods only)
│   ├── datamap/           # DataMap builder
│   ├── contexts/          # ContextBuilder, Context, Step
│   ├── security/          # SessionManager, auth
│   ├── skills/            # SkillBase, SkillManager, registry, 17 built-in
│   ├── prefabs/           # 5 pre-built agents
│   ├── server/            # AgentServer (multi-agent hosting)
│   ├── relay/             # RELAY WebSocket client source
│   ├── rest/              # REST HTTP client source + namespaces
│   └── logging/           # Structured logging
└── cli/                   # swaig-test CLI tool source
```

### Top-Level User-Facing Directories (REQUIRED)

**Every SDK port must have these top-level directories.** This is how the Python and TypeScript SDKs are structured. All ports must match.

```
sdk-root/
├── relay/                 # RELAY user-facing directory
│   ├── README.md          # Getting started, API overview, Go/TS/Python examples
│   ├── docs/              # Detailed reference docs
│   │   ├── getting-started.md
│   │   ├── call-methods.md
│   │   ├── events.md
│   │   ├── messaging.md
│   │   └── client-reference.md
│   └── examples/          # Standalone runnable examples
│       ├── relay_answer_and_welcome.*    # Answer inbound, play TTS, hangup
│       ├── relay_dial_and_play.*         # Dial outbound, play audio, hangup
│       └── relay_ivr_connect.*           # IVR with collect, connect to dept
│
├── rest/                  # REST user-facing directory
│   ├── README.md          # Getting started, namespace overview, examples
│   ├── docs/              # Detailed reference docs
│   │   ├── getting-started.md
│   │   ├── namespaces.md
│   │   ├── calling.md
│   │   ├── fabric.md
│   │   ├── compat.md
│   │   └── client-reference.md
│   └── examples/          # Standalone runnable examples (ALL 12 required)
│       ├── rest_10dlc_registration.*
│       ├── rest_calling_ivr_and_ai.*
│       ├── rest_calling_play_and_record.*
│       ├── rest_compat_laml.*
│       ├── rest_datasphere_search.*
│       ├── rest_fabric_conferences_and_routing.*
│       ├── rest_fabric_subscribers_and_sip.*
│       ├── rest_fabric_swml_and_callflows.*
│       ├── rest_manage_resources.*
│       ├── rest_phone_number_management.*
│       ├── rest_queues_mfa_and_recordings.*
│       └── rest_video_rooms.*
│
├── examples/              # Agent + SWMLService examples
│   ├── swmlservice_standalone.*    # REQUIRED — plain SWMLService hosts a tool, serves /swaig (no AgentBase)
│   ├── swmlservice_ai_sidecar.*    # REQUIRED — SWMLService emits <ai_sidecar>, registers a tool, dispatches end-to-end
│   ├── agent_simple.*              # AgentBase: minimal prompt + one tool
│   ├── agent_dynamic.*             # AgentBase: dynamic-config callback
│   └── ...                         # multi-agent, skills, prefabs, etc.
├── docs/                  # SDK documentation (architecture, guides, references)
└── ...
```

**The two `swmlservice_*` examples are non-negotiable.** They are the proof that SWMLService is independently runnable and that AgentBase is genuinely a subclass — not a parallel hierarchy with duplicated SWAIG hosting.

**README.md format for each directory:**
- What the module is and why you'd use it
- Installation / import instructions
- Quick start code example in the target language
- API overview with code snippets
- Link to detailed docs and examples
- Environment variables reference

**The relay and rest examples must be ported from the Python originals.** They cover the same API calls and patterns. The file names use the same convention across languages (just change the extension).

---

## SWML Core

### Schema-Driven Verb Methods

This is the most important pattern. The SWML schema (`schema.json`) defines 38 verbs. **Verb methods must be auto-generated from the schema**, not hardcoded.

The schema structure:
```
$defs.SWMLMethod.anyOf → list of $refs
Each $ref → $defs.VerbName → properties → { "actual_verb_name": {...} }
```

Example: `$defs.SIPRefer` has `properties: { "sip_refer": {...} }`. The actual verb name is `sip_refer`, not `SIPRefer`.

**Extraction algorithm:**
1. Parse `schema.json`
2. For each entry in `$defs.SWMLMethod.anyOf`:
   - Get the `$ref` (e.g., `#/$defs/SIPRefer`)
   - Look up the definition in `$defs`
   - The actual verb name is the first key in `properties`
3. Create a method for each verb name

**The 38 verbs (schema name → actual name):**
```
Answer → answer          AI → ai                AmazonBedrock → amazon_bedrock
Cond → cond              Connect → connect       Denoise → denoise
DetectMachine → detect_machine  EnterQueue → enter_queue  Execute → execute
Goto → goto              Hangup → hangup         JoinConference → join_conference
JoinRoom → join_room     Label → label           LiveTranscribe → live_transcribe
LiveTranslate → live_translate  Pay → pay         Play → play
Prompt → prompt          ReceiveFax → receive_fax  Record → record
RecordCall → record_call  Request → request       Return → return
SIPRefer → sip_refer     SendDigits → send_digits  SendFax → send_fax
SendSMS → send_sms       Set → set               Sleep → sleep
StopDenoise → stop_denoise  StopRecordCall → stop_record_call
StopTap → stop_tap       Switch → switch         Tap → tap
Transfer → transfer      Unset → unset           UserEvent → user_event
```

**Special cases:**
- `sleep` takes an integer (milliseconds), not a map/dict
- `ai` is auto-vivified here but **AgentBase hijacks it** with its own AI rendering pipeline

### SWML Document Structure

```json
{
  "version": "1.0.0",
  "sections": {
    "main": [
      {"answer": {"max_duration": 3600}},
      {"record_call": {"format": "mp4", "stereo": true}},
      {"ai": {
        "prompt": {"text": "You are a helpful assistant."},
        "post_prompt": "Summarize the conversation.",
        "post_prompt_url": "https://agent/post_prompt",
        "params": {"temperature": 0.7},
        "hints": ["SignalWire", "SWML"],
        "languages": [{"name": "English", "code": "en-US", "voice": "rachel"}],
        "SWAIG": {
          "functions": [...],
          "includes": [...],
          "native_functions": ["check_for_input"]
        },
        "global_data": {"key": "value"},
        "pronounce": [{"replace": "SW", "with": "SignalWire"}]
      }},
      {"hangup": {}}
    ]
  }
}
```

### 5-Phase Call Flow

The SWML document is assembled in 5 phases:
1. **Pre-answer verbs** — ringback tones, screening
2. **Answer verb** — with `max_duration`, optional `record_call`
3. **Post-answer verbs** — welcome messages, initial audio
4. **AI verb** — the main AI configuration (prompt, tools, params, etc.)
5. **Post-AI verbs** — cleanup after AI ends

---

## Agent Core

### SWMLService is the SWAIG host

`SWMLService` is the base class for everything that emits SWML and hosts SWAIG functions. It owns the tool registry, the `/swaig` endpoint, and the HTTP app. `AgentBase` is a subclass of `SWMLService` that adds agent-specific behavior (prompts, AI config, dynamic config, token validation) by overriding two extension points. There is no parallel hierarchy and no duplicated SWAIG hosting.

A user can instantiate `SWMLService` directly to host any non-agent SWML use case (the `ai_sidecar` verb, a SWAIG-tool-only service, etc.) without ever touching `AgentBase`:

```python
svc = SWMLService(name="sales-sidecar", route="/sales-sidecar")
svc.add_verb("answer", {})
svc.add_verb_to_section("main", "ai_sidecar", {...})
svc.define_tool(name="lookup_competitor", description="...", parameters={...},
                handler=lambda args, raw: {"response": "..."})
svc.run()  # serves GET /sales-sidecar (SWML) + POST /sales-sidecar/swaig
```

`AgentBase` reuses every bit of that — tool registry, `/swaig` route, HTTP app, name/route/host/port fields — and only overrides what's agent-specific.

### Hard invariants (every port)

These are the rules that make SWMLService and AgentBase share code instead of duplicating it. A port that violates any of these is broken regardless of test-pass count:

1. **`AgentBase` inherits from `SWMLService`** using the language's canonical idiom: `extends` / `: public` / `< Service` / struct embedding / `Deref<Target=Service>`. No standalone `AgentBase` class. No "AgentBase has-a Service" composition wrapper.
2. **The tool registry exists in exactly one place — on `SWMLService`.** `AgentBase` MUST NOT declare its own `tools` field, `tool_order`, or registry struct. It accesses the inherited registry.
3. **`define_tool`, `register_swaig_function`, `on_function_call`, `list_tool_names`, `has_tool` are defined on `SWMLService`.** `AgentBase` does not redefine them.
4. **The HTTP app/router is owned by `SWMLService`.** `AgentBase` mounts its extra routes (`/post_prompt`, `/check_for_input`, `/debug_events`, `/mcp`) onto the inherited app — it does not build a second app.
5. **Name, route, host, port, basic-auth credentials are fields of `SWMLService`.** `AgentBase` does not redeclare them.
6. **AgentBase overrides exactly two extension points** to layer in agent behavior. No third hook, no monkey-patching the dispatcher:

| Extension point | SWMLService default | AgentBase override |
|---|---|---|
| `_swaig_render_get_response(request, callId)` | Serialize the currently-built document via `render_document()` | Dynamically rebuild the doc via `_render_swml(callId)` (prompts, dynamic config) |
| `_swaig_pre_dispatch(request, body, callId, fnName)` | Returns `(self, null)` — no-op | Validates session token; creates ephemeral copy if dynamic-config callback set; returns `(target, shortCircuitDict)` |

### Key SWMLService Methods (independently usable, no AgentBase required)

**All configuration methods return self/this for chaining.**

Document: `add_section(name)`, `add_verb(verb, config)`, `add_verb_to_section(section, verb, config)`, `set_section`, `clear_sections`, plus the 38 auto-vivified verb methods (`answer`, `hangup`, `play`, `record_call`, `ai_sidecar` via the schema, etc.), `render_document()` / `render_swml()`.

Tools: `define_tool(name, description, parameters, handler, secure?)`, `register_swaig_function(dict)` (DataMap and other raw definitions), `define_tools()` / `list_tool_names()`, `has_tool(name)`, `on_function_call(name, args, rawData)`.

Routing: `register_routing_callback(handler, path)` for arbitrary `POST {route}/<path>` sinks (sidecar event endpoints, custom webhooks).

Web: `get_app()` / `as_router()`, `run(host?, port?)`, `serve(...)`, basic-auth credential resolution. Mounts `GET/POST {route}` (SWML) and `GET/POST {route}/swaig` (SWAIG dispatch + GET-returns-doc).

Extension points (override in subclasses): `_swaig_render_get_response`, `_swaig_pre_dispatch`.

### AgentBase Composition

`AgentBase` inherits SWMLService's surface (registry, routes, app, name/route/host/port). On top of that it composes 7 mixins for agent-specific behavior:

| Mixin (Python) | Responsibility | Port Strategy |
|---|---|---|
| PromptMixin | POM sections, raw text, contexts | PromptManager or inline |
| AuthMixin | Basic auth validation | AuthHandler or inline |
| SkillMixin | add_skill/remove_skill | Delegates to SkillManager |
| AIConfigMixin | Hints, languages, pronunciations, params | Inline fields |
| WebMixin | Agent-only routes (`/post_prompt`, `/check_for_input`, `/debug_events`, `/mcp`), CORS | Mount on the inherited SWMLService app |
| ServerlessMixin | Lambda/CGI/Cloud detection | ServerlessAdapter |
| StateMixin | Tool token creation/validation | Delegates to SessionManager |

The tool-registration + dispatch capability is **not** in this table because it lives on SWMLService. AgentBase inherits it; do not add a ToolMixin (or equivalent) to AgentBase composition.

### Key AgentBase Methods

**All configuration methods must return self/this for method chaining.**

Prompt: `SetPromptText`, `SetPostPrompt`, `PromptAddSection(title, body, bullets)`, `PromptAddSubsection`, `PromptAddToSection`, `PromptHasSection`, `GetPrompt`

Tools: `DefineTool(name, description, parameters, handler)`, `RegisterSwaigFunction(dict)` (for DataMap), `DefineTools()`, `OnFunctionCall(name, args, rawData)`

AI Config: `AddHint`, `AddHints`, `AddPatternHint`, `AddLanguage`, `SetLanguages`, `AddPronunciation`, `SetPronunciations`, `SetParam`, `SetParams`, `SetGlobalData`, `UpdateGlobalData`, `SetNativeFunctions`, `SetInternalFillers`, `AddInternalFiller`, `EnableDebugEvents`, `AddFunctionInclude`, `SetFunctionIncludes`, `SetPromptLlmParams`, `SetPostPromptLlmParams`

Verbs: `AddPreAnswerVerb`, `AddAnswerVerb`, `AddPostAnswerVerb`, `AddPostAiVerb`, `ClearPreAnswerVerbs`, `ClearPostAnswerVerbs`, `ClearPostAiVerbs`

Web: `SetDynamicConfigCallback`, `ManualSetProxyUrl`, `SetWebHookUrl`, `SetPostPromptUrl`, `AddSwaigQueryParams`, `ClearSwaigQueryParams`, `EnableDebugRoutes`

SIP: `EnableSipRouting`, `RegisterSipUsername`, `AutoMapSipUsernames`

Lifecycle: `OnSummary(callback)`, `OnDebugEvent(callback)`, `Run()`, `Serve()`, `AsRouter()`

### Dynamic Config (Per-Request Customization)

When `SetDynamicConfigCallback` is set:
1. On each SWML request, **clone** the agent into an ephemeral copy
2. Call the callback with `(queryParams, bodyParams, headers, agentCopy)`
3. The callback mutates the copy (add skills, change prompts, etc.)
4. Render SWML from the copy
5. Discard the copy (original agent is untouched)

This enables multi-tenancy: one agent definition serving different customers.

### HTTP Endpoints

| Endpoint | Method | Owner | Auth | Purpose |
|----------|--------|-------|------|---------|
| `{route}` | GET/POST | SWMLService | Basic | Return SWML document |
| `{route}/swaig` | GET/POST | SWMLService | Basic | SWAIG function dispatch (GET also returns SWML) |
| `{route}/post_prompt` | POST | AgentBase (via WebMixin) | Basic | Post-prompt summary callback |
| `{route}/check_for_input` | POST | AgentBase (via WebMixin) | Basic | Input-check callback |
| `{route}/debug_events` | POST | AgentBase (via WebMixin) | Basic | Debug-event webhook |
| `{route}/mcp` | POST | AgentBase (via WebMixin, opt-in) | Basic | MCP JSON-RPC bridge |
| `/health` | GET | WebMixin | None | Health check |
| `/ready` | GET | WebMixin | None | Readiness check |

`{route}` and `{route}/swaig` are owned by `SWMLService`, so any direct `SWMLService` user (sidecar, SWAIG-only service, custom verb host) gets them for free. The agent-only endpoints are mounted by AgentBase onto the inherited app.

### SWAIG Function Dispatch

When the platform calls a tool:
1. POST to `{route}/swaig` with JSON body (see payload format below)
2. SWMLService looks up the tool handler by function name and validates the name format (must match `^[a-zA-Z_][a-zA-Z0-9_]*$` — reject path-traversal-style names)
3. **(AgentBase only, via `_swaig_pre_dispatch` override)** If the tool is secure, validates the `meta_data_token` via SessionManager. If the dynamic-config callback is set, creates an ephemeral copy of the agent and calls the callback against the copy. On plain `SWMLService` this step is a no-op.
4. Calls the handler with `(args, rawData)` on the chosen target (self, or the ephemeral copy on AgentBase)
5. Handler returns a `SwaigFunctionResult`
6. Service serializes and returns the result

#### SWAIG Webhook Payload (what the platform POSTs to /swaig)

```json
{
  "function": "get_weather",
  "argument": {
    "parsed": [{"location": "London"}]
  },
  "call_id": "unique-call-uuid",
  "node_id": "node-uuid",
  "meta_data": {},
  "meta_data_token": "hmac-token-if-secure",
  "call": {
    "call_id": "unique-call-uuid",
    "node_id": "node-uuid",
    "segment_id": "segment-uuid",
    "call_state": "answered",
    "direction": "inbound",
    "type": "phone",
    "from": "+15551234567",
    "to": "+15559876543",
    "headers": []
  },
  "global_data": {"key": "value"},
  "caller_id_name": "",
  "caller_id_number": "+15551234567",
  "ai_session_id": "session-uuid"
}
```

Extract function args from `argument.parsed[0]` (it's an array with one object). The full payload is passed as `rawData` to the handler so tools can access `call`, `global_data`, etc.

#### Post-Prompt Payload (what the platform POSTs to /post_prompt)

```json
{
  "post_prompt_data": {
    "raw": "The raw AI summary text",
    "parsed": {"key": "value"},
    "substituted": "The substituted summary"
  },
  "call_id": "unique-call-uuid",
  "call": { ... },
  "global_data": { ... },
  "ai_session_id": "session-uuid"
}
```

The `on_summary` callback receives the parsed summary object (or null if parsing failed) and the full raw payload.

### Webhook URL Construction

Each tool's `web_hook_url` in the SWML is built as:
```
{proxyURLBase || scheme://host:port}{route}/swaig?query_params
```

If `webhookURL` is explicitly set, use that instead.

### Proxy URL Auto-Detection

If `SWML_PROXY_URL_BASE` is not set, detect the proxy from request headers (checked in order):
1. `X-Forwarded-Proto` + `X-Forwarded-Host` → `https://forwarded-host`
2. `X-Original-URL` → use directly
3. Fall back to `scheme://host:port` from the server config

### POM (Prompt Object Model) Serialization

When `usePom` is true, prompt sections are rendered as a structured array:

```json
{
  "prompt": {
    "pom": [
      {
        "title": "Personality",
        "body": "You are a helpful assistant.",
        "bullets": ["Be concise", "Be accurate"]
      },
      {
        "title": "Instructions",
        "body": "",
        "bullets": ["Answer questions", "Use tools when needed"],
        "subsections": [
          {"title": "Greeting", "body": "Always start with a greeting."}
        ]
      }
    ]
  }
}
```

When `usePom` is false (raw text mode), the prompt is a simple string:
```json
{"prompt": {"text": "You are a helpful assistant."}}
```

### Dynamic Config Clone Pattern

When `dynamicConfigCallback` is set, each SWML request creates an ephemeral copy:

1. **Shallow-copy** all primitive fields (strings, ints, bools)
2. **Deep-copy** all slices and maps (tools, hints, languages, globalData, pomSections, etc.) — mutations to the copy must not affect the original
3. Call the callback with `(queryParams, bodyParams, headers, ephemeralAgent)`
4. The callback can call any agent method on the copy (add tools, change prompts, etc.)
5. Render SWML from the copy
6. Discard the copy

The original agent is never mutated. This enables multi-tenancy — one agent definition, different config per request.

---

## SwaigFunctionResult

The response builder returned by tool handlers. **Every method returns self for chaining.**

### Serialization Format

```json
{
  "response": "The weather is sunny.",
  "action": [
    {"say": "Let me check that for you."},
    {"set_global_data": {"last_query": "weather"}}
  ],
  "post_process": true
}
```

- `response` — always included
- `action` — only included if non-empty
- `post_process` — only included if true

### Complete Action Methods (41)

**Call Control:**
- `Connect(destination, final, from)` — SWML connect action
- `SwmlTransfer(dest, aiResponse, final)` — transfer_uri action
- `Hangup()` — hangup action
- `Hold(timeout)` — hold with timeout (0-900)
- `WaitForUser(enabled, timeout, answerFirst)` — wait_for_user
- `Stop()` — stop action

**State & Data:**
- `UpdateGlobalData(data)` — set_global_data
- `RemoveGlobalData(keys)` — remove_global_data
- `SetMetadata(data)` / `RemoveMetadata(keys)` — set/remove_meta_data
- `SwmlUserEvent(eventData)` — user_event
- `SwmlChangeStep(stepName)` / `SwmlChangeContext(contextName)` — context_switch
- `SwitchContext(systemPrompt, userPrompt, consolidate, fullReset, isolated)` — context_switch with reset options
- `ReplaceInHistory(text)` — replace_history (string or bool→"summary")

**Media:**
- `Say(text)` — say action
- `PlayBackgroundFile(filename, wait)` — play_background_file or play_background_file_wait
- `StopBackgroundFile()` — stop_background_file
- `RecordCall(controlID, stereo, format, direction)` / `StopRecordCall(controlID)`

**Speech & AI:**
- `AddDynamicHints(hints)` / `ClearDynamicHints()`
- `SetEndOfSpeechTimeout(ms)` / `SetSpeechEventTimeout(ms)`
- `ToggleFunctions(toggles)` / `EnableFunctionsOnTimeout(enabled)`
- `EnableExtensiveData(enabled)`
- `UpdateSettings(settings)` — ai_settings

**Advanced:**
- `ExecuteSwml(swmlContent, transfer)` — SWML or transfer_swml
- `JoinConference(name, muted, beep, holdAudio)` / `JoinRoom(name)`
- `SipRefer(toURI)` / `Tap(uri, controlID, direction, codec)` / `StopTap(controlID)`
- `SendSms(to, from, body, media, tags)`
- `Pay(connectorURL, inputMethod, actionURL, timeout, maxAttempts)`

**RPC:**
- `ExecuteRpc(method, params)` — execute_rpc with jsonrpc 2.0
- `RpcDial(to, from, destSwml, callTimeout, region)`
- `RpcAiMessage(callID, messageText)` / `RpcAiUnhold(callID)`
- `SimulateUserInput(text)` — simulate_user_input

---

## DataMap

Server-side tools that execute on SignalWire's servers — no webhook needed.

Fluent builder API:
```
DataMap("weather")
  .Purpose("Get weather for a location")
  .Parameter("city", "string", "City name", required=True)
  .Webhook("GET", "https://api.weather.com?q=${city}")
  .Output(SwaigFunctionResult("Weather: ${response.conditions}"))
```

Key concepts:
- Variable expansion: `${args.param}`, `${response.field}`, `${global_data.key}`, `${foreach.item}`
- Expression matching: regex patterns against test values
- Foreach: iterate over arrays in response
- Error keys: check for error fields in API response
- `ToSwaigFunction()` serializes to the SWAIG function dict format

---

## Contexts & Steps

Structured conversation workflows with explicit state control (Programmatically Governed Inference).

**Hierarchy:** ContextBuilder → Context(s) → Step(s) → GatherInfo → GatherQuestion(s)

**Key rules:**
- Single context must be named "default"
- Steps have ordered execution within a context
- `SetFunctions("none" | ["func1", "func2"])` restricts which tools are available per step
- `SetValidSteps(["step2", "step3"])` controls navigation
- `SetValidContexts(["sales", "support"])` controls context switching
- `SetStepCriteria("description of when to advance")` gates progression
- GatherInfo collects typed data with confirmation

**Reserved native tool names:** `next_step`, `change_context`, `gather_submit` — the runtime auto-injects these when contexts/steps are present. `ContextBuilder.validate()` must reject any agent that registers a SWAIG tool with one of these names.

**Internal filler names:** Only these names are recognized by the SWML runtime for internal fillers: `hangup`, `check_time`, `wait_for_user`, `wait_seconds`, `adjust_response_latency`, `next_step`, `change_context`, `get_visual_input`, `get_ideal_strategy`. Warn (don't error) when `set_internal_fillers`/`add_internal_filler` receives an unknown name — the runtime silently ignores unrecognized filler names.

**Tool descriptions are LLM-facing:** SWAIG function descriptions and parameter descriptions are fed directly to the LLM via the tool schema (identical to OpenAI/Anthropic tool calling). They are prompt engineering, not developer notes. Every port's `define_tool` and `DataMap.purpose/description/parameter` should document this prominently. Bad description: "gets weather". Good description: "Get the current weather conditions and forecast for a city. Returns temperature, conditions, and humidity."

**Context.set_initial_step(step_name):** Sets which step a context starts on when entered (both at conversation creation and on `change_context` switches). Defaults to the first step (index 0) when omitted. Emits `initial_step` in `to_dict()` when set. `ContextBuilder.validate()` must reject unknown step names. Use case: skip a greeting step on transfers without removing it from the context.

**ContextBuilder.reset():** Clears all contexts so they can be rebuilt from scratch. Returns self for chaining. `AgentBase.reset_contexts()` is a convenience wrapper. Use case: dynamic config callbacks that need to rebuild contexts for specific requests (e.g., different context flow for transfers vs. new calls).

**Auth password fallback warning:** When no explicit password is provided and no `SWML_BASIC_AUTH_PASSWORD` env var is set, the SDK generates a random password. This is the silent cause of HTTP 401 for external callers. Log a warning (once per agent) explaining the auto-generated password and how to fix it.

---

## Skills System

### SkillBase Interface

Every skill must implement:
- `Name()`, `Description()`, `Version()`
- `RequiredEnvVars()` — list of required environment variables
- `SupportsMultipleInstances()` — can load same skill with different configs
- `Setup() bool` — initialize, validate deps
- `RegisterTools()` — return tool definitions
- `GetHints()` — speech recognition hints
- `GetGlobalData()` — data to merge into agent's global data
- `GetPromptSections()` — prompt sections to inject
- `Cleanup()` — teardown
- `GetParameterSchema()` — config schema for GUI tools
- `GetInstanceKey()` — unique key for this instance

### 18 Built-in Skills (Python ∩ TypeScript)

| Skill | Tool Name | Key Params | Env Vars |
|-------|-----------|------------|----------|
| datetime | get_datetime | timezone | — |
| math | calculate | — | — |
| joke | tell_joke | — | — |
| weather_api | get_weather | api_key, temperature_unit | WEATHER_API_KEY |
| web_search | web_search | api_key, search_engine_id, num_results | GOOGLE_SEARCH_API_KEY, GOOGLE_SEARCH_ENGINE_ID |
| wikipedia_search | search_wikipedia | — | — |
| google_maps | search_places | api_key | GOOGLE_MAPS_API_KEY |
| spider | scrape_url | delay, timeout, max_pages | — |
| datasphere | search_datasphere | space_name, project_id, token, document_id | SIGNALWIRE_PROJECT_ID, SIGNALWIRE_TOKEN, SIGNALWIRE_SPACE_NAME |
| datasphere_serverless | search_datasphere_serverless | (same) | (same) |
| swml_transfer | transfer_call | transfers (map), description | — |
| play_background_file | play_background_file | file_url, tool_name | — |
| api_ninjas_trivia | get_trivia | api_key | API_NINJAS_KEY |
| native_vector_search | search_knowledge | remote_url, index_name | — |
| info_gatherer | submit_answer | questions | — |
| claude_skills | ask_claude | api_key | ANTHROPIC_API_KEY |
| mcp_gateway | (varies) | gateway_url, server_name | — |
| custom_skills | (varies) | tools (list) | — |

### SkillManager Lifecycle

1. Get skill factory from registry
2. Create skill instance with params
3. Check for duplicate instances
4. Validate env vars (`RequiredEnvVars`)
5. Call `Setup()` — must return true
6. Call `RegisterTools()` — register tools with agent
7. Merge `GetHints()` into agent hints
8. Merge `GetGlobalData()` into agent global data
9. Add `GetPromptSections()` to agent prompts

---

## Prefab Agents

5 pre-built patterns extending AgentBase:

1. **InfoGathererAgent** — Sequential question collection with key/value answers
2. **SurveyAgent** — Typed surveys (rating, multiple_choice, yes_no, open_ended) with validation
3. **ReceptionistAgent** — Department routing with call transfer (phone or SWML)
4. **FAQBotAgent** — Keyword-based FAQ matching with optional related suggestions
5. **ConciergeAgent** — Venue concierge with amenity info and availability checking

---

## AgentServer

Multi-agent hosting on a single HTTP server:
- `Register(agent, route)` / `Unregister(route)`
- Route-based dispatch to the correct agent
- Central SIP routing (map SIP usernames to agent routes)
- Static file serving
- Health/readiness endpoints
- `Run()` with environment auto-detection

---

## RELAY Client

Real-time call control over WebSocket using the Blade protocol (JSON-RPC 2.0).

> **The complete RELAY wire protocol reference is in `RELAY_IMPLEMENTATION_GUIDE.md`** in this porting-sdk repo (do NOT copy it into language repos). What follows is the full content of that guide inlined here so this porting guide is self-contained.

### Protocol Overview

RELAY uses JSON-RPC 2.0 over WebSocket. The server is at `wss://<host>` (no path). All communication is async — you send requests, get responses matched by `id`, and receive server-pushed events via `signalwire.event`.

### Authentication

```json
{
  "jsonrpc": "2.0",
  "id": "<uuid>",
  "method": "signalwire.connect",
  "params": {
    "version": {"major": 2, "minor": 0, "revision": 0},
    "agent": "your-sdk-name/1.0",
    "event_acks": true,
    "authentication": {"project": "<project_id>", "token": "<token>"},
    "contexts": ["office", "support"]
  }
}
```

The response contains a `protocol` string — save it and send it back on reconnect to resume the session.

### Four Correlation Mechanisms

Every method uses one or more of these to bind requests to responses and events. **Getting these wrong is the #1 source of bugs.**

#### 1. JSON-RPC `id` (ALL methods)

Every request has a UUID `id`. The server responds with the same `id`. This is how you match RPC responses to pending requests.

```
Client → {"jsonrpc":"2.0", "id":"abc-123", "method":"calling.answer", "params":{...}}
Server → {"jsonrpc":"2.0", "id":"abc-123", "result":{"code":"200", "message":"Answered"}}
```

Implementation: maintain a `pending: Map<string, Future>` keyed by request `id`.

#### 2. `call_id` routing (all call-level methods)

Every call method sends `node_id` + `call_id` in params. Events come back with `call_id` in their params. Route events to the correct Call object by `call_id`.

```
Client → {"method":"calling.play", "params":{"node_id":"n1", "call_id":"c1", "control_id":"ctl1", ...}}
Server event → {"method":"signalwire.event", "params":{"event_type":"calling.call.play", "params":{"call_id":"c1", "control_id":"ctl1", "state":"finished"}}}
```

Implementation: maintain a `calls: Map<string, Call>` keyed by `call_id`.

#### 3. `control_id` action tracking (12 methods)

Methods that start long-running operations (play, record, detect, etc.) take a client-generated `control_id`. The server echoes it back in events. Multiple actions can run concurrently on the same call — `control_id` disambiguates.

Implementation: each Call maintains `actions: Map<string, Action>` keyed by `control_id`.

#### 4. `tag` correlation (dial only)

**CRITICAL**: `calling.dial` is the only method where the RPC response does NOT contain a `call_id`. The response is just `{"code":"200", "message":"Dialing"}`. The real `call_id` and `node_id` arrive asynchronously via events matched by `tag`.

Implementation: maintain `pending_dials: Map<string, Future<Call>>` keyed by `tag`.

### Method Categories

#### Simple fire-and-response (no async tracking)

These methods send an RPC, get a response with `code`/`message`, and are done. No control_id, no ongoing events to track.

| Method | RPC | Response |
|--------|-----|----------|
| `answer` | `calling.answer` | `{"code":"200", "message":"Answered"}` |
| `end` | `calling.end` | `{"code":"200", "message":"Disconnecting call"}` |
| `pass` | `calling.pass` | `{"code":"200", "message":"Passing call"}` |
| `connect` | `calling.connect` | `{"code":"200", "message":"connecting"}` |
| `disconnect` | `calling.disconnect` | `{"code":"200", "message":"Disconnecting"}` |
| `hold` | `calling.hold` | `{"code":"200", "message":"Call on hold"}` |
| `unhold` | `calling.unhold` | `{"code":"200", "message":"Call off hold"}` |
| `denoise` | `calling.denoise` | `{"code":"200", "message":"Denoiser on"}` |
| `denoise.stop` | `calling.denoise.stop` | `{"code":"200", "message":"Denoiser off"}` |
| `transfer` | `calling.transfer` | `{"code":"200", "message":"Transferring"}` |
| `join_conference` | `calling.join_conference` | `{"code":"200", "message":"Joining conference"}` |
| `leave_conference` | `calling.leave_conference` | `{"code":"200", "message":"Leaving conference"}` |
| `echo` | `calling.echo` | `{"code":"200", "message":"Echo started"}` |
| `bind_digit` | `calling.bind_digit` | `{"code":"200", "message":"Digit binding created"}` |
| `clear_digit_bindings` | `calling.clear_digit_bindings` | `{"code":"200", "message":"Digit bindings cleared"}` |
| `live_transcribe` | `calling.live_transcribe` | `{"code":"200", "message":"Live transcription started"}` |
| `live_translate` | `calling.live_translate` | `{"code":"200", "message":"Live translation started"}` |
| `join_room` | `calling.join_room` | `{"code":"200", "message":"Joining room"}` |
| `leave_room` | `calling.leave_room` | `{"code":"200", "message":"Leaving room"}` |
| `amazon_bedrock` | `calling.amazon_bedrock` | `{"code":"200", "message":"AI started"}` |
| `ai_message` | `calling.ai_message` | `{"code":"200", "message":"Message sent"}` |
| `ai_hold` | `calling.ai_hold` | `{"code":"200", "message":"AI on hold"}` |
| `ai_unhold` | `calling.ai_unhold` | `{"code":"200", "message":"AI resumed"}` |
| `user_event` | `calling.user_event` | `{"code":"200", "message":"Event sent"}` |
| `queue.enter` | `calling.queue.enter` | `{"code":"200", "message":"Entering Queue"}` |
| `queue.leave` | `calling.queue.leave` | `{"code":"200", "message":"Leaving Queue"}` |
| `refer` | `calling.refer` | `{"code":"200", "message":"Starting SIP REFER"}` |
| `send_digits` | `calling.send_digits` | `{"code":"200", "message":"Sending Digits"}` |

Note: `connect`, `refer`, `send_digits` etc. DO produce async events (`calling.call.connect`, `calling.call.refer`, `calling.call.send_digits`) but these route normally by `call_id`. You don't need special tracking — just the standard event dispatch.

#### control_id action methods (require action tracking)

These methods start a long-running operation. The client generates a `control_id` UUID, sends it in the request, and the server echoes it back in all related events. You MUST track these as Action objects to support `stop()`, `pause()`, `resume()`, `wait()`.

**Blocking vs fire-and-forget**: The `await call.play(...)` call only waits for the server to accept the command (the JSON-RPC response). The actual operation runs asynchronously on the server. The user chooses how to handle completion:

1. **Wait inline** (blocking): `await action.wait()` — blocks until the terminal event arrives
2. **Fire and forget** (background): don't call `action.wait()`, continue immediately
3. **Callback** (background + notification): pass `on_completed=callback` to the method. The callback fires when the action reaches a terminal state. Accepts both sync and async functions. Errors in callbacks are caught and logged.

The `on_completed` callback MUST also fire when the call is gone (404/410) — the action is resolved immediately with an empty event so the callback still runs.

| Method | RPC | Event Type | Terminal States |
|--------|-----|------------|-----------------|
| `play` | `calling.play` | `calling.call.play` | `finished`, `error` |
| `record` | `calling.record` | `calling.call.record` | `finished`, `no_input` |
| `detect` | `calling.detect` | `calling.call.detect` | `finished`, `error` |
| `collect` | `calling.collect` | `calling.call.collect` | `finished`, `error`, `no_input`, `no_match` |
| `play_and_collect` | `calling.play_and_collect` | `calling.call.collect` | `finished`, `error`, `no_input`, `no_match` |
| `pay` | `calling.pay` | `calling.call.pay` | `finished`, `error` |
| `send_fax` | `calling.send_fax` | `calling.call.fax` | `finished`, `error` |
| `receive_fax` | `calling.receive_fax` | `calling.call.fax` | `finished`, `error` |
| `tap` | `calling.tap` | `calling.call.tap` | `finished` |
| `stream` | `calling.stream` | `calling.call.stream` | `finished` |
| `transcribe` | `calling.transcribe` | `calling.call.transcribe` | `finished` |
| `ai` | `calling.ai` | N/A (ends on call end or stop) | `finished`, `error` |

Action sub-commands (these reference an existing `control_id`):
- `play.stop`, `play.pause`, `play.resume`, `play.volume`
- `record.stop`, `record.pause`, `record.resume`
- `detect.stop`
- `collect.stop`, `collect.start_input_timers`
- `play_and_collect.stop`, `play_and_collect.volume`
- `pay.stop`
- `send_fax.stop`, `receive_fax.stop`
- `tap.stop`
- `stream.stop`
- `transcribe.stop`
- `ai.stop`

#### play_and_collect gotcha

`play_and_collect` shares one `control_id` across both the play and collect phases. Events arrive as BOTH `calling.call.play` (for play state) and `calling.call.collect` (for collect result). Your CollectAction must filter by event_type — only resolve on `calling.call.collect` events, NOT on `calling.call.play` events with `state: finished` (that just means playback ended, not that input was collected).

#### detect gotcha

`detect` delivers results continuously via `calling.call.detect` events with a `detect` object. A detect action should resolve on the FIRST meaningful result (e.g., `HUMAN`, `MACHINE`, `CED`, digit) OR on terminal states `finished`/`error`. Don't wait only for `finished` — the useful data comes in intermediate events.

#### tag-based methods (dial)

**This is where most implementations break.**

##### calling.dial — the async dance

```
Client → {"method":"calling.dial", "params":{"tag":"my-tag-123", "devices":[[...]]}}
Server → {"result":{"code":"200", "message":"Dialing"}}   ← NO call_id here!
```

After the RPC response, the server sends a sequence of events:

1. **`calling.call.state`** events for each call leg (one per device being dialed):
```json
{"event_type":"calling.call.state", "params":{
  "call_id":"leg-uuid-1", "node_id":"node-uuid", "tag":"my-tag-123",
  "call_state":"created", "device":{...}
}}
```
Then `ringing`, then `answered` or `ended` for each leg.

2. **`calling.call.dial`** event when the dial operation completes:
```json
{"event_type":"calling.call.dial", "params":{
  "node_id":"node-uuid",
  "tag":"my-tag-123",
  "dial_state":"answered",
  "call":{
    "call_id":"winner-uuid",
    "node_id":"node-uuid",
    "tag":"my-tag-123",
    "device":{...},
    "dial_winner": true
  }
}}
```

**CRITICAL DETAILS:**
- The `calling.call.dial` event has NO top-level `call_id` in params. The call info is nested inside `params.call.call_id`.
- `dial_state` values: `dialing` (progress), `answered` (success), `failed` (all legs failed).
- With parallel dialing, multiple call legs are created. Each gets `calling.call.state` events. Only the winner appears in the `calling.call.dial` event with `dial_state: "answered"`. Losers get `calling.call.state` with `call_state: "ended"`.

##### Correct dial() implementation

```python
async def dial(devices, tag=None, timeout=120):
    tag = tag or generate_uuid()

    # 1. Register pending dial BEFORE sending RPC
    future = create_future()
    pending_dials[tag] = future

    # 2. Send the RPC — response is just {"code":"200","message":"Dialing"}
    await execute("calling.dial", {"tag": tag, "devices": devices})

    # 3. Wait for calling.call.dial event to resolve the future
    try:
        call = await wait_for(future, timeout=timeout)
        return call
    finally:
        pending_dials.pop(tag)
```

##### Event routing during dial

Your event handler needs three special cases:

```python
def handle_event(payload):
    event_type = payload["event_type"]
    event_params = payload["params"]
    call_id = event_params.get("call_id", "")

    # 1. Inbound call
    if event_type == "calling.call.receive":
        handle_inbound(payload)
        return

    # 2. Dial completion — call_id is NESTED at params.call.call_id
    if event_type == "calling.call.dial":
        tag = event_params.get("tag", "")
        dial_state = event_params.get("dial_state", "")
        call_info = event_params.get("call", {})
        future = pending_dials.get(tag)
        if future:
            if dial_state == "answered":
                call = find_or_create_call(call_info)
                future.resolve(call)
            elif dial_state == "failed":
                future.reject(Error("Dial failed"))
        return

    # 3. State events during dial — call not registered yet
    if event_type == "calling.call.state":
        tag = event_params.get("tag", "")
        if tag in pending_dials and call_id not in calls:
            # Create the Call object so events route correctly
            register_dial_leg(tag, event_params)
        # Fall through to normal routing

    # 4. Normal routing by call_id
    call = calls.get(call_id)
    if call:
        call.dispatch_event(payload)
        if call.state == "ended":
            calls.pop(call_id)
```

### Event ACK

The server expects an acknowledgment for every `signalwire.event`:
```json
{"jsonrpc":"2.0", "id":"<event_msg_id>", "result":{}}
```
Send this immediately when you receive the event, before processing it.

### Server Pings

The server sends `signalwire.ping` periodically. Respond with:
```json
{"jsonrpc":"2.0", "id":"<ping_msg_id>", "result":{}}
```

### Error Code Handling

The calling API always returns results with `code` and `message`. The code is a STRING, not an integer.

- Any `2xx` code = success
- `404` = call does not exist
- `410` = call existed but is gone
- `409` = conflict (call already connected, controlled by another client)

#### Call-gone handling (404/410)

When a caller hangs up, the server destroys the call. If your client tries to send a command after the caller hung up but before you received the `calling.call.state ended` event, you get a 404 or 410 error. **This is normal telephony flow, not an exceptional condition.**

Handle it gracefully: log it and return an empty result instead of raising an exception.

Also: if an action (play, record, etc.) gets a call-gone response, resolve the action's Future immediately so `action.wait()` doesn't hang forever.

### Event Structure Reference

All events arrive as:
```json
{
  "jsonrpc": "2.0",
  "method": "signalwire.event",
  "id": "<msg_id>",
  "params": {
    "event_type": "calling.call.play",
    "timestamp": 123457.1234,
    "params": {
      "call_id": "...",
      "control_id": "...",
      "state": "finished"
    }
  }
}
```

Note the nested `params.params` structure. The outer `params` has `event_type`, the inner `params` has event-specific data like `call_id`, `control_id`, `state`.

#### Events with non-standard structure

| Event | Gotcha |
|-------|--------|
| `calling.call.dial` | No top-level `call_id`. Has `tag`, `dial_state`, and `call` object containing `call_id`. |
| `calling.conference` | Uses `conference_id` instead of `call_id` for conference-level events. |
| `calling.call.detect` | Results are in `detect.params.event`, not in a `state` field. Terminal state is `finished`. |
| `calling.call.collect` | Result object has `type` (digit/speech/error/no_input/no_match) and `params`. |
| `calling.call.record` | `url`, `duration`, `size` may be at top level OR nested inside `record` object. Check both. |

### Authorization State (Fast Reconnection)

The server sends `signalwire.authorization.state` events containing an encrypted `authorization_state` string. Store this and send it back on reconnect for fast re-auth without a full authentication round-trip.

On reconnect, include `authorization_state` in the `signalwire.connect` params alongside `protocol`. If invalid or expired, the server ignores it and falls back to normal `authentication`.

### Server-Initiated Disconnect

The server sends `signalwire.disconnect` to gracefully shut down connections. The client MUST:

1. Respond with an empty result `{"jsonrpc":"2.0","id":"...","result":{}}`
2. Check the `restart` flag:
   - `restart: false` (or absent) → reconnect normally, reuse `protocol` and `authorization_state`
   - `restart: true` → clear `protocol` and `authorization_state`, reconnect with fresh auth

Do NOT set a "closing" flag — the client should reconnect after the server closes the socket.

### Dynamic Context Subscription

Subscribe/unsubscribe from contexts after connecting:

- `signalwire.receive` — Subscribe: `{"method":"signalwire.receive", "params":{"contexts":["sales","support"]}}`
- `signalwire.unreceive` — Unsubscribe: `{"method":"signalwire.unreceive", "params":{"contexts":["sales"]}}`

These are sent on the assigned protocol, not the signalwire protocol.

### Reconnection

On WebSocket disconnect:
1. Reject all pending request Futures
2. Reject all pending dial Futures
3. Wait with exponential backoff (1s → 2s → 4s → ... → 30s max)
4. Reconnect and re-authenticate with `signalwire.connect`, sending `protocol` + `authorization_state`
5. Unless `signalwire.disconnect` with `restart: true` was received — then connect fresh
6. Flush any queued requests

Call objects survive reconnect — the server tracks them by `call_id` across connections.

### Media Objects (reused across methods)

```
audio:    { type: "audio",    params: { url: "https://..." } }
tts:      { type: "tts",      params: { text: "...", language?: "en-US", gender?: "male"|"female", voice?: "..." } }
silence:  { type: "silence",  params: { duration: <seconds> } }
ringtone: { type: "ringtone", params: { name: "<country-code>", duration?: <seconds> } }
```

Ringtone country codes: `at au bg br be ch cl cn cz de dk ee es fi fr gr hu il in it lt jp mx my nl no nz ph pl pt ru se sg th uk us tw ve za`

### Device Objects (reused across dial/connect)

```
phone:  { type: "phone",  params: { from_number: "+1...", to_number: "+1...", timeout?: 30, max_duration?: <sec> } }
sip:    { type: "sip",    params: { from: "sip:...", to: "sip:...", headers?: [{name,value}], codecs?: [...] } }
webrtc: { type: "webrtc", params: { from: "+1...", to: "resource-name", timeout?: 30 } }
agora:  { type: "agora",  params: { from: "+1...", appid: "...", channel: "..." } }
call:   { type: "call",   params: { node_id: "...", call_id: "..." } }        // connect only
queue:  { type: "queue",  params: { queue_name: "...", queue_id?: "..." } }    // connect only
```

### Collect Object (reused in collect and play_and_collect)

```json
{
  "initial_timeout": 4.0,
  "digits": { "max": 4, "terminators": "#*", "digit_timeout": 5.0 },
  "speech": { "end_silence_timeout": 1.0, "speech_timeout": 60.0, "language": "en-US", "hints": ["word1"], "engine": "Deepgram" }
}
```

### Architecture Checklist

- [ ] `pending` map: request `id` → Future (for RPC response matching)
- [ ] `calls` map: `call_id` → Call (for event routing)
- [ ] Each Call has `actions` map: `control_id` → Action (for action event routing)
- [ ] `pending_dials` map: `tag` → Future<Call> (for dial event matching)
- [ ] `authorization_state` stored from events and sent on reconnect
- [ ] Event ACK sent for every `signalwire.event`
- [ ] Pong sent for every `signalwire.ping`
- [ ] `signalwire.disconnect` handled: respond, check `restart` flag, reconnect
- [ ] `signalwire.receive`/`signalwire.unreceive` for dynamic context management
- [ ] 404/410 errors handled gracefully (call-gone, not exceptional)
- [ ] `calling.call.dial` events routed by `tag`, not `call_id`
- [ ] `calling.call.state` events during dial create Call objects before dial completes
- [ ] `play_and_collect` CollectAction filters by event_type, ignores play events
- [ ] Auto-reconnect with exponential backoff
- [ ] All pending futures cleaned up on disconnect
- [ ] Actions support three completion patterns: wait (blocking), fire-and-forget, on_completed callback
- [ ] `on_completed` callback supports both sync and async functions, errors caught and logged
- [ ] `on_completed` fires on call-gone (404/410) with resolved empty event
- [ ] `messages` map: `message_id` → Message (for messaging.state routing)
- [ ] `on_message` handler for inbound SMS/MMS
- [ ] `send_message()` returns Message, tracks by `message_id`, supports `on_completed`

### Action Objects

All action methods return Action objects with:
- `Wait()` — block until terminal state
- `Stop()` — stop operation on server
- `IsDone()` / `Completed()` — check status
- `Result()` — terminal event
- `onCompleted` callback support

PlayAction additionally: `Pause()`, `Resume()`, `Volume(dB)`

### Messaging (SMS/MMS)

```
client.SendMessage(to, from, body, media, context, tags)
```

States: queued → initiated → sent → delivered (or undelivered/failed)
Inbound: received via `on_message` handler

---

## REST Client

Synchronous HTTP client for the SignalWire REST API.

### Base Pattern

- Basic Auth with project_id:token
- Base URL: `https://{space}`
- All responses are JSON (return raw maps/dicts, no wrapper objects)
- 204 No Content → return empty map/dict
- Non-2xx → throw SignalWireRestError

### CrudResource Pattern

Generic CRUD with: `List(params)`, `Create(data)`, `Get(id)`, `Update(id, data)`, `Delete(id)`
Pagination via iterator/generator.

### 18+ Namespaces

Fabric (13 sub-resources), Calling (37 command methods), PhoneNumbers, Datasphere, Video, Compat (Twilio LAML), Addresses, Queues, Recordings, NumberGroups, VerifiedCallers, SipProfile, Lookup, ShortCodes, ImportedNumbers, MFA, Registry, Logs, Project, PubSub, Chat.

---

## Security

Security must be correct from the start — not bolted on later. Every port must implement these requirements.

### Basic Auth
- Auto-generated credentials if not explicitly set
- `SWML_BASIC_AUTH_USER` / `SWML_BASIC_AUTH_PASSWORD` env vars
- Username defaults to agent name
- **CRITICAL: Use timing-safe comparison** for both username and password (e.g., `crypto/subtle.ConstantTimeCompare` in Go, `crypto.timingSafeEqual` in Node, `hmac.compare_digest` in Python). Standard `==` is vulnerable to timing attacks.
- **Never log passwords.** Log the username only. If you must confirm auth is configured, log `auth user: <name>` — never the password.
- **Never fall back to weak passwords.** If the system entropy source fails and you can't generate a random password, the service must refuse to start. Do not fall back to a hardcoded default like "changeme".

### Tool Tokens (SessionManager)
- HMAC-SHA256 signed tokens for secure SWAIG tools
- Token format: `base64(functionName:callID:expiryTimestamp + "." + hex(hmac_signature))`
- **Timing-safe comparison** for signature validation (use constant-time compare, not `==`)
- Token scoped to: function name, call ID, expiry timestamp
- Default expiry: 3600 seconds
- 32-byte random secret generated per SessionManager instance via `crypto/rand`

### Webhook Request Validation
- All ports MUST expose `validateWebhookSignature(signingKey, signature, url, rawBody) → bool`
- All ports MUST support **both** SignalWire signing schemes:
  - **RELAY/JSON** — hex HMAC-SHA1 of `url + rawBody`
  - **Compat/cXML** — base64 HMAC-SHA1 of `url + sortedFormParams`, with optional `bodySHA256` body-hash via URL query
- **Timing-safe comparison** required (never `==` on the digest)
- **Raw body must be captured before framework parsing** — the JSON scheme breaks under parse-and-reserialize
- **URL port normalization**: try the URL both with and without the standard port (`:443`/`:80`) for the compat scheme
- Ship a framework adapter (middleware / decorator) for the language's dominant HTTP stack that captures raw body, validates, returns 403 on failure, and forwards the cached body to downstream handlers
- `AgentBase` MUST accept a `signingKey` option (with `SIGNALWIRE_SIGNING_KEY` env fallback) and auto-mount the middleware on `/`, `/swaig`, `/post_prompt`
- Expose a `validateRequest` compat alias matching `@signalwire/compatibility-api`'s legacy signature for drop-in migrations
- Full algorithm, test vectors, per-language signatures, and required test cases: see [webhooks.md](./webhooks.md)

### HTTP Security Headers
Every HTTP response (except health checks) must include:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Cache-Control: no-store`

### Request Body Size Limits
- **All HTTP handlers must limit request body size** (e.g., 1MB) to prevent DoS via oversized payloads
- Use `http.MaxBytesReader` (Go), express body-parser limits (Node), or equivalent
- Return 413 or 400 if exceeded

### Input Validation
- **SIP username extraction:** Validate format — only allow `[a-zA-Z0-9._-]`, max 64 chars. Do not pass raw user input into SIP headers.
- **SWAIG function dispatch:** Validate that the requested function name exists in the tool registry before executing. Never execute arbitrary function names.
- **JSON parsing:** Always check for parse errors. Do not silently ignore malformed input.

### Concurrency Safety
- All shared state (global data, tool registry, correlation maps) must be protected by mutexes or equivalent
- RELAY client maps (`pending`, `calls`, `pendingDials`, `actions`) must be thread-safe
- Use `RWMutex` or equivalent for read-heavy access patterns

### Webhook URL Credentials
- SignalWire requires auth credentials in webhook URLs (platform limitation) — this is expected
- The URL format is: `https://user:pass@host:port/route/swaig`
- These URLs are sent to the SignalWire platform over HTTPS, not exposed to end users

---

## Serverless Support

### Step 0 — Check language support first

Before implementing, determine which serverless platforms the target language has first-class runtime support for. This drives what is **required** vs **optional** for your port.

| Platform | First-class runtimes (required if language matches) | Custom runtime only (optional) |
|---|---|---|
| AWS Lambda | Python, Node.js/TypeScript, Java, Ruby, Go, .NET | C++, Perl, Rust, others (via Lambda Runtime API) |
| Google Cloud Functions | Python, Node.js, Java, Ruby, Go, .NET, PHP | Others (via Cloud Run custom container) |
| Azure Functions | Python, Node.js, Java, PowerShell, .NET | Others (via custom handler) |
| CGI | Any — trivial stdin/stdout | — |

**Rule:** if the target language is in the first-class column for a platform, implementing that platform is **required**. Don't skip it on convenience grounds — it's a deployment path users will actually take. If custom-runtime only, it's optional and usually not worth shipping until there's demand.

### Step 1 — Execution-mode detection

Add a language-idiomatic enum/const plus a detector function. Read env vars only; never touch files or make network calls for detection.

| Mode | Detection (OR'd) |
|---|---|
| `cgi` | `GATEWAY_INTERFACE` present |
| `lambda` | `AWS_LAMBDA_FUNCTION_NAME` OR `LAMBDA_TASK_ROOT` present |
| `google_cloud_function` | `FUNCTION_TARGET` OR `K_SERVICE` OR `GOOGLE_CLOUD_PROJECT` present |
| `azure_function` | `WEBSITE_SITE_NAME` OR `AZURE_FUNCTIONS_APP_NAME` present |
| `server` | default (none of the above) |

Check in the order above — Lambda before GCF before Azure — because some env vars can overlap in testing harnesses.

### Step 2 — Base URL construction per mode

Your agent needs to emit webhook URLs that SignalWire can call back. The base URL depends on mode. **`SWML_PROXY_URL_BASE` env var, when set, takes precedence over all mode-specific logic.**

| Mode | Base URL algorithm |
|---|---|
| `server` | `{scheme}://{host}:{port}` from agent config |
| `cgi` | `{HTTPS==on ? https : http}://{HTTP_HOST or SERVER_NAME}{SCRIPT_NAME}` |
| `lambda` | `AWS_LAMBDA_FUNCTION_URL` if set, else `https://{AWS_LAMBDA_FUNCTION_NAME}.lambda-url.{AWS_REGION}.on.aws` |
| `google_cloud_function` | `https://{FUNCTION_REGION or GOOGLE_CLOUD_REGION}-{GOOGLE_CLOUD_PROJECT or GCP_PROJECT}.cloudfunctions.net/{K_SERVICE or FUNCTION_TARGET}` |
| `azure_function` | `https://{WEBSITE_SITE_NAME or AZURE_FUNCTIONS_APP_NAME}.azurewebsites.net/api/{AZURE_FUNCTION_NAME}` |

### Step 3 — CRITICAL invariant: the route must always be appended

**This is the single most important rule in serverless support. A production bug hit both Python and TypeScript because of it.**

The agent's mount route (e.g. `/my-agent`) must appear between the base URL and the endpoint suffix:

```
{base_url}{route}/swaig   ✓
{base_url}/swaig          ✗ BUG: route dropped
```

The common failure mode: your `get_full_url()` or equivalent returns a "base URL" that silently includes the route in the server/non-proxy branch but **not** in the proxy/serverless branches. Callers that do `{get_full_url()}/{endpoint}` then drop the route whenever proxy or serverless is active. The fix is symmetry: every branch that returns a "full URL" must include the route, OR keep the base strictly bare and make the single webhook builder responsible for concatenating `route + endpoint`. **Pick one discipline and enforce it in every branch.**

Real example of the buggy pattern (avoid):
```python
def get_full_url(self):
    if self._proxy_url_base:
        return self._proxy_url_base   # ← bug: no route
    return f"{scheme}://{host}:{port}{self.route}"
```

Good patterns:
- **A)** Every branch of `get_full_url` appends `route`.
- **B)** `get_full_url` always returns a bare base (no route); the single `build_webhook_url` does `base + route + "/" + endpoint`.

Go SDK's `pkg/swml/service.go` uses pattern (A) plus a defensive `HasSuffix(url, route)` re-check in the webhook builder — that belt-and-suspenders approach is worth copying.

### Step 4 — Handler adapter

Once URL construction is correct, wire up the actual serverless entry point. The platform invokes your handler with a platform-specific event shape; translate it into a request your agent's HTTP handler already understands, then translate the response back.

| Language | Lambda | GCF | Azure |
|---|---|---|---|
| Python | Mangum (ASGI) or raw Lambda handler | functions-framework | azure-functions |
| Node.js/TS | `@vendia/serverless-express` or Function URL native | `@google-cloud/functions-framework` | `@azure/functions` |
| Java | `aws-lambda-java-core` + API Gateway event types | Functions Framework for Java | azure-functions-java-library |
| Ruby | Native Lambda Ruby runtime (`handler(event:, context:)`) + Rack adapter | functions_framework gem | — |
| Go | `aws-lambda-go` + `aws-lambda-go-api-proxy` or Function URL native | `functions-framework-go` | — |
| .NET | `Amazon.Lambda.AspNetCoreServer` | Functions Framework for .NET | Microsoft.Azure.Functions.Worker |

The adapter should be a thin translation layer — it should NOT reimplement routing, auth, or SWML rendering.

### Step 5 — Required tests

These are non-negotiable even when "everything looks fine." Every prior port has had at least one subtle bug caught by exactly these tests.

1. **Execution-mode detection** — set each env var combination, assert mode.
2. **Base URL construction per mode** — with and without `AWS_LAMBDA_FUNCTION_URL` (and GCF/Azure equivalents).
3. **Precedence** — assert `SWML_PROXY_URL_BASE` beats every serverless env var.
4. **🔥 Route-preservation regression** — construct a webhook URL for an agent mounted at a non-root route (e.g. `/my-agent`) while BOTH a serverless env var AND `SWML_PROXY_URL_BASE` are set. Assert the URL contains `/my-agent/swaig`. This is the test that would have caught the Python+TypeScript bug before it shipped.
5. **Handler adapter smoke test** — feed a synthetic API Gateway / Function URL / GCF / Azure event into the adapter, assert status=200 and body shape.

### Step 6 — Example

Add an example per implemented platform (`examples/lambda_agent.*`, etc.) showing the minimal deployment boilerplate. The example is how users discover the feature exists.

---

## CLI Tools

### swaig-test

```bash
swaig-test agent_file --list-tools          # List all tools
swaig-test agent_file --exec tool_name      # Execute a tool
swaig-test agent_file --dump-swml           # Dump SWML document
swaig-test agent_file --simulate-serverless lambda
swaig-test agent_file --simulate-serverless lambda --dump-swml
swaig-test agent_file --simulate-serverless lambda --exec my_tool
```

Requires: agent discovery from source files, dynamic loading.

### Tool discovery: in-process introspection (NOT URL walking)

`--list-tools` MUST list tools by introspecting the in-memory tool registry of the loaded `SWMLService` (or `AgentBase`) instance. It MUST NOT work by hitting `/swaig` over HTTP and walking `<ai>.SWAIG.functions[]` in the rendered SWML doc — that path only finds tools attached to an `<ai>` verb, so it returns nothing for a non-AgentBase service that has tools registered but no `<ai>` block (e.g. an `ai_sidecar` host or a SWAIG-only service). Tools live in the runtime registry, so the registry is what gets walked.

Per-language implementation:

| Language | How `--list-tools` loads the script and reads the registry |
|---|---|
| Python / Ruby / Perl / PHP | `--file PATH` (or positional path). CLI requires/loads/dos the file in-process, scans for `SWMLService` subclasses (or finds the instance the file built), and walks the runtime tool registry directly. No subprocess. |
| TypeScript | `--file PATH`. Dynamic `import()` (via tsx for `.ts`); same in-process walk. |
| Java | `--class FQCN`. CLI uses `Class.forName(...)` + reflection; the SDK exposes `Service.getRegisteredTools()` / `getRegisteredSwaigFunctions()` accessors so the CLI doesn't need package-private access. |
| .NET | `--assembly PATH --class FQTYPE`. CLI does `Assembly.LoadFrom(...)` + reflection; the SDK exposes a public `Tools` accessor on `Service`. |
| Rust / Go / C++ | `--example NAME`. CLI spawns the example binary (`cargo run --example NAME`, `go run ./examples/NAME`, `build/example_NAME`) with `SWAIG_LIST_TOOLS=1` set in the child env. The SDK's `Service::run()` / `Service::Serve()` / `Service::serve()` checks that env var at entry, dumps the runtime tool registry to stdout between sentinel markers, and exits 0 *before* binding any port. CLI captures stdout, slices between markers, parses, displays. |

**Compiled-language introspect contract (Rust / Go / C++ — every port that emits a binary):**

1. The very first thing in the SDK's HTTP-server entry point (`run`/`Serve`/`serve`) MUST be:
   ```
   if env(SWAIG_LIST_TOOLS) is set:
       print "__SWAIG_TOOLS_BEGIN__"
       print json.dumps({"tools": [<each tool's native definition>]})
       print "__SWAIG_TOOLS_END__"
       exit(0)
   ```
2. The dump runs *after* user code populated the registry (define_tool, register_swaig_function, skill loading, dynamic config) but *before* any port is bound. This captures the registry as-actually-built.
3. The payload is `{"tools": [<each tool's definition object>]}`. Pass through whatever shape each tool natively stores — don't normalize. The CLI side must accept either `function|name`, `description|purpose`, `parameters|argument` so per-port differences don't break consumers.
4. Sentinel markers are exactly `__SWAIG_TOOLS_BEGIN__` and `__SWAIG_TOOLS_END__` (each on its own line). The CLI uses these to slice past any user log noise printed before serve() was called.
5. Expose a testable helper that returns the JSON string (e.g., `Service::build_tool_registry_json()`), separate from the path that prints + exits, so tests can assert the payload without invoking `exit()`.

**Hard rules:**
- `--list-tools` against a SWMLService-only example with no `<ai>` verb MUST return the registered tools, not "No tools found."
- The introspect path MUST NOT make any HTTP request, MUST NOT bind any port, and MUST NOT depend on a remote service being reachable.
- The compiled-language introspect path MUST NOT define a new `/swaig` action, route, or wire format. It uses env-var + sentinels in stdout, full stop.

**Required tests per port:**
- Building the runtime registry returns the expected shape with the expected names in registration order (testable helper, no exit).
- Loading an example (file/class/binary) and invoking `--list-tools` lists at least one tool. Use the new `swmlservice_swaig_standalone.*` and `swmlservice_ai_sidecar.*` examples as the fixtures.
- Sentinel extractor (compiled langs only): happy path, both markers missing, and partial markers (begin only / end only) — all return empty/None.

### `--simulate-serverless` — conditional on Phase 9

The accepted values for `--simulate-serverless` are exactly the platforms your port implemented in Phase 9. If your port doesn't ship Lambda support, don't accept `lambda` here — fail with a clear error instead of silently running the server path.

**What the flag must do** (mirrors Python's `signalwire/cli/simulation/mock_env.py`):

1. **Set the mode-detection env vars** for the requested platform so `get_execution_mode()` returns the right value for the duration of the invocation. E.g. for `lambda`: set `AWS_LAMBDA_FUNCTION_NAME`, `LAMBDA_TASK_ROOT`, `AWS_REGION` (and optionally `AWS_LAMBDA_FUNCTION_URL`).
2. **Clear conflicting env vars** — most importantly `SWML_PROXY_URL_BASE` — so platform-specific URL generation is actually exercised. Python warns if `SWML_PROXY_URL_BASE` is still set after clearing; ports should do the same.
3. **Load the agent** as usual.
4. **Route the invocation through the serverless adapter** from Phase 9, not the HTTP server. If you invoke the HTTP server with Lambda env vars set, you're only testing URL generation — not the adapter that will actually run in production.
5. **Restore env vars on exit** (whether success, error, or interrupt). Otherwise a later simulation or a test in the same process inherits leaked state.

**Combinations:**
- `--simulate-serverless <p> --dump-swml` — dump the SWML an agent would emit from within that platform (webhook URLs should come out with platform-appropriate base + route).
- `--simulate-serverless <p> --exec <tool> --param k=v` — dispatch a SWAIG function through the serverless adapter's code path.
- `--simulate-serverless <p>` without a sub-action — render SWML and exit.

**Tests required:**
- Env vars are set during invocation and restored after (both success and error paths).
- An agent with `SWML_PROXY_URL_BASE` set in the outer shell but simulated as `lambda` must produce a Lambda-style URL — proving the mock cleared the env var.
- Running with a platform the port didn't implement in Phase 9 surfaces a clear error, not a silent fallback.

---

## What to Skip

- **Search/RAG system** — Requires vector models and sentence-transformers. No good cross-language equivalent. The `native_vector_search` skill should support network mode only.
- **pgvector backend** — Depends on search system.
- **sw-search CLI** — Depends on search system.
- **BedrockAgent** — Niche; add later if needed.

---

## Language-Specific Patterns

### Python → Other Languages

| Python Pattern | Go Equivalent | TypeScript Equivalent |
|---|---|---|
| `@AgentBase.tool()` decorator | `agent.DefineTool(ToolDefinition{...})` | `agent.defineTool({...})` |
| Mixin inheritance (8 mixins) | Struct composition | Class composition |
| `**kwargs` for verb methods | `map[string]any` | `Record<string, unknown>` |
| `types.MethodType` auto-vivify | Explicit methods per verb | Generated methods |
| `asyncio` | goroutines + channels | async/await + Promises |
| `threading.Lock` | `sync.RWMutex` | N/A (single-threaded) |
| `setattr()` dynamic methods | Not available; use explicit | Not needed |
| Method chaining via `return self` | `return *AgentBase` pointer | `return this` |

### Language-Specific Patterns (Extended)

The table above covers Go and TypeScript. Here are the remaining languages ported so far:

| Python Pattern | PHP | Ruby | Perl | Java | C++ | C# (.NET) | Rust |
|---|---|---|---|---|---|---|---|
| `@AgentBase.tool()` decorator | `$agent->defineTool(...)` closure | `agent.define_tool(...) do` block | `$agent->define_tool(handler => sub {...})` | `agent.defineTool(name, desc, params, lambda)` | `define_tool({.handler = [](...){}})` designated init | `agent.DefineTool(name, desc, params, Func)` | `agent.define_tool(ToolDefinition { handler: \|args, raw\| { ... }, ..Default::default() })` builder |
| Mixin inheritance | Single class | Single class | Moo roles | Single class | Class inheritance | Single class | Single struct + traits |
| `**kwargs` verb methods | `__call()` magic | `method_missing` | `AUTOLOAD` | Explicit methods | Explicit methods | `Verb()` method | Explicit methods (or proc-macro generated) |
| `asyncio` | N/A (sync/blocking) | N/A (sync/blocking) | N/A (sync/blocking) | CompletableFuture | std::async/future | async/await + Task | tokio async/await |
| `threading.Lock` | N/A (single-threaded) | Mutex | N/A (single-threaded) | synchronized/ReentrantLock | std::mutex | lock/SemaphoreSlim | `tokio::sync::Mutex` / `parking_lot::Mutex` |
| Method chaining | `return $this` | `return self` | `return $self` | `return this` | `return *this` | `return this` | `&mut self -> &mut Self` |

### Timing-Safe Comparison by Language

Every port must use constant-time comparison for auth and HMAC validation. The function differs per language:

| Language | Function |
|----------|----------|
| Python | `hmac.compare_digest(a, b)` |
| Go | `crypto/subtle.ConstantTimeCompare(a, b)` |
| TypeScript | `crypto.timingSafeEqual(a, b)` |
| PHP | `hash_equals(a, b)` |
| Ruby | `OpenSSL.fixed_length_secure_compare(a, b)` or Rack `secure_compare` |
| Perl | HMAC-based comparison (compute HMAC of both, compare digests) |
| Java | `MessageDigest.isEqual(a, b)` |
| C++ | Custom constant-time loop or OpenSSL `CRYPTO_memcmp` |
| C# | `CryptographicOperations.FixedTimeEquals(a, b)` |
| Rust | `subtle::ConstantTimeEq::ct_eq(a, b)` (or `ring::constant_time::verify_slices_are_equal`) |

### Secure Random by Language

Every port must use cryptographic random for auth passwords and HMAC secrets. **Never fall back to weak RNG.**

| Language | Function |
|----------|----------|
| Python | `os.urandom(n)` or `secrets.token_hex(n)` |
| Go | `crypto/rand.Read(buf)` |
| TypeScript | `crypto.randomBytes(n)` |
| PHP | `random_bytes(n)` (throws on failure) |
| Ruby | `SecureRandom.hex(n)` |
| Perl | Read from `/dev/urandom` or `Crypt::URandom` |
| Java | `SecureRandom().nextBytes(buf)` |
| C++ | `std::random_device` or `/dev/urandom` |
| C# | `RandomNumberGenerator.Fill(buf)` |
| Rust | `rand::rngs::OsRng.fill_bytes(buf)` (or `getrandom::getrandom(buf)`) |

### Verb Auto-Vivification by Language

The 38 SWML verbs must be dynamically callable. Each language uses different mechanisms:

| Language | Mechanism |
|----------|-----------|
| Python | `setattr()` / `types.MethodType` |
| Go | Explicit `Verb()` method (no dynamic dispatch) |
| TypeScript | Generated methods at class definition |
| PHP | `__call()` magic method |
| Ruby | `method_missing` |
| Perl | `AUTOLOAD` |
| Java | Explicit `verb()` method |
| C++ | Explicit `verb()` method |
| C# | Explicit `Verb()` / `Sleep()` methods |
| Rust | Explicit `verb()` method (or proc-macro generated at compile time) |

### Async Patterns

- **RELAY WebSocket read loop**: goroutine (Go), asyncio.Task (Python), setInterval/events (TS), ReactPHP/polling (PHP), EventMachine (Ruby), AnyEvent (Perl), CompletableFuture (Java), std::async (C++), async/await Task (C#), `tokio::spawn` + tokio-tungstenite (Rust)
- **Action.Wait()**: channel receive (Go), asyncio.Future (Python), Promise (TS), polling loop (PHP), blocking (Ruby/Perl), CompletableFuture.get (Java), future.get (C++), TaskCompletionSource (C#), `tokio::sync::oneshot` (Rust)
- **Concurrent correlation**: sync.Map or mutex (Go), asyncio.Lock (Python), Map (TS, single-threaded), N/A (PHP, single-threaded), Mutex (Ruby), N/A (Perl, single-threaded), ConcurrentHashMap (Java), std::mutex (C++), ConcurrentDictionary or lock (C#), `tokio::sync::Mutex<HashMap>` or `dashmap` (Rust)

### Package Naming Convention

All SDKs use just the platform/language name — NOT "agents":

| Language | Package Name | Registry |
|----------|-------------|----------|
| Python | `signalwire` | PyPI |
| TypeScript | `@signalwire/sdk` | npm |
| Go | `github.com/signalwire/signalwire-go` | Go modules |
| PHP | `signalwire/sdk` | Packagist |
| Ruby | `signalwire` | RubyGems |
| Perl | `SignalWire` | CPAN |
| Java | `com.signalwire:signalwire-sdk` | Maven Central |
| C++ | `signalwire` (CMake) | — |
| C# | `SignalWire.Sdk` | NuGet |
| Rust | `signalwire` | crates.io |

### README Structure

Every SDK's top-level README must cover the **full SDK scope**, not just agents:
1. Title: "SignalWire SDK for {Language}"
2. One-line description covering all three capabilities
3. "What's in this SDK" table: AI Agents, RELAY Client, REST Client
4. Install command
5. AI Agents section (primary, with code example)
6. RELAY Client section (with code example, link to relay/README.md)
7. REST Client section (with code example, link to rest/README.md)
8. Environment variables with "Used by" column
9. Testing, License

---

## Common Pitfalls Found During Porting

These issues were discovered across multiple ports. Check for them in yours:

### 1. Test Environment Variable Isolation
Tests that mutate env vars (`SIGNALWIRE_LOG_LEVEL`, `SWML_BASIC_AUTH_USER`, etc.) can leak between tests when run in parallel. **Fix**: disable test parallelism or use per-test setup/teardown that resets env vars and singleton state.

### 2. JSON Deserialization Type Mismatches
When deserializing JSON to `Dictionary<string, object>`, values may come back as the language's JSON element type (e.g., `JsonElement` in C#, `JsonNode` in Java) rather than native strings/ints. The `ExtractSipUsername` and `HandleSwaigRequest` methods must handle both native types and JSON element types.

### 3. AgentServer Sub-Path Routing
When `AgentServer` dispatches `/bot/swaig` to an agent registered at `/bot`, the agent must receive the **full path** `/bot/swaig` — not the stripped sub-path `/swaig`. The agent's own `HandleRequest` already handles sub-path matching against its route.

### 4. Never Hardcode Test Environment Paths
Tests must never contain hardcoded paths like `/home/devuser/...` or Docker-specific paths. Use language-native constants (PHP: `PHP_BINARY`, C#: `Assembly.GetExecutingAssembly().Location`, etc.).

### 5. Embedded Resource Loading
The `schema.json` file must be embedded in the package — not loaded from a relative file path. This ensures it works in all deployment scenarios (installed packages, Docker, serverless, etc.).

| Language | Embedding Mechanism |
|----------|-------------------|
| Go | `embed.FS` |
| TypeScript | `import` or bundled |
| PHP | `__DIR__ . '/schema.json'` (relative to source file) |
| Ruby | `File.read(File.join(__dir__, 'schema.json'))` |
| Perl | `File::ShareDir` or `__FILE__` relative |
| Java | `getClass().getResourceAsStream("/schema.json")` |
| C++ | `#include` as string literal or CMake embed |
| C# | `Assembly.GetManifestResourceStream()` with `<EmbeddedResource>` in csproj |

---

## Testing Strategy

Tests are **proof of implementation**. If a feature has no test, it's not proven to work. The requirement is to match the Python SDK's test coverage — not a minimum count, but **100% of what Python tests** (excluding search).

### Requirements
- **Every public method tested** — if Python tests it, your port tests it
- **No live API calls in unit tests** — mock HTTP, mock WebSocket
- **All tests must pass with zero failures** before each git commit
- **Read the Python test files** in `tests/unit/` and create equivalent tests for every tested behavior

### Python Test Structure to Match

The Python SDK has tests organized by component. Your port must have equivalent tests for each:

```
tests/unit/core/
  test_agent_base.py          — AgentBase init, prompt, config, rendering
  test_agent_server.py        — multi-agent routing, registration, SIP
  test_swml_service.py        — SWML document generation
  test_swml_builder.py        — SWML construction
  test_swml_renderer.py       — SWML rendering
  test_swml_handler.py        — SWML handling
  test_swaig_function.py      — SWAIG function definition/execution
  test_function_result.py     — SwaigFunctionResult all 41 actions
  test_data_map.py            — DataMap patterns and webhook building
  test_contexts.py            — Context and step navigation
  test_session_manager.py     — Session lifecycle and tokens
  test_skill_manager.py       — Skill loading and configuration
  test_auth_handler.py        — Basic auth validation
  test_logging_config.py      — Logging setup
  test_pom_builder.py         — Prompt Object Model
  test_security_config.py     — Security settings

tests/unit/core/mixins/
  test_prompt_mixin.py        — Prompt configuration
  test_tool_mixin.py          — SWAIG tool definition
  test_web_mixin.py           — Web routing and HTTP
  test_auth_mixin.py          — Authentication
  test_serverless_mixin.py    — Lambda/CGI/Cloud detection
  test_state_mixin.py         — State management
  test_ai_config_mixin.py     — LLM parameters

tests/unit/skills/
  test_datetime_skill.py      — DateTime skill
  test_math_skill.py          — Math skill
  test_web_search_skill.py    — Web search
  test_wikipedia_search_skill.py
  test_weather_api_skill.py
  test_datasphere_skill.py
  test_datasphere_serverless_skill.py
  test_joke_skill.py
  test_spider_skill.py
  test_native_vector_search_skill.py
  test_mcp_gateway_skill.py
  test_claude_skills_skill.py
  test_api_ninjas_trivia_skill.py
  test_swml_transfer_skill.py
  test_play_background_file_skill.py
  test_info_gatherer_skill.py
  test_registry.py            — Skill registry

tests/unit/prefabs/
  test_survey.py              — SurveyAgent
  test_concierge.py           — ConciergeAgent
  (+ InfoGatherer, Receptionist, FAQBot)

tests/unit/relay/
  test_client.py              — RelayClient
  test_call.py                — Call handling
  test_client_dial.py         — Dialing
  test_message.py             — Messaging
  test_event.py               — Event handling

tests/unit/rest/
  test_client.py              — REST client
  test_base.py                — Base client
  test_calling.py             — Calling namespace
  test_fabric.py              — Fabric namespace
  test_namespaces.py          — Namespace routing

tests/unit/cli/
  test_agent_loader.py        — Agent discovery
  test_build_search.py        — Search index building (SKIP)
```

You don't need to match filenames exactly — but every **tested behavior** must be covered. If Python tests that `add_hint()` adds to the hints list, your port must test the same. If Python tests that expired tokens are rejected, your port must test the same.

---

## Final Audit (REQUIRED before shipping)

When the port is complete, perform these three audits before declaring it done. Do not skip this step.

### Automated surface audit (Layer B)

The porting-sdk repo ships `python_surface.json` — a machine-generated snapshot of every public class, method, and module function in the Python reference. Every port must diff against it.

**How ports plug in:**

1. Each port ships its own `scripts/enumerate_<lang>.*` that walks its source and emits JSON matching the shape of `python_surface.json`. The enumerator's responsibility is translating native names to Python-reference names: TypeScript's `setPromptText` becomes `signalwire.core.agent_base.AgentBase.set_prompt_text`, Go's `AgentBase.SetPromptText` becomes the same. Symbols line up only if both sides use the Python reference's names.

2. Port CI runs:

```bash
python3 porting-sdk/scripts/diff_port_surface.py \
    --reference porting-sdk/python_surface.json \
    --port-surface port_surface.json \
    --omissions PORT_OMISSIONS.md \
    --additions PORT_ADDITIONS.md
```

3. Drift → non-zero exit → CI failure. Clean drift → the port is symbol-complete against the current Python reference.

**PORT_OMISSIONS.md** lists symbols the port deliberately skips. Format:

```
# One symbol per line, rationale required.
signalwire.rest.namespaces.fabric.GenericResources.assign_phone_route: narrow-use legacy API; phone_numbers.set_* is the good path per phone-binding.md
signalwire.rest.namespaces.fabric.SwmlWebhooksResource.create: auto-materialized by phone_numbers.set_swml_webhook
```

**PORT_ADDITIONS.md** lists port-only extensions (same format). Reviewers use this to spot drift from the reference.

**Keeping `python_surface.json` fresh:** the porting-sdk's nightly CI regenerates it against the live `signalwire-python` main and fails the job on drift. When that fails, someone commits the regenerated snapshot to porting-sdk, which in turn triggers each port's CI to re-diff — surfacing port gaps within 24 hours of upstream additions.

### Completeness Audit

Cross-reference every item against the Python SDK:

1. **AgentBase methods** — compare every public method in `agent_base.py` against your port. Every method must exist with equivalent behavior.
2. **SwaigFunctionResult actions** — verify all 41 action methods match `function_result.py`. Pay special attention to:
   - Payment helper methods: `CreatePaymentPrompt()`, `CreatePaymentAction()`, `CreatePaymentParameter()`
   - These are static/convenience methods easily missed
3. **SWML verbs** — verify all 38 schema-driven verb methods are present and validated against `schema.json`
4. **RELAY client** — verify all 4 correlation mechanisms are implemented (JSON-RPC id, call_id, control_id, tag)
5. **REST client** — verify all 21 namespaces are initialized and have correct API paths
6. **Skills registry** — verify all 17 built-in skills are registered and constructable
7. **Skill integration** — verify `agent.AddSkill("skill_name", params)` one-liner works (not just manual SkillManager usage)
8. **No TODO/FIXME** — search entire codebase for TODO, FIXME, XXX, HACK, PLACEHOLDER — none should remain
9. **Examples compile** — every example must build without errors
10. **Top-level directories** — verify `relay/`, `rest/` directories each have README.md, docs/, examples/

### Security Audit

Perform a thorough security review of the entire implementation. Read the actual source code — do not rely on assumptions about what the code does. Check for common web application vulnerabilities (OWASP Top 10), language-specific pitfalls, and any place where untrusted input crosses a trust boundary.

The checklist below covers specific vulnerabilities that were found in prior ports. Use it as a starting point, not an exhaustive list:

1. **Timing-safe auth comparison** — basic auth MUST use constant-time comparison, not `==`
2. **No credential logging** — grep for password variables near log/print statements. Passwords must never appear in logs.
3. **No weak fallback passwords** — if random generation fails, service must refuse to start, not fall back to a known string
4. **Request body size limits** — every HTTP handler accepting POST bodies must enforce a max size (1MB recommended)
5. **SIP username validation** — extracted SIP usernames must be validated (alphanumeric + dots/hyphens, max length)
6. **JSON parse error handling** — no silent ignoring of malformed JSON input
7. **Shared state thread safety** — all maps/dicts accessed from multiple threads/goroutines/tasks must be protected
8. **HMAC token validation** — verify timing-safe comparison is used for token signature checking
9. **Security headers present** — verify X-Content-Type-Options, X-Frame-Options, Cache-Control on all authenticated endpoints
10. **Dependencies** — check for known vulnerabilities in all third-party dependencies

Beyond this checklist, review the implementation for any other security concerns specific to the language or framework being used.

---

## LiveKit Compatibility Shim

Once the SDK is ported to Go, a LiveKit compatibility layer can be added on top. LiveKit developers write:

```python
agent = Agent(instructions="...")
agent.function_tool("lookup_weather", handler, params)
session = AgentSession(stt=deepgram.STT(), llm=openai.LLM(), tts=cartesia.TTS())
session.start(room=ctx.room, agent=agent)
```

The shim maps:
- `Agent(instructions)` → `agent.SetPromptText(instructions)`
- `@function_tool` → `agent.DefineTool(...)`
- `AgentSession(stt=, llm=, tts=)` → SWML AI verb engine config
- `session.say()` → `SwaigFunctionResult.Say()`
- `AgentHandoff` → `SwmlChangeContext()`

The pitch: **same agent definition, zero pipeline infrastructure**. SignalWire's cloud handles the entire STT/LLM/TTS pipeline that LiveKit developers have to run and scale themselves.

---

## Environment Variables Reference

| Variable | Used By | Purpose |
|----------|---------|---------|
| `PORT` | Agent/Server | HTTP server port (default 3000) |
| `SWML_BASIC_AUTH_USER` | Agent | Basic auth username |
| `SWML_BASIC_AUTH_PASSWORD` | Agent | Basic auth password |
| `SWML_PROXY_URL_BASE` | Agent | Override webhook base URL |
| `SIGNALWIRE_PROJECT_ID` | RELAY/REST | Project identifier |
| `SIGNALWIRE_API_TOKEN` | RELAY/REST | API token |
| `SIGNALWIRE_JWT_TOKEN` | RELAY | JWT authentication |
| `SIGNALWIRE_SPACE` | RELAY/REST | Space hostname |
| `SIGNALWIRE_LOG_LEVEL` | Logging | debug/info/warn/error |
| `SIGNALWIRE_LOG_MODE` | Logging | "off" to suppress all |
| `RELAY_MAX_ACTIVE_CALLS` | RELAY | Max concurrent calls (default 1000) |
| `RELAY_MAX_CONNECTIONS` | RELAY | Max WebSocket connections (default 1) |
