# PORT_ADDITIONS.md

Symbols the Perl port ships that have no Python-reference equivalent.
One line per symbol: `<fully.qualified.symbol>: <one-sentence rationale>`.
Checked by `scripts/diff_port_surface.py` against `python_surface.json`.

See also: PORT_OMISSIONS.md for Python-reference symbols we deliberately skip.

---

signalwire.agent_server.AgentServer.list_agents: port-only accessor: Perl convention surfaces a list-style getter where Python uses a generator or direct attribute access
signalwire.agent_server.AgentServer.psgi_app: port-only: Perl ports use Plack/PSGI; psgi_app returns a coderef any Plack handler consumes
signalwire.core.agent_base.AgentBase.create_tool_token: prompt_mixin_lifted: Perl rolls up StateMixin / SessionManager onto AgentBase so callers don't reach into a sub-object — mirrors the documented tool_mixin_lifted pattern
signalwire.core.agent_base.AgentBase.get_contexts: prompt_mixin_lifted: Perl AgentBase exposes a get_contexts() accessor for the contexts list; Python uses PromptMixin.contexts (attribute access)
signalwire.core.agent_base.AgentBase.get_post_prompt: prompt_mixin_lifted: Perl rolls up PromptMixin onto AgentBase; Python keeps these on PromptMixin (mirrors tool_mixin_lifted pattern)
signalwire.core.agent_base.AgentBase.get_raw_prompt: prompt_mixin_lifted: Perl rolls up PromptMixin onto AgentBase; Python keeps these on PromptMixin (mirrors tool_mixin_lifted pattern)
signalwire.core.agent_base.AgentBase.list_tool_names: port-only helper used by ContextBuilder->validate to surface reserved-name collisions
signalwire.core.agent_base.AgentBase.pom: port-only Perl accessor returning the underlying SignalWire::POM::PromptObjectModel instance; Python keeps the POM private inside PromptMixin
signalwire.core.agent_base.AgentBase.psgi_app: port-only: Perl ports use Plack/PSGI; psgi_app returns a coderef any Plack handler consumes
signalwire.core.agent_base.AgentBase.render_swml: port-only public alias: Perl exposes render_swml as the method users call to dump SWML; Python keeps this internal
signalwire.core.agent_base.AgentBase.set_answer_config: port-only helper: wires AnswerConfig into SWML rendering; Python threads these through AIConfigMixin
signalwire.core.agent_base.AgentBase.set_prompt_pom: prompt_mixin_lifted: Perl rolls up PromptMixin onto AgentBase; Python keeps these on PromptMixin (mirrors tool_mixin_lifted pattern)
signalwire.core.agent_base.AgentBase.validate_tool_token: prompt_mixin_lifted: Perl rolls up StateMixin onto AgentBase; Python keeps validate_tool_token on StateMixin (mirrors tool_mixin_lifted pattern)
signalwire.core.contexts.ContextBuilder.attach_agent: port-only: weak-ref back to agent so validate() can check reserved tool-name collisions; Python avoids this via Python-level closures
signalwire.core.contexts.ContextBuilder.has_contexts: port-only: explicit presence check used in AgentBase build path; Python uses `if cb.contexts` idiom
signalwire.core.contexts.ContextBuilder.to_hashref: port-only: alias to to_dict that returns the nested hashref explicitly (Perl idiom)
signalwire.core.function_result.FunctionResult.to_json: port-only: convenience serializer; Python uses json.dumps(result.to_dict())
signalwire.core.logging_config.debug: port-only: Perl exports package-level logging functions; Python uses a logger handle (get_logger().debug(...))
signalwire.core.logging_config.error: port-only: Perl exports package-level logging functions; Python uses a logger handle (get_logger().debug(...))
signalwire.core.logging_config.info: port-only: Perl exports package-level logging functions; Python uses a logger handle (get_logger().debug(...))
signalwire.core.logging_config.warn: port-only: Perl exports package-level logging functions; Python uses a logger handle (get_logger().debug(...))
signalwire.core.skill_manager.SkillManager.list_skills: port-only accessor: Perl convention surfaces a list-style getter where Python uses a generator or direct attribute access
signalwire.core.swml_builder.SWMLBuilder.add_raw_verb: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_builder.SWMLBuilder.add_verb: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_builder.SWMLBuilder.clear_section: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_builder.SWMLBuilder.get_section: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_builder.SWMLBuilder.has_section: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_builder.SWMLBuilder.to_hash: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_builder.SWMLBuilder.to_json: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_builder.SWMLBuilder.to_pretty_json: port-only: SWML::Document public helper that Python keeps on SWMLService or private
signalwire.core.swml_service.SWMLService.can: port-only: Perl can() accessor (Moo plumbing) — surfaced because SWMLService defines it; harmless but recorded
signalwire.core.swml_service.SWMLService.define_tool: tool_mixin_lifted: Perl folds Python's ToolMixin (which Python composes into AgentBase) directly into SWMLService — so SWMLService standalone can host SWAIG tools without subclassing AgentBase. Mirrors Python's ToolMixin.define_tool exactly; just lives on a different class.
signalwire.core.swml_service.SWMLService.define_tools: tool_mixin_lifted: see SWMLService.define_tool note. Mirrors Python's ToolMixin.define_tools.
signalwire.core.swml_service.SWMLService.get_all_functions: tool_mixin_lifted: Perl exposes the tool registry's accessors directly on SWMLService; Python keeps these on ToolRegistry (accessed via agent.tool_registry.get_all_functions()).
signalwire.core.swml_service.SWMLService.get_basic_auth_credentials_with_source: port-only: Perl exposes a "with-source" variant that also returns where the credentials came from (env vs config vs explicit), used by debug routes; Python uses get_basic_auth_credentials() and infers source from logs.
signalwire.core.swml_service.SWMLService.get_function: tool_mixin_lifted: Perl exposes the tool registry's accessors directly on SWMLService; Python keeps these on ToolRegistry (accessed via agent.tool_registry.get_function()).
signalwire.core.swml_service.SWMLService.handle_additional_route: port-only: Perl exposes a hook for subclasses to mount extra routes onto the inherited PSGI app; Python achieves this via @app.route decorators.
signalwire.core.swml_service.SWMLService.has_function: tool_mixin_lifted: Perl exposes the tool registry's accessors directly on SWMLService; Python keeps these on ToolRegistry (accessed via agent.tool_registry.has_function()).
signalwire.core.swml_service.SWMLService.list_tool_names: port-only convenience accessor: returns the registered tool names in insertion order. Used by ContextBuilder->validate to surface reserved-name collisions; Python uses `cb._tools.keys()` directly.
signalwire.core.swml_service.SWMLService.on_function_call: tool_mixin_lifted: see SWMLService.define_tool note. Mirrors Python's ToolMixin.on_function_call.
signalwire.core.swml_service.SWMLService.on_swml_request: web_mixin_lifted: Perl rolls up WebMixin onto SWMLService so subclasses (notably AgentBase) can override the SWML-request hook directly; Python keeps on_swml_request on WebMixin (mirrors tool_mixin_lifted pattern).
signalwire.core.swml_service.SWMLService.register_swaig_function: tool_mixin_lifted: see SWMLService.define_tool note. Mirrors Python's ToolMixin.register_swaig_function.
signalwire.core.swml_service.SWMLService.remove_function: tool_mixin_lifted: Perl exposes the tool registry's mutators directly on SWMLService; Python keeps these on ToolRegistry (accessed via agent.tool_registry.remove_function()).
signalwire.core.swml_service.SWMLService.render_main_swml: port-only public hook: Perl exposes the main-section render path so subclasses can override; Python achieves this via _render_document overrides.
signalwire.core.swml_service.SWMLService.render_swml: port-only public alias: Perl exposes render_swml as the method users call to dump SWML; Python keeps this internal
signalwire.core.swml_service.SWMLService.swaig_pre_dispatch: port-only public hook: subclasses (notably AgentBase) override this to inject session-token validation and dynamic-config callbacks into the /swaig request path; Python uses _swaig_pre_dispatch (private with leading underscore).
signalwire.core.swml_service.SWMLService.to_psgi_app: port-only: Perl ports use Plack/PSGI; psgi_app returns a coderef any Plack handler consumes
signalwire.skills.datasphere.skill.DataSphereSkill.search_knowledge: port-only public method: Perl exposes the search call as a public method so the audit harness can drive it directly without going through the full SWAIG dispatch path. Python keeps the equivalent (_search_knowledge_handler) private.
signalwire.skills.spider.skill.SpiderSkill.scrape_url: port-only public method: Perl exposes the fetch+strip path as a public method so the audit harness can drive it without going through SWAIG dispatch. Python keeps the equivalent (_scrape_url_handler) private.
signalwire.skills.web_search.skill.WebSearchSkill.search_web: port-only public method: Perl exposes the Google-CSE call as a public method so the audit harness can drive it without going through SWAIG dispatch. Python keeps the equivalent (_search_web_handler) private.
signalwire.relay.call.Action.on_completed: port-only Action/Message helper; Python packs this into wait()/dispatch paths
signalwire.relay.call.Action.stop: port-only Action/Message helper; Python packs this into wait()/dispatch paths
signalwire.relay.call.Call.dispatch_event: port-only dispatcher/passthrough helper for Perl-idiomatic event plumbing
signalwire.relay.call.Call.pass: port-only dispatcher/passthrough helper for Perl-idiomatic event plumbing
signalwire.relay.call.CollectAction.collect_result: port-only: strongly-typed Perl accessor for the result payload on each Action subclass
signalwire.relay.call.DetectAction.detect_result: port-only: strongly-typed Perl accessor for the result payload on each Action subclass
signalwire.relay.call.FaxAction.fax_result: port-only: strongly-typed Perl accessor for the result payload on each Action subclass
signalwire.relay.call.PayAction.pay_result: port-only: strongly-typed Perl accessor for the result payload on each Action subclass
signalwire.relay.call.RecordAction.duration: port-only: Perl RecordAction exposes url/duration/size as explicit accessors; Python uses attribute-style access
signalwire.relay.call.RecordAction.size: port-only: Perl RecordAction exposes url/duration/size as explicit accessors; Python uses attribute-style access
signalwire.relay.call.RecordAction.url: port-only: Perl RecordAction exposes url/duration/size as explicit accessors; Python uses attribute-style access
signalwire.relay.client.Constants: port-only: SignalWire::Relay::Constants holds Blade/JSON-RPC constants; Python inlines them
signalwire.relay.client.RelayClient.authenticate: port-only: Perl surfaces individual WebSocket lifecycle steps; Python packs these into connect()
signalwire.relay.client.RelayClient.connect_ws: port-only: Perl surfaces individual WebSocket lifecycle steps; Python packs these into connect()
signalwire.relay.client.RelayClient.disconnect_ws: port-only: Perl surfaces individual WebSocket lifecycle steps; Python packs these into connect()
signalwire.relay.client.RelayClient.on_event: port-only: Perl surfaces individual WebSocket lifecycle steps; Python packs these into connect()
signalwire.relay.client.RelayClient.reconnect: port-only: Perl surfaces individual WebSocket lifecycle steps; Python packs these into connect()
signalwire.relay.event.AuthorizationStateEvent: port-only event subclass Perl emits explicitly; Python folds these into RelayEvent/CallState
signalwire.relay.event.CallDisconnectEvent: port-only event subclass Perl emits explicitly; Python folds these into RelayEvent/CallState
signalwire.relay.event.DisconnectEvent: port-only event subclass Perl emits explicitly; Python folds these into RelayEvent/CallState
signalwire.relay.event.RelayEvent.parse_event: port-only: Perl uses a class-method parser; Python uses the module-level parse_event() function
signalwire.relay.message.Message.dispatch_event: port-only dispatcher/passthrough helper for Perl-idiomatic event plumbing
signalwire.relay.message.Message.on_completed: port-only dispatcher/passthrough helper for Perl-idiomatic event plumbing
signalwire.rest._pagination.PaginatedIterator.all: port-only: drains the iterator into a list (Perl idiom for `list(iter)`); Python uses `list(it)` directly
signalwire.rest.call_handler.PhoneCallHandler.values: port-only: authoritative list accessor for the enum; Python uses the enum class directly
signalwire.rest.namespaces.calling.CallingNamespace.update_call: port-only helper for updating an in-flight call; Python clients use client.calls(sid).update()
signalwire.rest.namespaces.fabric.AddressesResource: port-only: Perl Fabric::Addresses is a resource class that extends Base; Python uses FabricAddresses (under a different name) or folds addresses into Resource
signalwire.rest.namespaces.fabric.AddressesResource.get: port-only: Perl Fabric::Addresses is a resource class that extends Base; Python uses FabricAddresses (under a different name) or folds addresses into Resource
signalwire.rest.namespaces.fabric.AddressesResource.list: port-only: Perl Fabric::Addresses is a resource class that extends Base; Python uses FabricAddresses (under a different name) or folds addresses into Resource
signalwire.rest.namespaces.fabric.FabricResource.list_addresses: crud_with_addresses_lifted: Perl folds Python's CrudWithAddresses.list_addresses mixin onto the FabricResource base class so all fabric resource classes inherit it; Python keeps it on the abstract CrudWithAddresses parent.
signalwire.rest.namespaces.fabric.Resource: port-only: internal helper class for the Fabric resource indirection; Python does not expose a top-level Resource class
signalwire.rest.namespaces.fabric.Resource.list_addresses: port-only: internal helper class for the Fabric resource indirection; Python does not expose a top-level Resource class
signalwire.rest.namespaces.fabric.ResourcePUT: port-only: internal helper class for the Fabric resource indirection; Python does not expose a top-level Resource class
signalwire.skills.registry.CustomSkills: port-only: SignalWire::Skills::Builtin::CustomSkills is the Perl harness for loading user-supplied skill packages; Python has no equivalent class
signalwire.skills.registry.CustomSkills.get_parameter_schema: port-only: SignalWire::Skills::Builtin::CustomSkills is the Perl harness for loading user-supplied skill packages; Python has no equivalent class
signalwire.skills.registry.CustomSkills.register_tools: port-only: SignalWire::Skills::Builtin::CustomSkills is the Perl harness for loading user-supplied skill packages; Python has no equivalent class
signalwire.skills.registry.CustomSkills.setup: port-only: SignalWire::Skills::Builtin::CustomSkills is the Perl harness for loading user-supplied skill packages; Python has no equivalent class
signalwire.skills.registry.SkillRegistry.clear_registry: port-only registry helper: Perl exposes these for test isolation and dynamic loading
signalwire.skills.registry.SkillRegistry.get_factory: port-only registry helper: Perl exposes these for test isolation and dynamic loading
signalwire.utils.schema_utils.SchemaUtils.get_verb: port-only: Perl SchemaUtils exposes verb-introspection helpers (get_verb, get_verb_names, has_verb, verb_count, instance); Python keeps these internal
signalwire.utils.schema_utils.SchemaUtils.get_verb_names: port-only: Perl SchemaUtils exposes verb-introspection helpers (get_verb, get_verb_names, has_verb, verb_count, instance); Python keeps these internal
signalwire.utils.schema_utils.SchemaUtils.has_verb: port-only: Perl SchemaUtils exposes verb-introspection helpers (get_verb, get_verb_names, has_verb, verb_count, instance); Python keeps these internal
signalwire.utils.schema_utils.SchemaUtils.instance: port-only: Perl SchemaUtils exposes verb-introspection helpers (get_verb, get_verb_names, has_verb, verb_count, instance); Python keeps these internal
signalwire.utils.schema_utils.SchemaUtils.verb_count: port-only: Perl SchemaUtils exposes verb-introspection helpers (get_verb, get_verb_names, has_verb, verb_count, instance); Python keeps these internal
signalwire.rest._base.CrudResource.delete_resource: perl-idiom port-only: Perl reserves the bareword ``delete`` for the built-in hash operator, so the canonical method is ``delete_resource``; the Python parity alias ``delete`` is also exposed
signalwire.rest._base.HttpClient.delete_request: perl-idiom port-only: Perl reserves the bareword ``delete`` for the built-in hash operator, so HttpClient exposes ``delete_request``; the Python parity alias ``delete`` is also exposed
signalwire.rest.namespaces.compat.CompatPhoneNumbers.delete_number: perl-idiom port-only: Compat resource keeps the domain-named ``delete_number`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.compat.CompatRecordings.delete_recording: perl-idiom port-only: Compat resource keeps the domain-named ``delete_recording`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.compat.CompatTokens.delete_token: perl-idiom port-only: Compat resource keeps the domain-named ``delete_token`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.compat.CompatTranscriptions.delete_transcription: perl-idiom port-only: Compat resource keeps the domain-named ``delete_transcription`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.fabric.GenericResources.delete_resource: perl-idiom port-only: Fabric GenericResources exposes ``delete_resource`` directly (the Python parity ``delete`` alias is also offered)
signalwire.rest.namespaces.project.ProjectTokens.delete_token: perl-idiom port-only: ProjectTokens keeps the domain-named ``delete_token`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.recordings.RecordingsResource.delete_recording: perl-idiom port-only: RecordingsResource keeps the domain-named ``delete_recording`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.registry.RegistryNumbers.delete_number: perl-idiom port-only: RegistryNumbers keeps the domain-named ``delete_number`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.video.VideoRoomRecordings.delete_recording: perl-idiom port-only: VideoRoomRecordings keeps the domain-named ``delete_recording`` alongside the Python-parity ``delete`` alias
signalwire.rest.namespaces.video.VideoStreams.delete_stream: perl-idiom port-only: VideoStreams keeps the domain-named ``delete_stream`` alongside the Python-parity ``delete`` alias
signalwire.core.security.webhook_middleware.wrap: perl-idiom port-only: Plack middleware wrap() instance method (Plack convention) — Python uses make_webhook_validation_dependency factory function instead
