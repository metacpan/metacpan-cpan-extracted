# PORT_SIGNATURE_OMISSIONS.md

Documented signature divergences between this Perl port and the Python
reference. Names-only divergences live in PORT_OMISSIONS.md /
PORT_ADDITIONS.md and are inherited automatically.

Format:
    <fully.qualified.symbol>: <one-line rationale>

Excused divergences fall into:

1. **Idiom-level** (deliberate, not fixable without breaking Perl API style):
   - Perl Moo classes don't model every Python attribute as a `has` decl
     (e.g. Python's `direction`, `segment_id`, `project_id` keyword-only
     args on `Call` aren't first-class Moo attrs in the Perl port).
   - Perl uses `_log` / `SignalWire::Logging->get_logger(...)` indirection
     where Python keeps a `logger` attribute on every class.
   - Perl SDK wraps a Plack/PSGI coderef; Python wraps a Flask app
     instance accessible via `.app`.

2. **Source-side stubs** (Perl methods that take fewer args because the
   body is a placeholder; the Python reference declares the full
   signature). Tracked here; will be filled in as the Perl port catches
   up. As of 2026-04-30 phase-4 audit: ZERO open source-side stubs —
   all 22 previously-tracked stubs have been closed by accepting the
   Python-canonical signatures and exercising them with Test::More
   tests under t/.


## Idiom: Perl logger / app accessor naming

signalwire.agent_server.AgentServer.app: Perl AgentServer wraps a Plack/PSGI coderef accessible via psgi_app(); Python's `.app` attribute is a Flask app instance — no direct equivalent in Plack land
signalwire.agent_server.AgentServer.logger: Perl uses SignalWire::Logging->get_logger(...) directly rather than a per-class logger attribute; Python keeps a `.logger` accessor on every class
signalwire.core.skill_base.SkillBase.logger: Perl SkillBase doesn't expose a logger attribute; subclasses use SignalWire::Logging directly when they need to log
signalwire.core.skill_manager.SkillManager.logger: Perl SkillManager doesn't expose a logger attribute; logging happens through SignalWire::Logging
signalwire.skills.registry.SkillRegistry.logger: Perl SkillRegistry doesn't expose a logger attribute; logging happens through SignalWire::Logging


## Idiom: Perl method-name renames

signalwire.relay.call.Call.on: Perl ``$call->on($cb)`` is the Perl idiom for registering a single all-events callback; Python's ``Call.on(event_type, handler)`` requires per-event-type registration — different ergonomics, same dispatch model
signalwire.skills.registry.SkillRegistry.register_skill: Perl exposes a two-arg ``register_skill(skill_name, skill_class)`` form that mirrors the underlying registry table; Python's classmethod takes a single ``skill_class`` and reads the name from the class itself


## Idiom: Perl Moo constructor shapes

signalwire.relay.call.Call.__init__: Perl Moo Call doesn't model `project_id`, `direction`, or `segment_id` as `has` attrs (the Perl SDK derives them from the Relay event payload at dispatch time rather than tracking them on the Call object); Python keeps them as constructor kwargs
signalwire.prefabs.survey.SurveyAgent.__init__: Perl SurveyAgent uses `survey_questions` (matching the SDK's other survey_* attrs) where Python uses `questions`; the constructor accepts both via Moo's open hash-arg interface but the canonical Perl attribute name differs


## Idiom: Perl event-class attribute coverage

signalwire.relay.event.CallReceiveEvent.__init__: Perl CallReceive doesn't model `direction`, `project_id`, or `segment_id` as Moo attrs; the Perl event objects expose only the subset the SDK actively consumes
signalwire.relay.event.CollectEvent.__init__: Perl CollectEvent doesn't model `final` flag as a Moo attr; the Perl SDK reads completion state from the underlying CallCollect payload
signalwire.relay.event.ConferenceEvent.__init__: Perl ConferenceEvent doesn't model `name` / `status` as Moo attrs; the Perl SDK reads them from the conference payload directly
signalwire.relay.event.MessageReceiveEvent.__init__: Perl MessageReceive doesn't model the base RelayEvent `call_id` (messaging events are call-id-less)
signalwire.relay.event.MessageStateEvent.__init__: Perl MessageState doesn't model the base RelayEvent `call_id` (messaging events are call-id-less)
signalwire.relay.event.ReferEvent.__init__: Perl ReferEvent doesn't model `sip_refer_to`, `sip_refer_response_code`, `sip_notify_response_code` as Moo attrs; the Perl SDK doesn't expose those SIP details (they live in the underlying CallRefer payload)
signalwire.relay.event.RelayEvent.__init__: Perl base RelayEvent omits `call_id` (subclasses add it where applicable); Python keeps it on the base class with `''` default
signalwire.relay.event.StreamEvent.__init__: Perl StreamEvent doesn't model `url` / `name` as Moo attrs; the Perl SDK reads them from the underlying CallStream payload
signalwire.relay.event.TranscribeEvent.__init__: Perl TranscribeEvent doesn't model `url`, `recording_id`, `duration`, `size` as Moo attrs; the Perl SDK reads them from the underlying CallTranscribe payload


## Idiom: Perl-side helpers replicated on AgentBase

signalwire.core.agent_base.AgentBase.create_tool_token: Perl AgentBase exposes ``create_tool_token`` directly (Moo composition flattens the StateMixin helper onto AgentBase); Python keeps the same helper one level out on a mixin class. Functionally equivalent — the Perl audit reports it as port-only because the Python class itself doesn't redeclare the method.
signalwire.core.agent_base.AgentBase.extract_sip_username: Perl AgentBase keeps a SignalWire-style ``from``/``caller_id_number`` extractor for backward compatibility; Python's ``SWMLService.extract_sip_username`` (the canonical version) checks ``call.to`` and is now also exposed on the Perl SWMLService. The AgentBase helper is a Perl-only convenience.


## Source-side stubs (Perl method bodies don't yet declare full args)

(All previously-listed stubs have been closed. New stubs would live here.)
