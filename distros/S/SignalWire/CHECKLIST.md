# SignalWire AI Agents SDK — Perl Port Checklist

Tracking checklist for the Perl port. Inherits the inventory contract from
`porting-sdk/CHECKLIST_TEMPLATE.md` so `audit_checklist.py` can verify that
every skill, prefab, REST namespace, doc, and example the Python reference
SDK ships is enumerated here. The phase-by-phase implementation tracking is
preserved verbatim so completed work has a place to be checked off.

**Target Language:** Perl
**Start Date:** 2025-03-20
**Python SDK Reference:** /home/devuser/src/signalwire-python (the source of truth)

---

## Verification Discipline (read before checking any box)

Agents completing this checklist have historically left gaps by treating ambiguous items as "done" when they were partially done. Every box must be checked only after **mechanical verification**. The rules below apply to every phase below and are enforced by `scripts/audit_checklist.py` in the porting-sdk repo (runs in CI).

1. **No item may be checked without a verifiable proof.** Proof is one of:
   - A passing test whose name you can name.
   - A file that exists at a specific path.
   - A command that exits 0 (compile, lint, grep-no-match, etc.).
   - A string that appears in a specific file at a specific location.
2. **"See `OTHER.md`" is not permission to skim.** If the checklist references another document, read it in full before checking the item.
3. **Counts in this checklist are exact, not floors.** "17 skills" means 17 skills, not "at least 17." If the Python reference changes the count, `audit_checklist.py` fails CI and this file gets updated.
4. **Doc↔code alignment is required.** Every method or class referenced in a `docs/`, `rest/docs/`, `relay/docs/`, or `examples/` file must exist in the port's source. Phase 13 audits this. A port that ships `assign_phone_route` in a doc without implementing it fails Phase 13.
5. **"Commit to git" means a named feature branch, not `main`.** Every `- [ ] Commit to git` means committing on a descriptive `feat/<topic>` branch (e.g. `feat/swml-core`, `feat/lambda-support`, `feat/phone-binding-helpers`). Direct commits to `main` fail review.
6. **"No tests skipped" means no tests skipped.** `pytest -m "not slow"`, `go test -short`, `rspec --tag ~integration`, etc. are not allowed when reporting a phase complete. Run the full suite, 0 failures, 0 skips.
7. **No stubs anywhere.** Every artifact in this port — SDK source, examples, skills, CLIs, transports, prefabs — is production code. A function body that returns `"would call X in production"`, `"not implemented"`, hardcoded fake-data shaped to look real, or any value that bypasses the documented upstream call IS A BUG and IS NOT EXEMPT BY ANY TEST. If `audit_stubs.py` (Phase 13) finds a hit, the port is not done. See PORTING_GUIDE.md → "Production Code Discipline" for the full rule and the small allow-list (optional-extra guards, abstract methods, documented platform restrictions). Tests are NOT allowed to assert stub behavior — a test like `assert err.contains("not available")` against a transport stub is itself a violation.
8. **Tests prove behavior, not shape.** A test that says "the symbol exists" or "the response is non-empty" against a stub passes against canned data. Tests must drive the documented user-visible behavior end-to-end: the function is called, the upstream is contacted (live with credentials, or via a recorded cassette of real upstream output), the parsed response matches what a live caller would see. A mock that removes the requirement that a transport exist at all is wrong — the transport's existence and basic correctness must be tested separately.
9. **Every example runs.** Every file in `examples/` must do exactly what its docstring says when invoked. `audit_examples_run.py` (Phase 13) drives each one and asserts the documented behavior. Compile-pass is not acceptance — behavior-pass is.

---

## Phase 1: Foundation
- [ ] Module/package initialized with git repo (main branch)
- [ ] Directory structure (see PORTING_GUIDE.md Module Layout)
- [ ] .gitignore
- [ ] README.md with quickstart example
- [ ] CLAUDE.md with development guidance
- [ ] Dependency file (cpanfile, Gemfile, go.mod, build.gradle, package.json, etc.)
- [ ] Logging system (levels: debug/info/warn/error, env: SIGNALWIRE_LOG_LEVEL, suppression: SIGNALWIRE_LOG_MODE=off)
- [ ] Tests: logger creation, level filtering, suppression, env var config
- [ ] Commit to git

## Phase 2: SWML Core
- [ ] SWML Document model (version, sections, verbs, JSON rendering)
- [ ] Schema loaded from schema.json (embedded in package)
- [ ] 38 verb methods auto-vivified from schema (see PORTING_GUIDE.md for mapping)
- [ ] Sleep verb: takes integer, not map
- [ ] AI verb: present but overridden by AgentBase
- [ ] SWMLService HTTP server
- [ ] Basic auth (auto-generated or SWML_BASIC_AUTH_USER/PASSWORD)
- [ ] Security headers (X-Content-Type-Options, X-Frame-Options, Cache-Control)
- [ ] /health, /ready endpoints (no auth)
- [ ] Routing callbacks
- [ ] SIP username extraction from request body
- [ ] SWML_PROXY_URL_BASE support
- [ ] **SWMLService SWAIG hosting:** tool registry on SWMLService, `define_tool(name, description, parameters, handler, secure?)`, `register_swaig_function(dict)` (DataMap/raw), `on_function_call(name, args, raw)`, `list_tool_names`, `has_tool`
- [ ] **SWMLService `/swaig` endpoint:** GET returns SWML doc, POST dispatches tool by name; function-name validated against `^[a-zA-Z_][a-zA-Z0-9_]*$`; basic auth required; 1MB body limit; missing/unknown name returns 400/404
- [ ] **SWMLService extension points:** `_swaig_render_get_response(request, callId)` defaults to serializing the current doc; `_swaig_pre_dispatch(request, body, callId, fnName)` defaults to no-op `(self, null)` — both must be overridable by subclasses
- [ ] **SWMLService is independently runnable:** a user can construct `SWMLService` directly (no AgentBase), register a tool, emit any verb (including `ai_sidecar`), serve `GET {route}` + `GET/POST {route}/swaig`. Tests prove this end-to-end without instantiating AgentBase.
- [ ] Tests: document CRUD, schema loads 38 verbs, all verb methods callable, service auth, HTTP endpoints, security headers, **SWMLService SWAIG round-trip (define + GET /swaig + POST /swaig dispatch + unknown-fn 404 + invalid-name 400 + no-auth 401)**, **SWMLService sidecar pattern (ai_sidecar verb + tool dispatch end-to-end)**
- [ ] Commit to git

## Phase 3: Agent Core

### SwaigFunctionResult
- [ ] Constructor(response, post_process)
- [ ] SetResponse, SetPostProcess, AddAction, AddActions, ToMap/ToDict
- [ ] Serialization rules: response always, action only if non-empty, post_process only if true
- [ ] **Exactly 41 action methods** documented in SWAIG_FUNCTION_RESULT_REFERENCE.md with exact JSON (read the whole file; count the `### <Method>` sections; your port must implement every one). Count is enforced by `scripts/audit_checklist.py` if the reference doc changes.
- [ ] Payment helpers: CreatePaymentPrompt, CreatePaymentAction, CreatePaymentParameter
- [ ] Method chaining on all methods (return `self` / `this` / `&mut Self`)
- [ ] Tests: construction, serialization, each action category (connect, hangup, say, update_global_data, record_call, toggle_functions, execute_rpc, send_sms, payment helpers), method chaining. **Proof: test file exists at the language-idiomatic path, runs clean, covers ≥1 case per method.**

### SessionManager
- [ ] HMAC-SHA256 token creation (functionName:callID:expiry, signed, base64)
- [ ] Token validation (timing-safe comparison, expiry check)
- [ ] Random 32-byte secret per manager — fail hard if entropy unavailable
- [ ] Default expiry: 3600 seconds
- [ ] Tests: token round-trip, wrong function/callID rejected, expired rejected, tampered rejected

### DataMap
- [ ] Fluent builder: New, Purpose/Description, Parameter (with enum), Expression
- [ ] Webhook, WebhookExpressions, Body, Params, Foreach
- [ ] Output, FallbackOutput, ErrorKeys, GlobalErrorKeys
- [ ] ToSwaigFunction serialization
- [ ] CreateSimpleApiTool helper
- [ ] CreateExpressionTool helper
- [ ] Tests: fluent chain, parameters, webhook config, expressions, serialization, helpers

### Contexts & Steps
- [ ] ContextBuilder: AddContext, GetContext, Validate, Reset, ToMap
- [ ] Context: AddStep, GetStep, RemoveStep, MoveStep, SetInitialStep, all setters, ToMap
- [ ] Step: all setters (text, sections, criteria, functions, navigation, gather, reset), ToMap
- [ ] GatherInfo and GatherQuestion
- [ ] CreateSimpleContext helper
- [ ] Validation: single context must be "default", initial_step must reference existing step, reserved tool names rejected
- [ ] AgentBase.ResetContexts() convenience method
- [ ] Tests: step config, context with steps, gather info, serialization, validation rules, fillers, MoveStep, initial_step, reset

### AgentBase
- [ ] **Inherits from SWMLService** — `extends`/`: public`/struct-embedding/`Deref<Target=Service>`. No standalone class. No re-declaration of name/route/host/port/auth/app fields. No second tool registry. No second `/swaig` route.
- [ ] Constructor with functional options / builder pattern (calls SWMLService constructor with resolved name/route/host/port/auth)
- [ ] Prompt: SetPromptText, SetPostPrompt, POM (AddSection, AddSubsection, AddToSection, HasSection)
- [ ] AI Config: hints, pattern hints, languages, pronunciations, params, global data, native functions, fillers, debug events, function includes, LLM params
- [ ] Verbs: AddPreAnswerVerb, AddAnswerVerb, AddPostAnswerVerb, AddPostAiVerb, Clear methods
- [ ] Contexts: DefineContexts returns ContextBuilder
- [ ] Skills: AddSkill one-liner, RemoveSkill, ListSkills, HasSkill
- [ ] Web: DynamicConfigCallback, proxy URL, webhook URL, post-prompt URL, query params
- [ ] SIP: EnableSipRouting, RegisterSipUsername, extractSipUsername utility
- [ ] Lifecycle: OnSummary, OnDebugEvent
- [ ] SWML Rendering: 5-phase pipeline (pre-answer, answer, post-answer, AI, post-AI)
- [ ] **Overrides `_swaig_render_get_response`** to render the prompt-driven doc (not the raw `render_document()` default)
- [ ] **Overrides `_swaig_pre_dispatch`** to validate session token (when `secure`) and apply dynamic-config callback to an ephemeral copy
- [ ] Mounts agent-only routes onto the inherited app: /post_prompt (summary), /check_for_input, /debug_events, /mcp (opt-in). Does NOT remount /, /swaig, /health, /ready.
- [ ] Dynamic config: clone agent, apply callback, render from clone, original not mutated
- [ ] Webhook URL construction with auth and query params
- [ ] Run/Serve/AsRouter inherited from SWMLService (or overridden only to add agent-specific startup)
- [ ] Request body size limit (1MB) on all POST handlers (inherited helper)
- [ ] Tests: construction, **AgentBase IS-A SWMLService (inheritance check)**, prompt modes, **tools defined on AgentBase dispatch through inherited /swaig**, AI config, verbs, contexts, skills integration, render_swml structure, dynamic config isolation, HTTP endpoints (auth, SWML, swaig dispatch, post_prompt, health), method chaining
- [ ] Commit to git

## Phase 4: Skills System
- [ ] SkillBase interface (see SKILLS_MANIFEST.md for full contract)
- [ ] BaseSkill with default implementations
- [ ] SkillManager: LoadSkill, UnloadSkill, ListLoadedSkills, HasSkill, GetSkill
- [ ] SkillRegistry: RegisterSkill, GetSkillFactory, ListSkills
- [ ] All 17 built-in skills (see SKILLS_MANIFEST.md for exact specifications):
  - [ ] datetime (get_current_time, get_current_date)
  - [ ] math (calculate — safe evaluator, no eval)
  - [ ] joke (tell_joke)
  - [ ] weather_api (get_weather — HTTP to WeatherAPI.com)
  - [ ] web_search (web_search — HTTP to Google CSE)
  - [ ] wikipedia_search (search_wiki — HTTP to Wikipedia API)
  - [ ] google_maps (lookup_address, compute_route)
  - [ ] spider (scrape_url — HTTP fetch + HTML strip)
  - [ ] datasphere (search_datasphere — HTTP to SignalWire DataSphere)
  - [ ] datasphere_serverless (DataMap-based DataSphere)
  - [ ] swml_transfer (transfer_call — pattern matching)
  - [ ] play_background_file (play/stop background audio)
  - [ ] api_ninjas_trivia (get_trivia)
  - [ ] native_vector_search (search_knowledge — network mode only)
  - [ ] info_gatherer (start_questions + submit_answer — stateful)
  - [ ] claude_skills (SKILL.md file loading)
  - [ ] mcp_gateway (MCP server bridge)
- [ ] Tests: registry lists 17, each instantiable, skills without env vars setup OK, datetime+math handlers execute, SkillManager load/unload
- [ ] **Skill upstream-call verification.** For each skill that names an upstream service (`weather_api`, `web_search`, `wikipedia_search`, `google_maps`, `spider`, `datasphere`, `api_ninjas_trivia`, `native_vector_search`, `claude_skills`, `mcp_gateway`), there is a test that drives the skill end-to-end against either (a) the live upstream gated by an env var (e.g. `SWSDK_LIVE_TESTS=1`) AND credentials, OR (b) a recorded HTTP cassette of a real upstream response. NO skill may pass its tests against a hardcoded fake response — the real transport must be exercised. `audit_skills_upstream.py` (Phase 13) validates this and fails any skill whose handler returns canned data without making a network call.
- [ ] Commit to git

## Phase 5: Prefab Agents
- [ ] InfoGathererAgent (questions → start_questions + submit_answer tools)
- [ ] SurveyAgent (typed questions → validate_response + log_response tools)
- [ ] ReceptionistAgent (departments → collect_caller_info + transfer_call tools)
- [ ] FAQBotAgent (FAQs → search_faqs tool with keyword scoring)
- [ ] ConciergeAgent (venue → check_availability + get_directions tools)
- [ ] Tests: each constructible, each has expected tools, tool handlers execute
- [ ] Commit to git

## Phase 6: AgentServer
- [ ] Register/Unregister agents by route
- [ ] GetAgents/GetAgent
- [ ] SIP routing (SetupSipRouting, RegisterSipUsername)
- [ ] Static file serving (with path traversal protection, security headers, MIME types)
- [ ] Health/ready endpoints
- [ ] Root index listing agents
- [ ] Run with HTTP server
- [ ] Tests: register/unregister, get agents, health endpoint, route dispatch, SIP routing, static file serving
- [ ] Commit to git

## Phase 7: RELAY Client
- [ ] WebSocket connection to wss://{space}
- [ ] JSON-RPC 2.0 framing
- [ ] Authentication (project/token and JWT)
- [ ] Authorization state for fast reconnect
- [ ] Auto-reconnect with exponential backoff (1s → 30s)
- [ ] 4 correlation mechanisms (JSON-RPC id, call_id, control_id, tag)
- [ ] Event ACK (immediate response to signalwire.event)
- [ ] Ping handling (respond to signalwire.ping)
- [ ] Server disconnect handling (restart flag)
- [ ] Context subscription/unsubscription
- [ ] Call object — all methods documented in `call-methods.md` (read the whole file; count the methods; your port must expose every one)
- [ ] **Exactly 11 action types** with Wait/Stop/IsDone/OnCompleted: PlayAction, RecordAction, CollectAction, ConnectAction, DetectAction, FaxAction, TapAction, SendDigitsAction, DialAction, ReferAction, PayAction. (Plus PromptAction + queue/echo variants — follow `RELAY_IMPLEMENTATION_GUIDE.md` for the authoritative list and update this line if it diverges.)
- [ ] PlayAction: Pause, Resume, Volume
- [ ] play_and_collect gotcha handled (filter by event_type)
- [ ] detect gotcha handled (resolve on first meaningful result)
- [ ] dial tag correlation (call_id nested in params.call.call_id)
- [ ] call-gone (404/410) handled gracefully
- [ ] **Exactly 22 typed event types** (see the event-constants table in `events.md`): EVENT_CALL_STATE, EVENT_CALL_RECEIVE, EVENT_CALL_PLAY, EVENT_CALL_RECORD, EVENT_CALL_COLLECT, EVENT_CALL_CONNECT, EVENT_CALL_DETECT, EVENT_CALL_FAX, EVENT_CALL_TAP, EVENT_CALL_STREAM, EVENT_CALL_SEND_DIGITS, EVENT_CALL_DIAL, EVENT_CALL_REFER, EVENT_CALL_DENOISE, EVENT_CALL_PAY, EVENT_CALL_QUEUE, EVENT_CALL_ECHO, EVENT_CALL_TRANSCRIBE, EVENT_CONFERENCE, EVENT_CALLING_ERROR, EVENT_MESSAGING_RECEIVE, EVENT_MESSAGING_STATE
- [ ] SMS/MMS messaging (SendMessage, OnMessage, delivery tracking)
- [ ] Tests: constants, event parsing (all types), action wait/resolve/callback, call creation, message state, client construction, correlation mechanism verification
- [ ] **Real WebSocket transport.** The transport actually opens a WSS connection to `wss://{space}/api/relay/ws`, runs the JSON-RPC `signalwire.connect` handshake, and round-trips real frames. NO stub transport (no `Stub: production would write to socket`, no comment about "production opens WSS"). Test proof: a transport-level test stands up a JSON-RPC echo server (or uses a recorded cassette of a real RELAY connect/auth exchange) and verifies the client's connect → authenticate → subscribe → event-receive flow over a real socket. A unit test that mocks the transport away does not satisfy this item.
- [ ] Commit to git

## Phase 8: REST Client
- [ ] HTTP client with Basic Auth
- [ ] CrudResource (List, Create, Get, Update, Delete)
- [ ] Pagination support
- [ ] SignalWireRestError
- [ ] **All 21 REST namespaces** — exact stems below. Every one must be accessible as `client.<stem>` (Python) / `client.<CamelStem>` (Go/Java/etc.) in the port. Enforced by `scripts/audit_checklist.py`.
  - [ ] Fabric — **exactly 16 sub-resources**: `swml_scripts`, `swml_webhooks`, `ai_agents`, `relay_applications`, `call_flows`, `conference_rooms`, `freeswitch_connectors`, `subscribers`, `sip_endpoints`, `sip_gateways`, `cxml_scripts`, `cxml_webhooks`, `cxml_applications`, `resources`, `addresses`, `tokens`
  - [ ] Calling (**exactly 37 commands** — see the OpenAPI spec at `rest-apis/calling/openapi.yaml`)
  - [ ] PhoneNumbers — see § Phone-number binding below for the 7 typed helpers
  - [ ] Datasphere
  - [ ] Video
  - [ ] Compat (Twilio LAML)
  - [ ] Addresses
  - [ ] Queues
  - [ ] Recordings
  - [ ] NumberGroups
  - [ ] VerifiedCallers
  - [ ] SipProfile
  - [ ] Lookup
  - [ ] ShortCodes
  - [ ] ImportedNumbers
  - [ ] MFA
  - [ ] Registry
  - [ ] Logs
  - [ ] Project
  - [ ] PubSub
  - [ ] Chat
- [ ] Tests: client creation, all namespaces initialized (non-nil), CRUD path construction, error formatting, sub-resource verification

### Phone-number binding (required — see phone-binding.md)

Routing an inbound phone number to an SWML webhook, cXML app, AI agent, call flow, etc. is configured on the **phone number**, not on the Fabric resource. See [phone-binding.md](phone-binding.md) for the full model. Every port must ship:

- [ ] `PhoneCallHandler` enum / constants with all 11 wire values (`relay_script`, `laml_webhooks`, `laml_application`, `ai_agent`, `call_flow`, `relay_application`, `relay_topic`, `relay_context`, `relay_connector`, `video_room`, `dialogflow`). Name chosen to avoid colliding with the RELAY client's `CallHandler` / `on_call_handler` callback type already present in 5 of 7 ports.
- [ ] Typed helpers on `phone_numbers`, each a one-liner wrapping `phone_numbers.update` with the right `call_handler` value and companion field:
  - [ ] `set_swml_webhook(sid, url=...)` → `call_handler=relay_script` + `call_relay_script_url`
  - [ ] `set_cxml_webhook(sid, url=..., fallback_url=?, status_callback_url=?)` → `laml_webhooks` + `call_request_url` (+ optional fallback / status)
  - [ ] `set_cxml_application(sid, application_id=...)` → `laml_application` + `call_laml_application_id`
  - [ ] `set_ai_agent(sid, agent_id=...)` → `ai_agent` + `call_ai_agent_id`
  - [ ] `set_call_flow(sid, flow_id=..., version=?)` → `call_flow` + `call_flow_id` (+ optional `call_flow_version`)
  - [ ] `set_relay_application(sid, name=...)` → `relay_application` + `call_relay_application`
  - [ ] `set_relay_topic(sid, topic=...)` → `relay_topic` + `call_relay_topic`
- [ ] `assign_phone_route` on fabric resources — **either omit entirely (preferred, Java and C++ do this) or keep with a deprecation warning + docstring naming which resource types actually accept it**. Do not ship it with no docstring and a mock-only test — that's the trap the porting audit found.
- [ ] `swml_webhooks` / `cxml_webhooks` Fabric resources — if the port exposes them as create-capable, the create method's docstring must state "created automatically by `phone_numbers.set_swml_webhook` / `set_cxml_webhook`; manual create is rarely needed." Preferred approach: don't expose a `create` method on these (match Python's `cxml_applications` precedent of `raise NotImplementedError`).
- [ ] Tests: one unit test per typed helper asserting the wire-level body (`call_handler` + companion field), plus a single round-trip test showing `phone_numbers.set_swml_webhook` ends up with `swml_webhook` in the Fabric resources listing (mockable). **Regression test** against the post-mortem: setting `call_handler=relay_script` does NOT require pre-creating a `swml_webhook` resource, and `assign_phone_route` is NOT called.

- [ ] Commit to git

## Phase 9: Serverless

First decide per platform: **required** or **optional**, based on whether the target language has a first-class runtime on that platform. See PORTING_GUIDE.md § Serverless Support for the capability table and implementation details.

### 9.0 Per-language capability check

Fill this in before starting the phase:

- [ ] Target language has first-class AWS Lambda runtime? **Yes / No**
  - If **Yes**, all Lambda items below are **required**.
  - If **No** (language needs a custom runtime), Lambda is **optional** — skip unless there's demand.
- [ ] Target language has first-class Google Cloud Functions runtime? **Yes / No** (required if yes)
- [ ] Target language has first-class Azure Functions runtime? **Yes / No** (required if yes)
- [ ] CGI is always trivial — **required** for all ports.

**Reference list of first-class runtimes** (update this as AWS/Google/Microsoft add more):
- Lambda: Python, Node.js/TypeScript, Java, Ruby, Go, .NET
- GCF: Python, Node.js, Java, Ruby, Go, .NET, PHP
- Azure: Python, Node.js, Java, PowerShell, .NET

### 9.1 Execution-mode detection (required for any port implementing any serverless platform)

- [ ] Idiomatic enum/const for modes: `server`, `cgi`, `lambda`, `google_cloud_function`, `azure_function`
- [ ] Detector reads env vars only (no filesystem, no network)
- [ ] Detection order: cgi → lambda → gcf → azure → server (Lambda before GCF before Azure — they can overlap in test harnesses)
- [ ] Env var mapping per PORTING_GUIDE.md § Serverless Support Step 1
- [ ] Tests: each mode detected via its env var combination, precedence is correct

### 9.2 AWS Lambda (required iff language has first-class runtime)

- [ ] Base URL construction: `AWS_LAMBDA_FUNCTION_URL` preferred, else `https://{AWS_LAMBDA_FUNCTION_NAME}.lambda-url.{AWS_REGION}.on.aws`
- [ ] `SWML_PROXY_URL_BASE` takes precedence over Lambda-specific URL
- [ ] **🔥 Agent route is concatenated into every webhook URL** — see Step 3 of the guide; this is the bug that bit Python and TypeScript
- [ ] Handler adapter translates API Gateway / Function URL events into the agent's HTTP handler (don't reimplement routing)
- [ ] `examples/lambda_agent.*` exists with minimal deployment boilerplate
- [ ] Tests:
  - [ ] Mode detection with `AWS_LAMBDA_FUNCTION_NAME` set
  - [ ] Base URL with `AWS_LAMBDA_FUNCTION_URL` set
  - [ ] Base URL fallback construction when `AWS_LAMBDA_FUNCTION_URL` unset
  - [ ] `SWML_PROXY_URL_BASE` beats Lambda env vars
  - [ ] **Route-preservation regression: agent at non-root route + Lambda env vars + `SWML_PROXY_URL_BASE` set → webhook URL contains `{route}/swaig`**
  - [ ] Handler smoke test: synthetic event in, 200 response out

### 9.3 Google Cloud Functions (required iff language has first-class runtime)

- [ ] Base URL construction per guide (region, project, service name)
- [ ] `SWML_PROXY_URL_BASE` takes precedence
- [ ] **Agent route is concatenated into every webhook URL**
- [ ] Handler adapter using the language's Functions Framework
- [ ] `examples/gcf_agent.*` exists
- [ ] Tests: mode detection, base URL, precedence, route-preservation regression, handler smoke test

### 9.4 Azure Functions (required iff language has first-class runtime)

- [ ] Base URL construction per guide
- [ ] `SWML_PROXY_URL_BASE` takes precedence
- [ ] **Agent route is concatenated into every webhook URL**
- [ ] Handler adapter using the language's Azure Functions library
- [ ] `examples/azure_agent.*` exists
- [ ] Tests: mode detection, base URL, precedence, route-preservation regression, handler smoke test

### 9.5 CGI (required for all ports)

- [ ] Mode detection via `GATEWAY_INTERFACE`
- [ ] Base URL from `HTTPS`, `HTTP_HOST`/`SERVER_NAME`, `SCRIPT_NAME`
- [ ] Tests: mode detection, URL construction, route preservation

### 9.6 Commit to git

- [ ] All new serverless code committed on a feature branch
- [ ] Every test passes — no skips, no `--no-verify`, no env-var leakage between tests

## Phase 10: CLI
- [ ] swaig-test: --url, --dump-swml, --list-tools, --exec, --param, --raw, --verbose
- [ ] URL auth extraction (http://user:pass@host:port/path)
- [ ] **`--list-tools` introspects the runtime tool registry in-process — never via HTTP.**
  - [ ] Dynamic langs (Python, Ruby, Perl, PHP, TypeScript): `--file PATH` (or positional path) loads the script in-process, finds the SWMLService subclass/instance, walks the registry directly. NO `/swaig` HTTP request.
  - [ ] Reflective langs (Java, .NET): `--class FQCN` (and `--assembly PATH` on .NET) loads via reflection, reads the SDK's public registry accessor (e.g. `getRegisteredTools()`, `Tools` property — add the accessor to Service if it doesn't exist).
  - [ ] Compiled langs (Rust, Go, C++): `--example NAME` spawns the example binary with `SWAIG_LIST_TOOLS=1` set in the child env. The SDK's `serve()`/`run()` checks the env var at entry and dumps the runtime registry to stdout between `__SWAIG_TOOLS_BEGIN__` / `__SWAIG_TOOLS_END__` sentinels, then `exit(0)` — BEFORE any port is bound. CLI captures stdout, slices between markers, parses, displays.
  - [ ] CLI is permissive about field names: accepts both `function|name`, `description|purpose`, `parameters|argument` (each port emits whatever it natively stores; no normalization).
  - [ ] `--list-tools` against a SWMLService-only example (no `<ai>` verb) returns the registered tools — NOT "No tools found." Verified against `examples/swmlservice_swaig_standalone.*` and `examples/swmlservice_ai_sidecar.*`.
- [ ] **Introspect contract for compiled-language SDKs:** the env-check in `serve()`/`run()` runs after user code populated the registry but before binding. Pull the JSON-build path into a separate testable helper (`build_tool_registry_json()` or equivalent) so tests can assert the payload without invoking `exit()`.
- [ ] `--simulate-serverless <platform>` flag — conditional on Phase 9
  - [ ] Accepts only platforms the port actually implemented in Phase 9 (reject others with a clear error)
  - [ ] For each implemented platform: sets the mode-detection env vars (e.g. `AWS_LAMBDA_FUNCTION_NAME`, `LAMBDA_TASK_ROOT`) before loading the agent, and clears them on exit so tests in the same process don't leak
  - [ ] Clears conflicting env vars (notably `SWML_PROXY_URL_BASE`) during simulation so platform-specific URL logic is exercised — mirrors Python's `mock_env.py` behavior
  - [ ] Routes agent invocation through the serverless adapter (Phase 9.2/9.3/9.4 handler), NOT the HTTP server — otherwise you're testing the wrong code path
  - [ ] Combines with `--dump-swml` and `--exec` (you simulate the environment, then dump/execute)
- [ ] Tests: URL parsing, param parsing, integration with live agent
- [ ] **Tests for `--list-tools` introspection:** building the registry returns the expected shape and order via the testable helper; loading an example (file/class/binary) lists at least one tool; sentinel extractor (compiled langs) handles happy path + both markers missing + partial markers correctly.
- [ ] Tests for each simulated platform the port implements: env vars are set during invocation and cleared after, `SWML_PROXY_URL_BASE` precedence is honored, agent runs through the serverless adapter
- [ ] Commit to git

## Phase 11: Documentation & Examples

Documentation and examples prove the implementation is complete and usable.

**The rule is simple: if the Python SDK has a doc or example (except search-related and bedrock-related), the port must have an equivalent in the target language.** This is not a suggestion — it's a requirement. Read the Python SDK's `docs/`, `examples/`, `relay/`, and `rest/` directories and port every file. Missing docs or examples mean missing proof that the feature works.

Do NOT copy `RELAY_IMPLEMENTATION_GUIDE.md` into language repos — the canonical copy lives in the porting-sdk repo and is only needed during development.

### Top-level docs/ (20 files — ALL from Python SDK except search/bedrock/comparison)

Port every one of these. Each must contain code examples in the target language, not Python.

- [ ] architecture.md
- [ ] agent_guide.md
- [ ] api_reference.md
- [ ] swaig_reference.md
- [ ] datamap_guide.md
- [ ] contexts_guide.md
- [ ] skills_system.md
- [ ] skills_parameter_schema.md
- [ ] third_party_skills.md
- [ ] security.md
- [ ] configuration.md
- [ ] llm_parameters.md
- [ ] sdk_features.md
- [ ] cli_guide.md
- [ ] swml_service_guide.md
- [ ] web_service.md
- [ ] cloud_functions_guide.md
- [ ] mcp_gateway_reference.md
- [ ] mcp_integration.md

Skip: search_*.md (4 files), bedrock_agent.md, livekit_comparison.md, pipecat_comparison.md

### Top-level relay/ directory (REQUIRED — 9 files)
- [ ] relay/README.md (API overview, quick start, code examples in target language)
- [ ] relay/docs/getting-started.md
- [ ] relay/docs/call-methods.md
- [ ] relay/docs/events.md
- [ ] relay/docs/messaging.md
- [ ] relay/docs/client-reference.md
- [ ] relay/examples/relay_answer_and_welcome.* (proves: answer, play TTS, hangup)
- [ ] relay/examples/relay_dial_and_play.* (proves: outbound dial, play, hangup)
- [ ] relay/examples/relay_ivr_connect.* (proves: collect DTMF, connect to department)

### Top-level rest/ directory (REQUIRED — 19 files)
- [ ] rest/README.md (API overview, namespace examples in target language)
- [ ] rest/docs/getting-started.md
- [ ] rest/docs/namespaces.md
- [ ] rest/docs/calling.md
- [ ] rest/docs/fabric.md
- [ ] rest/docs/compat.md
- [ ] rest/docs/client-reference.md
- [ ] rest/examples/rest_10dlc_registration.* (proves: registry namespace)
- [ ] rest/examples/rest_calling_ivr_and_ai.* (proves: calling namespace)
- [ ] rest/examples/rest_calling_play_and_record.* (proves: calling play/record)
- [ ] rest/examples/rest_compat_laml.* (proves: compat namespace)
- [ ] rest/examples/rest_datasphere_search.* (proves: datasphere namespace)
- [ ] rest/examples/rest_fabric_conferences_and_routing.* (proves: fabric sub-resources — **must NOT demonstrate `assign_phone_route` as the path to bind a phone number to a webhook; that's the anti-pattern the porting audit found**)
- [ ] rest/examples/rest_fabric_subscribers_and_sip.* (proves: fabric SIP)
- [ ] rest/examples/rest_fabric_swml_and_callflows.* (proves: fabric SWML)
- [ ] rest/examples/rest_manage_resources.* (proves: CRUD operations)
- [ ] rest/examples/rest_phone_number_management.* (proves: phone numbers)
- [ ] rest/examples/rest_bind_phone_to_swml_webhook.* (proves: `phone_numbers.set_swml_webhook` happy path — **this is the example whose absence cost a user hours per the binding post-mortem; every port must ship it**)
- [ ] rest/examples/rest_queues_mfa_and_recordings.* (proves: queues, MFA, recordings)
- [ ] rest/examples/rest_video_rooms.* (proves: video namespace)

### Agent examples/ directory (port ALL from Python except search/bedrock)

Every Python example has a counterpart in the port. The list below is the minimum — if Python has more, port those too. Run `ls ~/src/signalwire-python/examples/*.py` to get the current list.

- [ ] examples/README.md (index with descriptions)
- [ ] simple_agent.* (proves: AgentBase, prompt, tools, hints, language, run)
- [ ] simple_dynamic_agent.* (proves: DynamicConfigCallback, per-request customization)
- [ ] simple_dynamic_enhanced.* (proves: advanced dynamic config)
- [ ] simple_static_agent.* (proves: static config, no dynamic callback)
- [ ] multi_agent_server.* (proves: AgentServer, multiple agents, route dispatch)
- [ ] multi_endpoint_agent.* (proves: single agent, multiple endpoints)
- [ ] contexts_demo.* (proves: DefineContexts, steps, criteria, navigation, fillers)
- [ ] data_map_demo.* (proves: DataMap webhook + expression tools)
- [ ] advanced_datamap_demo.* (proves: advanced DataMap patterns)
- [ ] skills_demo.* (proves: AddSkill one-liner, skill registry)
- [ ] joke_skill_demo.* (proves: joke skill with API key)
- [ ] web_search_agent.* (proves: web search skill)
- [ ] web_search_multi_instance_demo.* (proves: multiple skill instances)
- [ ] wikipedia_demo.* (proves: wikipedia search skill)
- [ ] datasphere_serverless_demo.* (proves: datasphere serverless skill)
- [ ] datasphere_serverless_env_demo.* (proves: datasphere with env vars)
- [ ] datasphere_webhook_env_demo.* (proves: datasphere webhook)
- [ ] datasphere_multi_instance_demo.* (proves: multiple datasphere instances)
- [ ] session_and_state_demo.* (proves: global data, post-prompt, OnSummary callback)
- [ ] call_flow_and_actions_demo.* (proves: pre/post answer verbs, debug events, FunctionResult actions)
- [ ] swaig_features_agent.* (proves: type inference, fillers, webhook URLs)
- [ ] comprehensive_dynamic_agent.* (proves: per-request dynamic config, multi-tenant)
- [ ] gather_info_demo.* (proves: GatherInfo/GatherQuestion)
- [ ] llm_params_demo.* (proves: LLM parameter tuning)
- [ ] record_call_example.* (proves: call recording)
- [ ] tap_example.* (proves: call tapping)
- [ ] room_and_sip_example.* (proves: SIP routing, rooms)
- [ ] custom_path_agent.* (proves: custom routes)
- [ ] auto_vivified_example.* (proves: auto-vivified SWML verbs)
- [ ] basic_swml_service.* (proves: SWMLService runs without AgentBase — instantiates SWMLService directly, serves SWML on `/`)
- [ ] swmlservice_swaig_standalone.* (proves: SWMLService hosts SWAIG functions without AgentBase — `define_tool` + POST /swaig dispatch)
- [ ] swmlservice_ai_sidecar.* (proves: SWMLService emits `<ai_sidecar>` verb, registers a tool, dispatches end-to-end)
- [ ] dynamic_swml_service.* (proves: dynamic SWML generation)
- [ ] swml_service_example.* (proves: SWML service patterns)
- [ ] swml_service_routing_example.* (proves: SWML service routing)
- [ ] declarative_agent.* (proves: declarative config)
- [ ] lambda_agent.* (proves: AWS Lambda deployment)
- [ ] kubernetes_ready_agent.* (proves: K8s deployment patterns)
- [ ] mcp_agent.* (proves: MCP integration)
- [ ] mcp_gateway_demo.* (proves: MCP gateway skill)
- [ ] info_gatherer_example.* (proves: InfoGathererAgent prefab)
- [ ] dynamic_info_gatherer_example.* (proves: dynamic InfoGatherer)
- [ ] survey_agent_example.* (proves: SurveyAgent prefab)
- [ ] faq_bot_agent.* (proves: FAQBotAgent prefab)
- [ ] receptionist_agent_example.* (proves: ReceptionistAgent prefab)
- [ ] concierge_agent_example.* (proves: ConciergeAgent prefab)
- [ ] joke_agent.* (proves: simple agent with joke skill)
- [ ] gather_per_question_functions_demo.* (proves: gather_info per-question function whitelist)
- [ ] step_function_inheritance_demo.* (proves: step functions inherit from previous step when omitted)
- [ ] relay_answer_and_welcome.* (proves: RELAY answer+play — also in relay/examples/)

Skip: bedrock_*.py, search_*.py, pgvector_*.py, sigmond_*.py

### Commit to git

## Phase 12: Testing Verification

Tests are proof of implementation. The port must test **everything the Python SDK tests**. Read the Python test files in `tests/unit/` and ensure equivalent coverage exists in your port for every tested behavior.

- [ ] Every public method has at least one test exercising it
- [ ] Every test the Python SDK has (except search-related) has an equivalent in the port
- [ ] All tests pass with zero failures, no tests skipped
- [ ] Test coverage matches Python SDK organization:
  - [ ] Core: agent_base, swml_service, swml_builder, swml_renderer, swml_handler
  - [ ] SWAIG: swaig_function, function_result (all 41 action methods)
  - [ ] Security: session_manager, auth_handler
  - [ ] DataMap: data_map (all builder methods, serialization)
  - [ ] Contexts: contexts (steps, navigation, validation, gather_info)
  - [ ] Mixins/Config: prompt, tool, web, auth, serverless, state, ai_config, skill
  - [ ] Skills: registry, manager, each of the 17 built-in skills individually
  - [ ] Prefabs: each of the 5 prefab agents
  - [ ] AgentServer: registration, routing, SIP, static files
  - [ ] RELAY: client, call, action types, events, messages
  - [ ] REST: client, base resource, each major namespace, pagination
  - [ ] CLI: argument parsing, tool listing, execution
  - [ ] Utilities: schema_utils, logging, pom_builder, type_inference

## Phase 13: Final Audit (REQUIRED)

### Completeness Audit
- [ ] Every AgentBase public method from Python SDK has an equivalent. **Proof:** grep the port's source for every symbol the Python SDK exposes in `signalwire/core/agent_base.py` public surface; every one resolves.
- [ ] All 41 SwaigFunctionResult action methods present (plus the non-action basics: set_response, set_post_process, add_action, add_actions, to_dict, and the 3 payment helpers). **Proof:** grep the port's equivalent file for the 41 action names in SWAIG_FUNCTION_RESULT_REFERENCE.md; every one resolves, or the omission is justified in PORT_OMISSIONS.md.
- [ ] All 38 SWML verb methods present and schema-validated
- [ ] RELAY client: all 4 correlation mechanisms implemented (JSON-RPC id, call_id, control_id, tag)
- [ ] REST client: all 21 namespaces initialized with correct paths (see Phase 8 for the enumerated list)
- [ ] Skills registry: all 17 built-in skills registered (per Phase 4 enumerated list)
- [ ] agent.AddSkill() one-liner integration works (not just manual SkillManager)
- [ ] SIP username extraction utility exists
- [ ] Static file serving in AgentServer with path traversal protection
- [ ] No TODO/FIXME/HACK/PLACEHOLDER comments remain. **Proof:** `grep -rn 'TODO\|FIXME\|HACK\|PLACEHOLDER' <src dirs>` returns zero lines outside an explicit allow-list file.
- [ ] Every example compiles/runs without syntax errors. **Proof:** per language — `python -m py_compile examples/*.py`, `tsc --noEmit examples/*.ts`, `go build ./examples/...`, `javac examples/*.java`, `perl -c examples/*.pl`, `ruby -c examples/*.rb`, `cmake --build build --target examples`. All exit 0.
- [ ] Top-level relay/ and rest/ directories have README, docs, examples

### Symbol-level surface parity (REQUIRED)

The porting-sdk ships `python_surface.json` — a machine-generated snapshot of every public class, method, and module function in the Python reference. Your port must match this surface, or record each deliberate deviation in `PORT_OMISSIONS.md` / `PORT_ADDITIONS.md`.

- [ ] Your port has a `scripts/enumerate_<lang>.*` (or equivalent) that walks its source and emits a JSON snapshot in the same shape as `python_surface.json` — **with Python-reference symbol names, not native names**. Example: TypeScript's `setPromptText` is emitted as `signalwire.core.agent_base.AgentBase.set_prompt_text`. The translation layer is the port's responsibility.
- [ ] CI step runs `diff_port_surface.py --reference porting-sdk/python_surface.json --port-surface <port>.json --omissions PORT_OMISSIONS.md --additions PORT_ADDITIONS.md` on every PR. Non-zero exit fails the build.
- [ ] `PORT_OMISSIONS.md` at repo root lists every Python-reference symbol the port deliberately does NOT implement, one per line: `<fully.qualified.symbol>: <one-line rationale>`. **The phone-binding work set the precedent:** Java and C++ list `signalwire.rest.namespaces.fabric.GenericResources.assign_phone_route` with rationale "narrow-use legacy API; phone_numbers.set_* is the good path per phone-binding.md".
- [ ] `PORT_ADDITIONS.md` at repo root lists every port-only extension (symbols in the port that have no Python-reference equivalent), same format. Reviewers use this to spot drift from the reference.

### Doc↔code alignment (REQUIRED — the "Java/C++ phantom API" check)

This section exists because during the phone-binding audit, two ports were found shipping `rest/docs/fabric.md` that promised `assign_phone_route` and `swml_webhooks.create` — methods that had never been implemented in those ports. The checklist let it through because nothing cross-checked doc promises against actual source.

The porting-sdk ships `scripts/audit_docs.py` — a language-agnostic tool that walks a port's doc and example files, extracts method-call patterns from fenced code blocks and source files, and fails if any reference doesn't resolve in the port's `port_surface.json`. Every port must wire this into CI.

- [ ] CI step runs `audit_docs.py --root <port-root> --surface port_surface.json --ignore DOC_AUDIT_IGNORE.md`. Non-zero exit fails the build.
- [ ] `DOC_AUDIT_IGNORE.md` at repo root lists identifiers to skip: external SDK calls (`ArgumentParser`, `Thread`), stdlib (`json.loads`, `os.environ.get`), HTTP-client basics that aren't in the port's public surface, or intentional future-reference placeholders. Format: one name per line, optional `: <rationale>`. Skips without rationale are allowed for obvious externals but discouraged; prefer listing *why*.
- [ ] Every `examples/*` file compiles. Required commands per language (exit 0):
  - Python: `python -m py_compile examples/*.py`
  - TypeScript: `npx tsc --noEmit examples/**/*.ts`
  - Go: `go build ./examples/...`
  - Java: `javac -d /tmp/example-compile examples/**/*.java`
  - Perl: `perl -c examples/*.pl`
  - Ruby: `ruby -c examples/*.rb`
  - C++: `cmake --build build --target examples` (or the repo's example target)
- [ ] If the port **deliberately omits** a symbol the Python reference ships (e.g. Java and C++ intentionally omit `assign_phone_route` per the phone-binding spec), record it in `PORT_OMISSIONS.md` at the port's repo root. One line per omission: `<fully-qualified-symbol>: <one-sentence rationale>`. The file is checked by Phase 13 CI against the Python reference; un-recorded omissions fail the audit.
- [ ] If the port **adds** a symbol that has no Python reference equivalent, record it in `PORT_ADDITIONS.md` with the same format. Reviewers check that every addition has a justification.

### Behavior audit suite (REQUIRED — the "stub on main" check)

This section exists because the audit machinery historically only verified that names existed and tests passed; it did not verify that function bodies actually did the work the names promised. Several ports shipped with relay-client transports stubbed (`Stub: production would write to socket`), CLI HTTP layers stubbed (`HTTP transport not available`), `/swaig` dispatchers silently returning `[]` for every POST, and skill handlers returning hardcoded fake data. Every layer of the SHAPE audit was happy because the symbols existed and the tests passed — the tests passed because they asserted shape, not behavior.

Eight runnable programs in `porting-sdk/scripts/` close the gap. **All eight must exit 0 before a port is "complete."** The agent fixing a port runs them as the FINAL receipt and pastes the exit codes in the report. The main session re-runs them to verify (agents are not believed without a green program output).

- [ ] **`scripts/audit_stubs.py --root <port>` exits 0.** Greps the port for stub patterns (commented stubs like `// stub: in production...`, silent canned-data stubs whose params are all prefixed `_` and body is one literal return, feature gates whose feature isn't declared, panicking "not implemented" macros, etc.). Hits must be fixed OR recorded with rationale in port's `INTENTIONAL_NON_IMPLEMENTATION.md`.
- [ ] **`scripts/audit_http_swml.py --root <port>` exits 0.** For each port's example services, binds a real socket, asserts `GET <route>` returns a valid SWML doc, asserts `POST <route>/swaig` with `{"function":"NAME","argument":{"parsed":[{...}]}}` actually invokes the registered handler and returns its real response (not canned `[]`). Catches dispatcher stubs.
- [ ] **`scripts/audit_relay_handshake.py --root <port>` exits 0.** Stands up a local WS fixture on `127.0.0.1:0` that speaks JSON-RPC 2.0 and the `signalwire.connect` handshake. Drives the port's RELAY client at it. Asserts WSS upgrade arrives, `signalwire.connect` request is sent, auth response is parsed, contexts subscribe, an event the fixture pushes is dispatched to the client's callback. Catches stub WS transports (`// Stub: production would open WSS...`).
- [ ] **`scripts/audit_rest_transport.py --root <port>` exits 0.** Stands up a local HTTP fixture on `127.0.0.1:0`. Drives every REST namespace's documented operations against it. Asserts the wire request shape (method, path, headers, query params, body) matches the documented contract, and the parsed response matches a recorded real-shape response. Proves transport + serialization, NOT third-party reachability.
- [ ] **`scripts/audit_skills_dispatch.py --root <port>` exits 0.** For each skill that names an upstream service (Google CSE, Wikipedia, DataSphere, MCP gateway, etc.), drives the skill against a local HTTP fixture (no live credentials required) and asserts the skill's handler issued a real outbound HTTP request with the documented shape AND parsed a recorded response correctly. A skill whose handler returns canned data without contacting the fixture fails. Live testing against real upstreams is gated separately by an env var like `SWSDK_LIVE_TESTS=1`; the fixture-based audit is the always-on baseline.
- [ ] **`scripts/audit_test_parity.py --root <port>` exits 0.** Every Python test (minus skip list) has a behavior-equivalent in the port. Walks Python's `tests/` and the port's tests, maps by target symbol, fails on missing tests AND on tests whose body doesn't actually drive the symbol.
- [ ] **`scripts/audit_example_parity.py --root <port>` exits 0.** Every Python example (minus skip list) has a port-equivalent with the same documented contract.
- [ ] **`scripts/audit_no_cheat_tests.py --root <port>` exits 0.** No `assert true` / `expect(true).toBe(true)`, no empty / `pass`-bodied tests, no no-assertion tests, no tests that mock the very transport they exist to verify, no tests that only assert nullness (`assertNotNull(result)`) without checking response content. Allow-list in port's `INTENTIONAL_THIN_TESTS.md` for legit thin tests with rationale.

These eight audits answer "do the named things actually do what they claim?" The Layer A/B/C audits below answer "do the named things exist?" Both are required.

### Security Audit
Read all source code and review the full implementation for security issues. The items below are known vulnerabilities found in prior ports — check each with a concrete grep or test, not a skim:
- [ ] Basic auth uses timing-safe comparison (NOT `==`). **Proof:** grep for the language's timing-safe primitive (see PORTING_GUIDE.md § Timing-Safe Comparison by Language) in the auth-handling code; confirm it appears at every auth comparison site.
- [ ] Passwords never appear in log output
- [ ] No weak fallback passwords — fail to start if crypto/rand fails
- [ ] All POST handlers enforce request body size limits (1MB)
- [ ] SIP username extraction validates input format
- [ ] JSON parse errors are checked, not silently ignored
- [ ] All shared state protected by mutexes (global data, tool registry, RELAY maps)
- [ ] HMAC token validation uses timing-safe comparison
- [ ] Security headers set on all authenticated endpoints
- [ ] Third-party dependencies checked for known vulnerabilities
- [ ] General review: no other injection, XSS, SSRF, or language-specific vulnerabilities
