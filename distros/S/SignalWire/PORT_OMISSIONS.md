# PORT_OMISSIONS.md

Python-reference symbols the Perl port deliberately does not implement.
One line per symbol: `<fully.qualified.symbol>: <one-sentence rationale>`.
Checked by `scripts/diff_port_surface.py` against `python_surface.json`.

See also: PORT_ADDITIONS.md for Perl-only extensions.

---

## search-subsystem

The search/RAG subsystem (vector search, pgvector, index builder, query processor, document processor, migration tooling, sw-search CLI) is explicitly out of scope for ports per `porting-sdk/PORTING_GUIDE.md` § What to Skip. Ports support the `native_vector_search` skill only in network mode, which Perl does.

signalwire.search.document_processor.DocumentProcessor: search-subsystem
signalwire.search.document_processor.DocumentProcessor.__init__: search-subsystem
signalwire.search.document_processor.DocumentProcessor.create_chunks: search-subsystem
signalwire.search.index_builder.IndexBuilder: search-subsystem
signalwire.search.index_builder.IndexBuilder.__init__: search-subsystem
signalwire.search.index_builder.IndexBuilder.build_index: search-subsystem
signalwire.search.index_builder.IndexBuilder.build_index_from_sources: search-subsystem
signalwire.search.index_builder.IndexBuilder.validate_index: search-subsystem
signalwire.search.migration.SearchIndexMigrator: search-subsystem
signalwire.search.migration.SearchIndexMigrator.__init__: search-subsystem
signalwire.search.migration.SearchIndexMigrator.get_index_info: search-subsystem
signalwire.search.migration.SearchIndexMigrator.migrate_pgvector_to_sqlite: search-subsystem
signalwire.search.migration.SearchIndexMigrator.migrate_sqlite_to_pgvector: search-subsystem
signalwire.search.models.resolve_model_alias: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend.__init__: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend.close: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend.create_schema: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend.delete_collection: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend.get_stats: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend.list_collections: search-subsystem
signalwire.search.pgvector_backend.PgVectorBackend.store_chunks: search-subsystem
signalwire.search.pgvector_backend.PgVectorSearchBackend: search-subsystem
signalwire.search.pgvector_backend.PgVectorSearchBackend.__init__: search-subsystem
signalwire.search.pgvector_backend.PgVectorSearchBackend.close: search-subsystem
signalwire.search.pgvector_backend.PgVectorSearchBackend.fetch_candidates: search-subsystem
signalwire.search.pgvector_backend.PgVectorSearchBackend.get_stats: search-subsystem
signalwire.search.pgvector_backend.PgVectorSearchBackend.search: search-subsystem
signalwire.search.query_processor.detect_language: search-subsystem
signalwire.search.query_processor.ensure_nltk_resources: search-subsystem
signalwire.search.query_processor.get_synonyms: search-subsystem
signalwire.search.query_processor.get_wordnet_pos: search-subsystem
signalwire.search.query_processor.load_spacy_model: search-subsystem
signalwire.search.query_processor.preprocess_document_content: search-subsystem
signalwire.search.query_processor.preprocess_query: search-subsystem
signalwire.search.query_processor.remove_duplicate_words: search-subsystem
signalwire.search.query_processor.set_global_model: search-subsystem
signalwire.search.query_processor.vectorize_query: search-subsystem
signalwire.search.search_engine.SearchEngine: search-subsystem
signalwire.search.search_engine.SearchEngine.__init__: search-subsystem
signalwire.search.search_engine.SearchEngine.get_stats: search-subsystem
signalwire.search.search_engine.SearchEngine.search: search-subsystem
signalwire.search.search_service.SearchService: search-subsystem
signalwire.search.search_service.SearchService.__init__: search-subsystem
signalwire.search.search_service.SearchService.search_direct: search-subsystem
signalwire.search.search_service.SearchService.start: search-subsystem
signalwire.search.search_service.SearchService.stop: search-subsystem
signalwire.skills.native_vector_search.skill.NativeVectorSearchSkill.cleanup: search-subsystem
signalwire.skills.native_vector_search.skill.NativeVectorSearchSkill.get_global_data: search-subsystem
signalwire.skills.native_vector_search.skill.NativeVectorSearchSkill.get_instance_key: search-subsystem
signalwire.skills.native_vector_search.skill.NativeVectorSearchSkill.get_prompt_sections: search-subsystem

## bedrock-niche

BedrockAgent is called out as niche and deferred in `porting-sdk/PORTING_GUIDE.md` § What to Skip. Not implemented in the Perl port; will add when there is demand.

signalwire.agents.bedrock.BedrockAgent: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.__init__: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.__repr__: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.set_inference_params: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.set_llm_model: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.set_llm_temperature: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.set_post_prompt_llm_params: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.set_prompt_llm_params: bedrock-niche
signalwire.agents.bedrock.BedrockAgent.set_voice: bedrock-niche

## livewire-python-only

The `signalwire.livewire` compatibility shim is a Python-only adapter for the LiveKit Agents framework (`porting-sdk/PORTING_GUIDE.md` § LiveKit Compatibility Shim). It has no equivalent Perl toolchain, so the port does not ship it.

signalwire.livewire.Agent: livewire-python-only
signalwire.livewire.Agent.__init__: livewire-python-only
signalwire.livewire.Agent.llm_node: livewire-python-only
signalwire.livewire.Agent.on_enter: livewire-python-only
signalwire.livewire.Agent.on_exit: livewire-python-only
signalwire.livewire.Agent.on_user_turn_completed: livewire-python-only
signalwire.livewire.Agent.session: livewire-python-only
signalwire.livewire.Agent.stt_node: livewire-python-only
signalwire.livewire.Agent.tts_node: livewire-python-only
signalwire.livewire.Agent.update_instructions: livewire-python-only
signalwire.livewire.Agent.update_tools: livewire-python-only
signalwire.livewire.AgentHandoff: livewire-python-only
signalwire.livewire.AgentHandoff.__init__: livewire-python-only
signalwire.livewire.AgentServer: livewire-python-only
signalwire.livewire.AgentServer.__init__: livewire-python-only
signalwire.livewire.AgentServer.rtc_session: livewire-python-only
signalwire.livewire.AgentSession: livewire-python-only
signalwire.livewire.AgentSession.__init__: livewire-python-only
signalwire.livewire.AgentSession.generate_reply: livewire-python-only
signalwire.livewire.AgentSession.history: livewire-python-only
signalwire.livewire.AgentSession.interrupt: livewire-python-only
signalwire.livewire.AgentSession.say: livewire-python-only
signalwire.livewire.AgentSession.start: livewire-python-only
signalwire.livewire.AgentSession.update_agent: livewire-python-only
signalwire.livewire.AgentSession.userdata: livewire-python-only
signalwire.livewire.ChatContext: livewire-python-only
signalwire.livewire.ChatContext.__init__: livewire-python-only
signalwire.livewire.ChatContext.append: livewire-python-only
signalwire.livewire.InferenceLLM: livewire-python-only
signalwire.livewire.InferenceLLM.__init__: livewire-python-only
signalwire.livewire.InferenceSTT: livewire-python-only
signalwire.livewire.InferenceSTT.__init__: livewire-python-only
signalwire.livewire.InferenceTTS: livewire-python-only
signalwire.livewire.InferenceTTS.__init__: livewire-python-only
signalwire.livewire.JobContext: livewire-python-only
signalwire.livewire.JobContext.__init__: livewire-python-only
signalwire.livewire.JobContext.connect: livewire-python-only
signalwire.livewire.JobContext.wait_for_participant: livewire-python-only
signalwire.livewire.JobProcess: livewire-python-only
signalwire.livewire.JobProcess.__init__: livewire-python-only
signalwire.livewire.Room: livewire-python-only
signalwire.livewire.RunContext: livewire-python-only
signalwire.livewire.RunContext.__init__: livewire-python-only
signalwire.livewire.RunContext.userdata: livewire-python-only
signalwire.livewire.StopResponse: livewire-python-only
signalwire.livewire.ToolError: livewire-python-only
signalwire.livewire.function_tool: livewire-python-only
signalwire.livewire.plugins.CartesiaTTS: livewire-python-only
signalwire.livewire.plugins.CartesiaTTS.__init__: livewire-python-only
signalwire.livewire.plugins.DeepgramSTT: livewire-python-only
signalwire.livewire.plugins.DeepgramSTT.__init__: livewire-python-only
signalwire.livewire.plugins.ElevenLabsTTS: livewire-python-only
signalwire.livewire.plugins.ElevenLabsTTS.__init__: livewire-python-only
signalwire.livewire.plugins.OpenAILLM: livewire-python-only
signalwire.livewire.plugins.OpenAILLM.__init__: livewire-python-only
signalwire.livewire.plugins.SileroVAD: livewire-python-only
signalwire.livewire.plugins.SileroVAD.__init__: livewire-python-only
signalwire.livewire.plugins.SileroVAD.load: livewire-python-only
signalwire.livewire.run_app: livewire-python-only

## cli-python-tooling

The `signalwire.cli` package bundles interactive project generators (dokku/init-project), swaig-test simulation, dynamic config loading, and mock environment harnesses. These are Python-specific dev tooling that the Perl port has not built out. Users interact with the Perl SDK directly via scripts and PSGI rather than through CLI wrappers.

signalwire.cli.build_search.console_entry_point: cli-python-tooling
signalwire.cli.build_search.main: cli-python-tooling
signalwire.cli.build_search.migrate_command: cli-python-tooling
signalwire.cli.build_search.remote_command: cli-python-tooling
signalwire.cli.build_search.search_command: cli-python-tooling
signalwire.cli.build_search.validate_command: cli-python-tooling
signalwire.cli.core.agent_loader.discover_agents_in_file: cli-python-tooling
signalwire.cli.core.agent_loader.discover_services_in_file: cli-python-tooling
signalwire.cli.core.agent_loader.load_agent_from_file: cli-python-tooling
signalwire.cli.core.agent_loader.load_service_from_file: cli-python-tooling
signalwire.cli.core.argparse_helpers.CustomArgumentParser: cli-python-tooling
signalwire.cli.core.argparse_helpers.CustomArgumentParser.__init__: cli-python-tooling
signalwire.cli.core.argparse_helpers.CustomArgumentParser.error: cli-python-tooling
signalwire.cli.core.argparse_helpers.CustomArgumentParser.parse_args: cli-python-tooling
signalwire.cli.core.argparse_helpers.CustomArgumentParser.print_usage: cli-python-tooling
signalwire.cli.core.argparse_helpers.parse_function_arguments: cli-python-tooling
signalwire.cli.core.dynamic_config.apply_dynamic_config: cli-python-tooling
signalwire.cli.core.service_loader.ServiceCapture: cli-python-tooling
signalwire.cli.core.service_loader.ServiceCapture.__init__: cli-python-tooling
signalwire.cli.core.service_loader.ServiceCapture.capture: cli-python-tooling
signalwire.cli.core.service_loader.discover_agents_in_file: cli-python-tooling
signalwire.cli.core.service_loader.load_agent_from_file: cli-python-tooling
signalwire.cli.core.service_loader.load_and_simulate_service: cli-python-tooling
signalwire.cli.core.service_loader.simulate_request_to_service: cli-python-tooling
signalwire.cli.dokku.Colors: cli-python-tooling
signalwire.cli.dokku.DokkuProjectGenerator: cli-python-tooling
signalwire.cli.dokku.DokkuProjectGenerator.__init__: cli-python-tooling
signalwire.cli.dokku.DokkuProjectGenerator.generate: cli-python-tooling
signalwire.cli.dokku.cmd_config: cli-python-tooling
signalwire.cli.dokku.cmd_deploy: cli-python-tooling
signalwire.cli.dokku.cmd_init: cli-python-tooling
signalwire.cli.dokku.cmd_logs: cli-python-tooling
signalwire.cli.dokku.cmd_scale: cli-python-tooling
signalwire.cli.dokku.generate_password: cli-python-tooling
signalwire.cli.dokku.main: cli-python-tooling
signalwire.cli.dokku.print_error: cli-python-tooling
signalwire.cli.dokku.print_header: cli-python-tooling
signalwire.cli.dokku.print_step: cli-python-tooling
signalwire.cli.dokku.print_success: cli-python-tooling
signalwire.cli.dokku.print_warning: cli-python-tooling
signalwire.cli.dokku.prompt: cli-python-tooling
signalwire.cli.dokku.prompt_yes_no: cli-python-tooling
signalwire.cli.execution.datamap_exec.execute_datamap_function: cli-python-tooling
signalwire.cli.execution.datamap_exec.simple_template_expand: cli-python-tooling
signalwire.cli.execution.webhook_exec.execute_external_webhook_function: cli-python-tooling
signalwire.cli.init_project.Colors: cli-python-tooling
signalwire.cli.init_project.ProjectGenerator: cli-python-tooling
signalwire.cli.init_project.ProjectGenerator.__init__: cli-python-tooling
signalwire.cli.init_project.ProjectGenerator.generate: cli-python-tooling
signalwire.cli.init_project.generate_password: cli-python-tooling
signalwire.cli.init_project.get_agent_template: cli-python-tooling
signalwire.cli.init_project.get_app_template: cli-python-tooling
signalwire.cli.init_project.get_env_credentials: cli-python-tooling
signalwire.cli.init_project.get_readme_template: cli-python-tooling
signalwire.cli.init_project.get_test_template: cli-python-tooling
signalwire.cli.init_project.get_web_index_template: cli-python-tooling
signalwire.cli.init_project.main: cli-python-tooling
signalwire.cli.init_project.mask_token: cli-python-tooling
signalwire.cli.init_project.print_error: cli-python-tooling
signalwire.cli.init_project.print_step: cli-python-tooling
signalwire.cli.init_project.print_success: cli-python-tooling
signalwire.cli.init_project.print_warning: cli-python-tooling
signalwire.cli.init_project.prompt: cli-python-tooling
signalwire.cli.init_project.prompt_multiselect: cli-python-tooling
signalwire.cli.init_project.prompt_select: cli-python-tooling
signalwire.cli.init_project.prompt_yes_no: cli-python-tooling
signalwire.cli.init_project.run_interactive: cli-python-tooling
signalwire.cli.init_project.run_quick: cli-python-tooling
signalwire.cli.output.output_formatter.display_agent_tools: cli-python-tooling
signalwire.cli.output.output_formatter.format_result: cli-python-tooling
signalwire.cli.output.swml_dump.handle_dump_swml: cli-python-tooling
signalwire.cli.output.swml_dump.setup_output_suppression: cli-python-tooling
signalwire.cli.simulation.data_generation.adapt_for_call_type: cli-python-tooling
signalwire.cli.simulation.data_generation.generate_comprehensive_post_data: cli-python-tooling
signalwire.cli.simulation.data_generation.generate_fake_node_id: cli-python-tooling
signalwire.cli.simulation.data_generation.generate_fake_sip_from: cli-python-tooling
signalwire.cli.simulation.data_generation.generate_fake_sip_to: cli-python-tooling
signalwire.cli.simulation.data_generation.generate_fake_swml_post_data: cli-python-tooling
signalwire.cli.simulation.data_generation.generate_fake_uuid: cli-python-tooling
signalwire.cli.simulation.data_generation.generate_minimal_post_data: cli-python-tooling
signalwire.cli.simulation.data_overrides.apply_convenience_mappings: cli-python-tooling
signalwire.cli.simulation.data_overrides.apply_overrides: cli-python-tooling
signalwire.cli.simulation.data_overrides.parse_value: cli-python-tooling
signalwire.cli.simulation.data_overrides.set_nested_value: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders.__contains__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders.__getitem__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders.__init__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders.get: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders.items: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders.keys: cli-python-tooling
signalwire.cli.simulation.mock_env.MockHeaders.values: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams.__contains__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams.__getitem__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams.__init__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams.get: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams.items: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams.keys: cli-python-tooling
signalwire.cli.simulation.mock_env.MockQueryParams.values: cli-python-tooling
signalwire.cli.simulation.mock_env.MockRequest: cli-python-tooling
signalwire.cli.simulation.mock_env.MockRequest.__init__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockRequest.body: cli-python-tooling
signalwire.cli.simulation.mock_env.MockRequest.client: cli-python-tooling
signalwire.cli.simulation.mock_env.MockRequest.json: cli-python-tooling
signalwire.cli.simulation.mock_env.MockURL: cli-python-tooling
signalwire.cli.simulation.mock_env.MockURL.__init__: cli-python-tooling
signalwire.cli.simulation.mock_env.MockURL.__str__: cli-python-tooling
signalwire.cli.simulation.mock_env.ServerlessSimulator: cli-python-tooling
signalwire.cli.simulation.mock_env.ServerlessSimulator.__init__: cli-python-tooling
signalwire.cli.simulation.mock_env.ServerlessSimulator.activate: cli-python-tooling
signalwire.cli.simulation.mock_env.ServerlessSimulator.add_override: cli-python-tooling
signalwire.cli.simulation.mock_env.ServerlessSimulator.deactivate: cli-python-tooling
signalwire.cli.simulation.mock_env.ServerlessSimulator.get_current_env: cli-python-tooling
signalwire.cli.simulation.mock_env.create_mock_request: cli-python-tooling
signalwire.cli.simulation.mock_env.load_env_file: cli-python-tooling
signalwire.cli.swaig_test_wrapper.main: cli-python-tooling
signalwire.cli.test_swaig.console_entry_point: cli-python-tooling
signalwire.cli.test_swaig.main: cli-python-tooling
signalwire.cli.test_swaig.print_help_examples: cli-python-tooling
signalwire.cli.test_swaig.print_help_platforms: cli-python-tooling
signalwire.cli.types.AgentInfo: cli-python-tooling
signalwire.cli.types.CallData: cli-python-tooling
signalwire.cli.types.DataMapConfig: cli-python-tooling
signalwire.cli.types.FunctionInfo: cli-python-tooling
signalwire.cli.types.PostData: cli-python-tooling
signalwire.cli.types.VarsData: cli-python-tooling

## serverless-no-perl-runtime

Per `porting-sdk/PORTING_GUIDE.md` § Serverless Support (Step 0), Perl has no first-class Lambda / Google Cloud Functions / Azure Functions runtime; it is "custom-runtime-only". The porting-sdk explicitly marks such platforms as optional and usually not worth shipping until demand exists. The Perl port omits ServerlessMixin accordingly.

signalwire.core.mixins.serverless_mixin.ServerlessMixin: serverless-no-perl-runtime
signalwire.core.mixins.serverless_mixin.ServerlessMixin.handle_serverless_request: serverless-no-perl-runtime

## mcp-gateway-standalone-service

The standalone MCP gateway service + manager + session manager (a long-running Python-only HTTP front for MCP tool servers) is not ported. The Perl port ships the `mcp_gateway` skill for calling MCP servers from agents, which is the user-facing half. The standalone server process will be ported if there is demand.

signalwire.mcp_gateway.gateway_service.MCPGateway: mcp-gateway-standalone-service
signalwire.mcp_gateway.gateway_service.MCPGateway.__init__: mcp-gateway-standalone-service
signalwire.mcp_gateway.gateway_service.MCPGateway.run: mcp-gateway-standalone-service
signalwire.mcp_gateway.gateway_service.MCPGateway.shutdown: mcp-gateway-standalone-service
signalwire.mcp_gateway.gateway_service.main: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPClient: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPClient.__init__: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPClient.call_method: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPClient.call_tool: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPClient.get_tools: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPClient.start: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPClient.stop: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager.__init__: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager.create_client: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager.get_service: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager.get_service_tools: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager.list_services: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager.shutdown: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPManager.validate_services: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPService: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPService.__hash__: mcp-gateway-standalone-service
signalwire.mcp_gateway.mcp_manager.MCPService.__post_init__: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.Session: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.Session.is_alive: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.Session.is_expired: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.Session.touch: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager.__init__: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager.close_session: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager.create_session: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager.get_service_session_count: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager.get_session: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager.list_sessions: mcp-gateway-standalone-service
signalwire.mcp_gateway.session_manager.SessionManager.shutdown: mcp-gateway-standalone-service

## pom-standalone-tooling

The `signalwire.pom.pom_tool` CLI helper (`pom-tool` / `python -m signalwire.pom.pom_tool`) is a Python-only entry point — same role the Perl SDK fills via `prove`/standalone scripts. The standalone Prompt Object Model itself (`signalwire.pom.pom.PromptObjectModel` and `Section`) IS now ported in Perl as `SignalWire::POM::PromptObjectModel` / `SignalWire::POM::Section` (lib/SignalWire/POM/), with byte-for-byte parity verified by t/pom/prompt_object_model.t.

signalwire.pom.pom_tool.detect_file_format: pom-standalone-tooling
signalwire.pom.pom_tool.load_pom: pom-standalone-tooling
signalwire.pom.pom_tool.main: pom-standalone-tooling
signalwire.pom.pom_tool.render_pom: pom-standalone-tooling

## python-specific-mixin-class-nodes

Perl's Moo-based AgentBase composes these mixin responsibilities directly into the AgentBase class via role-like inheritance. The mixin *methods* are exposed (and enumerated via the translation map), but the Python-facing empty container classes — `MCPServerMixin`, `AuthMixin` (as a standalone class), `StateMixin` — have no Perl equivalent because there's no separate package to enumerate. `AuthMixin`'s methods are recorded under their SWMLService definitions per the translation rules; `state_mixin.validate_tool_token` is handled inline in AgentBase's SWAIG request path.

signalwire.core.mixins.auth_mixin.AuthMixin: python-specific-mixin-class-nodes
signalwire.core.mixins.mcp_server_mixin.MCPServerMixin: python-specific-mixin-class-nodes
signalwire.core.mixins.state_mixin.StateMixin: python-specific-mixin-class-nodes
signalwire.core.mixins.state_mixin.StateMixin.validate_tool_token: python-specific-mixin-class-nodes

## web-service-python-wrapper

The `signalwire.web.web_service.WebService` class is a Python-only wrapper around uvicorn/FastAPI that bundles auth, routing, and CORS into one constructor. The Perl port uses Plack/PSGI directly — `AgentBase->psgi_app` returns a coderef any Plack handler consumes — so there is no analogous standalone web service abstraction.

signalwire.web.web_service.WebService: web-service-python-wrapper
signalwire.web.web_service.WebService.__init__: web-service-python-wrapper
signalwire.web.web_service.WebService.add_directory: web-service-python-wrapper
signalwire.web.web_service.WebService.remove_directory: web-service-python-wrapper
signalwire.web.web_service.WebService.start: web-service-python-wrapper
signalwire.web.web_service.WebService.stop: web-service-python-wrapper

## not-yet-implemented

Python symbols the Perl port has not yet built but intends to. Each entry carries a one-line rationale naming the parent feature.

signalwire.agent_server.AgentServer.get_agents: not_yet_implemented: AgentServer helper pending (global routing callback, SIP routing)
signalwire.agent_server.AgentServer.register_global_routing_callback: not_yet_implemented: AgentServer helper pending (global routing callback, SIP routing)
signalwire.agent_server.AgentServer.register_sip_username: not_yet_implemented: AgentServer helper pending (global routing callback, SIP routing)
signalwire.agent_server.AgentServer.setup_sip_routing: not_yet_implemented: AgentServer helper pending (global routing callback, SIP routing)
signalwire.core.agent.prompt.manager.PromptManager: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.__init__: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.define_contexts: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.get_contexts: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.get_post_prompt: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.get_prompt: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.get_raw_prompt: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.prompt_add_section: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.prompt_add_subsection: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.prompt_add_to_section: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.prompt_has_section: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.set_post_prompt: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.set_prompt_pom: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.prompt.manager.PromptManager.set_prompt_text: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.decorator.ToolDecorator: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.decorator.ToolDecorator.create_class_decorator: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.decorator.ToolDecorator.create_instance_decorator: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.__init__: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.define_tool: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.get_all_functions: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.get_function: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.has_function: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.register_class_decorated_tools: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.register_swaig_function: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.registry.ToolRegistry.remove_function: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.type_inference.create_typed_handler_wrapper: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent.tools.type_inference.infer_schema: not_yet_implemented: Python-specific internal refactoring module (tool decorator, prompt manager sub-module) — Perl flattens these into AgentBase/mixin methods
signalwire.core.agent_base.AgentBase.add_answer_verb: not_yet_implemented: SIP routing / agent naming helper pending
signalwire.core.agent_base.AgentBase.auto_map_sip_usernames: not_yet_implemented: SIP routing / agent naming helper pending
signalwire.core.agent_base.AgentBase.enable_sip_routing: not_yet_implemented: SIP routing / agent naming helper pending
signalwire.core.agent_base.AgentBase.get_name: not_yet_implemented: SIP routing / agent naming helper pending
signalwire.core.agent_base.AgentBase.register_sip_username: not_yet_implemented: SIP routing / agent naming helper pending
signalwire.core.auth_handler.AuthHandler: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.auth_handler.AuthHandler.__init__: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.auth_handler.AuthHandler.flask_decorator: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.auth_handler.AuthHandler.get_auth_info: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.auth_handler.AuthHandler.get_fastapi_dependency: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.auth_handler.AuthHandler.verify_api_key: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.auth_handler.AuthHandler.verify_basic_auth: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.auth_handler.AuthHandler.verify_bearer_token: not_yet_implemented: standalone AuthHandler class pending — Perl currently ties auth into SWMLService
signalwire.core.config_loader.ConfigLoader: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.__init__: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.find_config_file: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.get: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.get_config: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.get_config_file: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.get_section: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.has_config: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.merge_with_env: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.config_loader.ConfigLoader.substitute_vars: not_yet_implemented: unified ConfigLoader pending — Perl reads env/config ad hoc today
signalwire.core.data_map.create_expression_tool: not_yet_implemented: module-level DataMap factory helper pending
signalwire.core.data_map.create_simple_api_tool: not_yet_implemented: module-level DataMap factory helper pending
signalwire.core.logging_config.configure_logging: not_yet_implemented: logging helper pending — Perl Logging module covers debug/info/warn/error
signalwire.core.logging_config.get_execution_mode: not_yet_implemented: logging helper pending — Perl Logging module covers debug/info/warn/error
signalwire.core.logging_config.reset_logging_configuration: not_yet_implemented: logging helper pending — Perl Logging module covers debug/info/warn/error
signalwire.core.logging_config.strip_control_chars: not_yet_implemented: logging helper pending — Perl Logging module covers debug/info/warn/error
signalwire.core.mixins.auth_mixin.AuthMixin.get_basic_auth_credentials: not_yet_implemented: pending port
signalwire.core.mixins.auth_mixin.AuthMixin.validate_basic_auth: not_yet_implemented: pending port
signalwire.core.mixins.prompt_mixin.PromptMixin.get_post_prompt: not_yet_implemented: prompt mixin accessor pending
signalwire.core.mixins.prompt_mixin.PromptMixin.set_prompt_pom: not_yet_implemented: prompt mixin accessor pending
signalwire.core.mixins.tool_mixin.ToolMixin.tool: not_yet_implemented: Python @tool decorator has no Perl analogue; define_tool is the documented path
signalwire.core.mixins.tool_mixin.ToolMixin: tool_mixin_lifted_to_swml_service: Python's ToolMixin is mixed in to AgentBase. Perl folds the tool registry into SWMLService directly so SWMLService stands alone (per the SWAIG-lift refactor); the surface is the same (`define_tool`, `define_tools`, `register_swaig_function`, `on_function_call`) but it lives on SWMLService, not a separate mixin class.
signalwire.core.mixins.tool_mixin.ToolMixin.define_tool: tool_mixin_lifted_to_swml_service: see the class-level note above; Perl exposes this on SWMLService.
signalwire.core.mixins.tool_mixin.ToolMixin.define_tools: tool_mixin_lifted_to_swml_service: see the class-level note above; Perl exposes this on SWMLService.
signalwire.core.mixins.tool_mixin.ToolMixin.on_function_call: tool_mixin_lifted_to_swml_service: see the class-level note above; Perl exposes this on SWMLService.
signalwire.core.mixins.tool_mixin.ToolMixin.register_swaig_function: tool_mixin_lifted_to_swml_service: see the class-level note above; Perl exposes this on SWMLService.
signalwire.core.agent_base.AgentBase.__init__: perl_constructor_idiom: Moo provides BUILD; Python's __init__ has no direct analogue but the constructor signature (named arguments accepted by AgentBase->new) is identical.
signalwire.core.mixins.web_mixin.WebMixin.as_router: not_yet_implemented: web mixin helper pending — Perl exposes psgi_app/run/serve directly
signalwire.core.mixins.web_mixin.WebMixin.enable_debug_routes: not_yet_implemented: web mixin helper pending — Perl exposes psgi_app/run/serve directly
signalwire.core.mixins.web_mixin.WebMixin.get_app: not_yet_implemented: web mixin helper pending — Perl exposes psgi_app/run/serve directly
signalwire.core.mixins.web_mixin.WebMixin.on_request: not_yet_implemented: web mixin helper pending — Perl exposes psgi_app/run/serve directly
signalwire.core.mixins.web_mixin.WebMixin.on_swml_request: not_yet_implemented: web mixin helper pending — Perl exposes psgi_app/run/serve directly
signalwire.core.mixins.web_mixin.WebMixin.register_routing_callback: not_yet_implemented: web mixin helper pending — Perl exposes psgi_app/run/serve directly
signalwire.core.mixins.web_mixin.WebMixin.setup_graceful_shutdown: not_yet_implemented: web mixin helper pending — Perl exposes psgi_app/run/serve directly
signalwire.core.pom_builder.PomBuilder: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.__init__: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.add_section: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.add_subsection: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.add_to_section: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.from_sections: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.get_section: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.has_section: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.render_markdown: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.render_xml: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.to_dict: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.pom_builder.PomBuilder.to_json: not_yet_implemented: standalone PomBuilder class pending — POM built inline on AgentBase today
signalwire.core.security_config.SecurityConfig: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.__init__: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.get_basic_auth: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.get_cors_config: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.get_security_headers: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.get_ssl_context_kwargs: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.get_url_scheme: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.load_from_env: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.log_config: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.should_allow_host: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.security_config.SecurityConfig.validate_ssl_config: not_yet_implemented: SecurityConfig dataclass pending — Perl wires these defaults directly into AgentBase
signalwire.core.skill_base.SkillBase.get_skill_data: not_yet_implemented: SkillBase helper method pending
signalwire.core.skill_base.SkillBase.update_skill_data: not_yet_implemented: SkillBase helper method pending
signalwire.core.skill_base.SkillBase.validate_packages: not_yet_implemented: SkillBase helper method pending
signalwire.core.skill_manager.SkillManager.get_skill: not_yet_implemented: SkillManager helper method pending
signalwire.core.skill_manager.SkillManager.list_loaded_skills: not_yet_implemented: SkillManager helper method pending
signalwire.core.swaig_function.SWAIGFunction: not_yet_implemented: standalone SWAIGFunction wrapper class pending
signalwire.core.swaig_function.SWAIGFunction.__call__: not_yet_implemented: standalone SWAIGFunction wrapper class pending
signalwire.core.swaig_function.SWAIGFunction.__init__: not_yet_implemented: standalone SWAIGFunction wrapper class pending
signalwire.core.swaig_function.SWAIGFunction.execute: not_yet_implemented: standalone SWAIGFunction wrapper class pending
signalwire.core.swaig_function.SWAIGFunction.to_swaig: not_yet_implemented: standalone SWAIGFunction wrapper class pending
signalwire.core.swaig_function.SWAIGFunction.validate_args: not_yet_implemented: standalone SWAIGFunction wrapper class pending
signalwire.core.swml_builder.SWMLBuilder.__getattr__: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.ai: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.answer: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.build: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.hangup: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.play: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.render: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.reset: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_builder.SWMLBuilder.say: not_yet_implemented: SWMLBuilder helper pending — SWML::Document covers most of this
signalwire.core.swml_handler.AIVerbHandler: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.AIVerbHandler.build_config: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.AIVerbHandler.get_verb_name: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.AIVerbHandler.validate_config: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.SWMLVerbHandler: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.SWMLVerbHandler.build_config: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.SWMLVerbHandler.get_verb_name: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.SWMLVerbHandler.validate_config: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.VerbHandlerRegistry: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.VerbHandlerRegistry.__init__: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.VerbHandlerRegistry.get_handler: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.VerbHandlerRegistry.has_handler: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_handler.VerbHandlerRegistry.register_handler: not_yet_implemented: VerbHandlerRegistry not yet separated from SWML::Service
signalwire.core.swml_renderer.SwmlRenderer: not_yet_implemented: SwmlRenderer indirection not yet ported
signalwire.core.swml_renderer.SwmlRenderer.render_function_response_swml: not_yet_implemented: SwmlRenderer indirection not yet ported
signalwire.core.swml_renderer.SwmlRenderer.render_swml: not_yet_implemented: SwmlRenderer indirection not yet ported
signalwire.core.swml_service.SWMLService.__getattr__: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.add_section: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.add_verb: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.add_verb_to_section: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.as_router: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.full_validation_enabled: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.get_basic_auth_credentials: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.get_document: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.manual_set_proxy_url: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.on_request: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.register_routing_callback: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.register_verb_handler: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.render_document: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.reset_document: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.serve: not_yet_implemented: SWML::Service helper pending
signalwire.core.swml_service.SWMLService.stop: not_yet_implemented: SWML::Service helper pending
signalwire.prefabs.concierge.ConciergeAgent.check_availability: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.concierge.ConciergeAgent.get_directions: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.concierge.ConciergeAgent.on_summary: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.faq_bot.FAQBotAgent.on_summary: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.faq_bot.FAQBotAgent.search_faqs: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.info_gatherer.InfoGathererAgent.on_swml_request: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.info_gatherer.InfoGathererAgent.set_question_callback: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.info_gatherer.InfoGathererAgent.start_questions: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.info_gatherer.InfoGathererAgent.submit_answer: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.receptionist.ReceptionistAgent.on_summary: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.survey.SurveyAgent.log_response: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.survey.SurveyAgent.on_summary: not_yet_implemented: prefab agent helper method pending
signalwire.prefabs.survey.SurveyAgent.validate_response: not_yet_implemented: prefab agent helper method pending
signalwire.relay.call.AIAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.AIAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.Call.__repr__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.Call.pass_: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.Call.wait_for: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.Call.wait_for_ended: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.CollectAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.CollectAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.CollectAction.volume: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.DetectAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.DetectAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.FaxAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.FaxAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.PayAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.PayAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.PlayAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.PlayAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.RecordAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.RecordAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.StandaloneCollectAction: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.StandaloneCollectAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.StandaloneCollectAction.start_input_timers: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.StandaloneCollectAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.StreamAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.StreamAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.TapAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.TapAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.TranscribeAction.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.call.TranscribeAction.stop: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayClient.__aenter__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayClient.__aexit__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayClient.__del__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayClient.connect: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayClient.disconnect: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayClient.relay_protocol: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayError: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.client.RelayError.__init__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.CallReceiveEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.CallStateEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.CallingErrorEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.CollectEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.ConferenceEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.ConnectEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.DenoiseEvent: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.DenoiseEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.DetectEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.DialEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.EchoEvent: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.EchoEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.FaxEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.HoldEvent: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.HoldEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.MessageReceiveEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.MessageStateEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.PayEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.PlayEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.QueueEvent: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.QueueEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.RecordEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.ReferEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.RelayEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.SendDigitsEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.StreamEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.TapEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.TranscribeEvent.from_payload: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.event.parse_event: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.message.Message.__repr__: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.relay.message.Message.result: not_yet_implemented: relay feature pending — relay client is functional but incomplete
signalwire.rest._base.CrudWithAddresses: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest._base.CrudWithAddresses.list_addresses: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.addresses.AddressesResource.delete: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.calling.CallingNamespace.update: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.datasphere.DatasphereNamespace: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.datasphere.DatasphereNamespace.__init__: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.fabric.FabricAddresses: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.fabric.FabricAddresses.get: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.fabric.FabricAddresses.list: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.fabric.FabricResource: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.fabric.FabricResourcePUT: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.number_groups.NumberGroupsResource.delete_membership: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.number_groups.NumberGroupsResource.get_membership: not_yet_implemented: REST coverage pending for this resource method
signalwire.rest.namespaces.queues.QueuesResource.get_member: not_yet_implemented: REST coverage pending for this resource method
signalwire.skills.api_ninjas_trivia.skill.ApiNinjasTriviaSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.api_ninjas_trivia.skill.ApiNinjasTriviaSkill.get_tools: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.claude_skills.skill.ClaudeSkillsSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.datasphere.skill.DataSphereSkill.cleanup: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.datasphere.skill.DataSphereSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.datasphere.skill.DataSphereSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.datasphere_serverless.skill.DataSphereServerlessSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.datasphere_serverless.skill.DataSphereServerlessSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.datetime.skill.DateTimeSkill.get_hints: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.datetime.skill.DateTimeSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.google_maps.skill.GoogleMapsClient: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.google_maps.skill.GoogleMapsClient.__init__: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.google_maps.skill.GoogleMapsClient.compute_route: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.google_maps.skill.GoogleMapsClient.validate_address: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.google_maps.skill.GoogleMapsSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.info_gatherer.skill.InfoGathererSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.joke.skill.JokeSkill.get_hints: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.joke.skill.JokeSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.math.skill.MathSkill.get_hints: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.math.skill.MathSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.mcp_gateway.skill.MCPGatewaySkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.play_background_file.skill.PlayBackgroundFileSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.play_background_file.skill.PlayBackgroundFileSkill.get_tools: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.registry.SkillRegistry.add_skill_directory: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.registry.SkillRegistry.discover_skills: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.registry.SkillRegistry.get_all_skills_schema: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.registry.SkillRegistry.get_skill_class: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.registry.SkillRegistry.list_all_skill_sources: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.spider.skill.SpiderSkill.cleanup: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.spider.skill.SpiderSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.swml_transfer.skill.SWMLTransferSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.swml_transfer.skill.SWMLTransferSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.weather_api.skill.WeatherApiSkill.get_tools: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.__init__: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.extract_html_content: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.extract_reddit_content: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.extract_text_from_url: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.is_reddit_url: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.search_and_scrape: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.search_and_scrape_best: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.GoogleSearchScraper.search_google: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.WebSearchSkill.get_hints: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.WebSearchSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill.WebSearchSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.GoogleSearchScraper: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.GoogleSearchScraper.__init__: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.GoogleSearchScraper.extract_text_from_url: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.GoogleSearchScraper.search_and_scrape: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.GoogleSearchScraper.search_and_scrape_best: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.GoogleSearchScraper.search_google: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill.get_global_data: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill.get_hints: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill.get_parameter_schema: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill.register_tools: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_improved.WebSearchSkill.setup: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.GoogleSearchScraper: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.GoogleSearchScraper.__init__: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.GoogleSearchScraper.extract_text_from_url: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.GoogleSearchScraper.search_and_scrape: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.GoogleSearchScraper.search_google: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill.get_global_data: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill.get_hints: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill.get_instance_key: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill.get_parameter_schema: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill.register_tools: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.web_search.skill_original.WebSearchSkill.setup: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.wikipedia_search.skill.WikipediaSearchSkill.get_hints: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.wikipedia_search.skill.WikipediaSearchSkill.get_prompt_sections: not_yet_implemented: skill internal helper not yet ported
signalwire.skills.wikipedia_search.skill.WikipediaSearchSkill.search_wiki: not_yet_implemented: skill internal helper not yet ported
signalwire.list_skills: not_yet_implemented: top-level convenience export — Perl users currently use the class path (e.g. SignalWire::REST::RestClient->new) directly
signalwire.run_agent: not_yet_implemented: top-level convenience export — Perl users currently use the class path (e.g. SignalWire::REST::RestClient->new) directly
signalwire.start_agent: not_yet_implemented: top-level convenience export — Perl users currently use the class path (e.g. SignalWire::REST::RestClient->new) directly
signalwire.utils.is_serverless_mode: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.full_validation_available: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.generate_method_body: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.generate_method_signature: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.get_all_verb_names: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.get_verb_parameters: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.get_verb_properties: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.get_verb_required_properties: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.load_schema: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.validate_document: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaUtils.validate_verb: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaValidationError: not_yet_implemented: utility helper pending
signalwire.utils.schema_utils.SchemaValidationError.__init__: not_yet_implemented: utility helper pending
signalwire.utils.url_validator.validate_url: not_yet_implemented: utility helper pending
signalwire.core.security.webhook_middleware.make_webhook_validation_dependency: framework_specific: FastAPI dependency factory; Perl exposes Plack middleware as a class (SignalWire::Security::WebhookMiddleware) instead — see PORT_ADDITIONS.md
