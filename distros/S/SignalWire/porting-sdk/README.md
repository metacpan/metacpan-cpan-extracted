# SignalWire AI Agents SDK — Porting Kit

Everything needed to port the SignalWire AI Agents SDK to a new language.

## Contents

### Core Reference Documents

| File | Description |
|------|-------------|
| **PORTING_GUIDE.md** | Master guide: architecture, build order, all APIs, RELAY protocol (inlined), patterns, gotchas |
| **CHECKLIST_TEMPLATE.md** | Copy this and check off items as you build. Covers all 12 phases |
| **SWAIG_FUNCTION_RESULT_REFERENCE.md** | Exact JSON output for all 41 FunctionResult action methods |
| **SKILLS_MANIFEST.md** | All 17 built-in skills: exact names, params, env vars, tools, prompts |
| **RELAY_IMPLEMENTATION_GUIDE.md** | Standalone RELAY protocol deep-dive (also inlined in PORTING_GUIDE) |

### Cross-language Audit (existing-port maintenance)

| File | Description |
|------|-------------|
| **AUDIT_DISCIPLINE.md** | **READ FIRST** when continuing the audit grind — capability-not-naming framing, MIXIN_PROJECTIONS pattern, full filter rationale, TDD-bidirectional protocol, per-port reflection gotchas |
| **SIGNATURE_AUDIT_PLAN.md** | Phases 0–6 of the audit machinery (architecture, type vocabulary, adapter contracts) |
| **ADAPTER_CONTRACT.md** | Per-port adapter's contract with the audit |
| **AUDIT_LAYERS.md** | Overview of the 11 audit programs |
| **surface_schema_v2.json** | Canonical inventory shape every port adapter emits |
| **type_aliases.yaml** | Per-port native→canonical type translation table |

### API Specifications

| Directory | Description |
|-----------|-------------|
| **rest-apis/** | OpenAPI YAML specs for all REST API namespaces (13 files) |
| **schema.json** | SWML verb schema (12,249 lines) — embed this in your SDK |

### RELAY Protocol Docs

| File | Description |
|------|-------------|
| **call-methods.md** | All Call object methods with parameters |
| **client-reference.md** | RelayClient API reference |
| **events.md** | All 22 event types with fields |
| **getting-started.md** | RELAY quickstart |
| **messaging.md** | SMS/MMS messaging reference |

### REST Client Docs

| File | Description |
|------|-------------|
| **namespaces.md** | All REST API namespaces overview |
| **calling.md** | Calling namespace (37 commands) |
| **fabric.md** | Fabric namespace (16 sub-resources) |
| **compat.md** | Twilio-compatible LAML API |
| **getting-started.md** | REST client quickstart |
| **client-reference.md** | SignalWireClient API reference |

## How to Use This Kit

1. Read **PORTING_GUIDE.md** end-to-end first
2. Copy **CHECKLIST_TEMPLATE.md** to your project as `PROGRESS.md`
3. Copy **schema.json** into your SDK (embed it for verb auto-vivification)
4. Build in the order specified in the guide (Foundation → SWML → Agent → Skills → RELAY → REST)
5. Reference **SWAIG_FUNCTION_RESULT_REFERENCE.md** when implementing action methods
6. Reference **SKILLS_MANIFEST.md** when implementing built-in skills
7. Reference **RELAY_IMPLEMENTATION_GUIDE.md** for protocol details
8. Use **rest-apis/*.yaml** OpenAPI specs for REST namespace implementation

## Existing Ports

| Language | Location | Status |
|----------|----------|--------|
| Python | `signalwire-agents` | Reference implementation |
| TypeScript | `signalwire-agents-typescript` | Complete (95%+ parity) |
| Go | `signalwire-agents-go` | Complete (Phases 1-8, 10-12) |

## Key Principles

1. **The platform handles the AI pipeline** — your SDK just generates SWML and handles webhooks
2. **Schema-driven verbs** — auto-vivify the 38 SWML verb methods from `schema.json`
3. **Method chaining everywhere** — all config methods return self
4. **Dynamic config via ephemeral clones** — never mutate the original agent per-request
5. **RELAY: 4 correlation mechanisms** — get these right or nothing works
6. **Skip search/RAG** — no vector models needed; `native_vector_search` skill uses network mode only
