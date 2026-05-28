# DOC_AUDIT_IGNORE

<!--
  Names the Layer C doc/example auditor (`porting-sdk/scripts/audit_docs.py`)
  should skip when checking this port's docs and examples.

  Every entry MUST have a rationale. If a name here maps to a real Perl
  API, delete it — the audit will catch typos only when this list is
  tight. If an entry is a genuine external or cross-language carryover,
  keep it with an explanation.

  Format: one name per line; `name: rationale` accepted; `#` comments
  allowed. Free-form prose belongs inside HTML comments like this one.

  The audit's regex treats `word.word(` as a method call. Most entries
  below are Python SDK references that appear inside ```python fenced
  blocks in the docs — the Perl documentation (Layer C content
  migration) reuses the Python SDK's prose and examples to illustrate
  concepts the Perl port mirrors behaviourally. They are NOT references
  to Perl APIs.
-->

## Python stdlib (inside ```python code blocks in docs)

# datetime / time
isoformat: Python stdlib datetime method (Python code block)
fromisoformat: Python stdlib datetime classmethod (Python code block)
total_seconds: Python stdlib timedelta method (Python code block)

# logging / os.path — Python standard library utility calls in example code
basicConfig: Python stdlib logging.basicConfig (Python code block)
getLogger: Python stdlib logging.getLogger (Python code block)
setLevel: Python stdlib logging.Logger.setLevel (Python code block)
warning: Python stdlib logging.Logger.warning (Python code block)
abspath: Python stdlib os.path.abspath (Python code block)

# threading — Python's `threading.Thread(...)` inside a web-service code sample
Thread: Python stdlib threading.Thread constructor (Python code block)

## Python SignalWire SDK API (shown for concept parity, not Perl API)

# AgentBase / SkillBase camelCase convenience aliases (Python sugar only)
setGoal: Python convenience wrapper for prompt_add_section (Python code block)
setInstructions: Python convenience wrapper for prompt_add_section (Python code block)
setPersonality: Python convenience wrapper for prompt_add_section (Python code block)

# SWMLService document lifecycle (Python prose; Perl port exposes
# equivalent semantics via the generated document)
build_document: Python SWMLService lifecycle method (Python code block)
build_voicemail_document: Python SWMLService subclass override (Python code block)
reset_document: Python SWMLService lifecycle method (Python code block)
get_document: Python SWMLService accessor (Python code block)
add_answer_verb: Python SWMLService helper (Python code block)
add_verb_to_section: Python SWMLService helper (Python code block)
register_verb_handler: Python SWMLService extension hook (Python code block)

# SIP routing — Python SDK mixins (Perl port offers equivalent routing
# via SWML + AgentServer; these exact names are Python-only)
enable_sip_routing: Python SDK mixin method (Python code block)
register_sip_username: Python SDK mixin method (Python code block)
register_routing_callback: Python SDK mixin method (Python code block)
setup_sip_routing: Python AgentServer method (Python code block)
register_customer_route: Python user-defined route (Python code block)
register_product_route: Python user-defined route (Python code block)

# FastAPI / Starlette ecosystem (shown in Python web_service examples)
as_router: Python FastAPI router bridge (Python code block)
include_router: Python FastAPI router composition (Python code block)
add_directory: Python FastAPI StaticFiles mount (Python code block)
remove_directory: Python FastAPI StaticFiles unmount (Python code block)

# Relay event / call methods (Python-only names; Perl Relay uses
# idiomatic method names -- see relay/docs for Perl forms)
from_payload: Python Relay event classmethod (Python code block)
wait_for: Python Relay Call wait_for method (Python code block)
wait_for_ended: Python Relay Call wait_for_ended method (Python code block)
pass_: Python Relay Call pass_ method - suffix underscore because `pass` is a Python reserved keyword (Python code block)

# Miscellaneous Python SDK method names in illustrative snippets
add_application: Python SWML helper (Python code block)
allow_functions: Python AgentBase secure-functions helper (Python code block)
enable_record_call: Python AgentBase record helper (Python code block)
handle_serverless_request: Python Lambda/Cloud Run entrypoint (Python code block)
list_all_skill_sources: Python skills registry helper (Python code block)
on_completion_go_to: Python contexts transition helper (Python code block)
register_default_tools: Python agent-internal helper (Python code block)
register_knowledge_base_tool: Python agent-internal helper (Python code block)
setup_google_search: Python skill bootstrap helper (Python code block)
start: Python web-service/agent-server start method (Python code block)
tool: Python @AgentBase.tool(...) decorator (Python code block, decorator syntax)
validate_packages: Python third-party skills helper (Python code block)

## User-code placeholders in pedagogical Python snippets

<!--
  These names appear inside illustrative Python examples where they stand
  for code the READER would write (custom configs, analytics hooks,
  sample business logic). They are not API to implement.
-->

alert_ops_team: user-supplied hook in prose example (Python code block)
apply_custom_config: user-supplied hook in prose example (Python code block)
apply_default_config: user-supplied hook in prose example (Python code block)
delete_state: user-supplied state store method in prose example (Python code block)
get_config: user-supplied config accessor in prose example (Python code block)
get_customer_config: user-supplied hook in prose example (Python code block)
get_customer_settings: user-supplied hook in prose example (Python code block)
get_customer_tier: user-supplied hook in prose example (Python code block)
get_state: user-supplied state store method in prose example (Python code block)
has_config: user-supplied config accessor in prose example (Python code block)
is_valid_customer: user-supplied hook in prose example (Python code block)
load_user_preferences: user-supplied hook in prose example (Python code block)
schedule_follow_up: user-supplied hook in prose example (Python code block)
send_to_analytics: user-supplied hook in prose example (Python code block)
update_state: user-supplied state store method in prose example (Python code block)

## Private/underscored helpers in Python examples

<!--
  Leading-underscore Python method names inside illustrative Python code
  blocks showing how Python's AgentBase is extended internally. They are
  not Perl port surface.
-->

_check_basic_auth: Python internal helper referenced in subclassing example
_configure_instructions: Python internal helper referenced in subclassing example
_get_new_messages: Python internal helper referenced in subclassing example
_register_custom_tools: Python internal helper referenced in subclassing example
_register_default_tools: Python internal helper referenced in subclassing example
_setup_contexts: Python internal helper referenced in subclassing example
_setup_static_config: Python internal helper referenced in subclassing example
_test_api_connection: Python internal helper referenced in subclassing example

## Regex false positives

<!--
  The `.name(` regex fires on strings that happen to contain a dot-word
  followed by `(`. These are not method calls.
-->

Mark: part of the voice identifier "inworld.Mark" in comments/strings (e.g. `voice => 'inworld.Mark'` inside a hashref - not a method call)
pl: appears in the substring ".pl(" inside the comment "joke_agent.pl (raw data_map)."

## Audit-harness internals

<!--
  examples/relay_audit_harness.pl uses a private hook on Relay::Client to
  emit a method-bearing JSON-RPC frame back to the audit fixture (the
  fixture watches for `method:"signalwire.event"` from the client to
  count an event as dispatched; Python's bare-result ack does not
  satisfy that watcher). Calling the private helper from a harness is
  intentional and not part of the public API surface.
-->
_send: private hook used by examples/relay_audit_harness.pl to emit method-bearing ack frame to the audit fixture

## Private agent/swmlservice render helpers used by examples

<!--
  Some Perl examples drive Plack::Runner directly via `parse_options`
  (real Perl module method, in the Plack distribution — not part of the
  port's public surface) before handing the resulting PSGI app to the
  runner. The audit's regex picks up the method call but it isn't a
  port symbol.
-->
parse_options: Plack::Runner method called by SWML standalone examples
sleep: Perl built-in (and the SWML `sleep` verb the auto-vivified example illustrates) — appears in `sleep(...)` syntax inside an example
delete_resource: Python REST namespace helper described in fabric.md prose; Perl REST resources expose `delete()` directly per CRUD pattern
new: Perl/Moo constructor — appears in 148+ ClassName->new(...) call sites in docs and examples; not a port symbol to resolve
set_question_callback: example placeholder representing a user-supplied per-question handler in the dynamic InfoGatherer demo (not a port API)
