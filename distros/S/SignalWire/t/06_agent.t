#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64);

use_ok('SignalWire::Agent::AgentBase');

# ============================================================
# 1. Construction and defaults
# ============================================================
subtest 'construction defaults' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test_agent');
    is($agent->name,  'test_agent', 'name set');
    is($agent->route, '/',          'default route is /');
    is($agent->host,  '0.0.0.0',   'default host');
    ok($agent->auto_answer, 'auto_answer defaults to true');
    ok(!$agent->record_call, 'record_call defaults to false');
    is($agent->record_format, 'mp4', 'default record format');
    ok($agent->use_pom, 'use_pom defaults to true');
    is(ref $agent->tools, 'HASH', 'tools is hashref');
    is(ref $agent->tool_order, 'ARRAY', 'tool_order is arrayref');
    is(ref $agent->hints, 'ARRAY', 'hints is arrayref');
    is(ref $agent->global_data, 'HASH', 'global_data is hashref');
    ok(defined $agent->session_manager, 'session_manager is built');
    ok(defined $agent->basic_auth_user, 'basic_auth_user has value');
    ok(defined $agent->basic_auth_password, 'basic_auth_password has value');
};

# ============================================================
# 2. Route normalization
# ============================================================
subtest 'route normalization' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(
        name  => 'test',
        route => '/agent/',
    );
    is($agent->route, '/agent', 'trailing slash stripped');
};

# ============================================================
# 3. Prompt methods (POM mode)
# ============================================================
subtest 'prompt POM mode' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pom_test');

    $agent->prompt_add_section('Personality', 'You are helpful.',
        bullets => ['Be concise', 'Be accurate']);

    my $sections = $agent->pom_sections;
    is(scalar @$sections, 1, 'one section added');
    is($sections->[0]{title}, 'Personality', 'section title');
    is($sections->[0]{body}, 'You are helpful.', 'section body');
    is(scalar @{$sections->[0]{bullets}}, 2, 'two bullets');

    # Test prompt_has_section
    ok($agent->prompt_has_section('Personality'), 'has Personality section');
    ok(!$agent->prompt_has_section('Missing'), 'does not have Missing section');

    # Test get_prompt returns sections array in POM mode
    my $prompt = $agent->get_prompt;
    is(ref $prompt, 'ARRAY', 'get_prompt returns array in POM mode');
};

# ============================================================
# 4. Prompt methods (raw text mode)
# ============================================================
subtest 'prompt raw text mode' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(
        name    => 'raw_test',
        use_pom => 0,
    );
    $agent->set_prompt_text('You are a helpful assistant.');
    is($agent->get_prompt, 'You are a helpful assistant.', 'raw text prompt');
};

# ============================================================
# 5. Prompt subsection and add_to_section
# ============================================================
subtest 'prompt subsection' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'sub_test');
    $agent->prompt_add_section('Parent', 'Parent body');
    $agent->prompt_add_subsection('Parent', 'Child', 'Child body');
    $agent->prompt_add_to_section('Parent', bullets => ['extra bullet']);

    my $sec = $agent->pom_sections->[0];
    ok(exists $sec->{subsections}, 'subsections created');
    is($sec->{subsections}[0]{title}, 'Child', 'subsection title');
    ok(grep { $_ eq 'extra bullet' } @{$sec->{bullets}}, 'bullet added via add_to_section');
};

# ============================================================
# 6. Tool registration
# ============================================================
subtest 'tool registration' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'tool_test');

    $agent->define_tool(
        name        => 'get_weather',
        description => 'Get the weather',
        parameters  => {
            type => 'object',
            properties => {
                location => { type => 'string' },
            },
            required => ['location'],
        },
        handler => sub {
            my ($args) = @_;
            return { response => "Sunny in $args->{location}" };
        },
    );

    ok(exists $agent->tools->{get_weather}, 'tool registered');
    is($agent->tools->{get_weather}{function}, 'get_weather', 'tool name stored');
    is(scalar @{$agent->tool_order}, 1, 'tool_order has one entry');
    is($agent->tool_order->[0], 'get_weather', 'correct order entry');

    # Test on_function_call
    my $result = $agent->on_function_call('get_weather', { location => 'London' }, {});
    is(ref $result, 'HASH', 'handler returns hash');
    like($result->{response}, qr/London/, 'handler received args');

    # Non-existent function
    my $missing = $agent->on_function_call('missing', {}, {});
    ok(!defined $missing, 'missing function returns undef');
};

# ============================================================
# 7. register_swaig_function (DataMap style)
# ============================================================
subtest 'register_swaig_function' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'swaig_test');
    $agent->register_swaig_function({
        function    => 'get_joke',
        description => 'Get a joke',
        parameters  => { type => 'object', properties => {} },
        data_map    => { webhooks => [] },
    });
    ok(exists $agent->tools->{get_joke}, 'swaig function registered');
    ok(exists $agent->tools->{get_joke}{data_map}, 'data_map preserved');
};

# ============================================================
# 8. define_tools (multiple)
# ============================================================
subtest 'define_tools multiple' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'multi_tool');
    $agent->define_tools(
        { name => 'tool_a', description => 'A' },
        { function => 'tool_b', description => 'B', parameters => {} },
    );
    ok(exists $agent->tools->{tool_a}, 'tool_a registered');
    ok(exists $agent->tools->{tool_b}, 'tool_b registered');
    is(scalar @{$agent->tool_order}, 2, 'two tools in order');
};

# ============================================================
# 9. AI config methods
# ============================================================
subtest 'AI config methods' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'config_test');

    # Method chaining
    my $ret = $agent->add_hint('SignalWire');
    is($ret, $agent, 'add_hint returns self');

    $agent->add_hints('AI', 'agent');
    is(scalar @{$agent->hints}, 3, '3 hints');

    $agent->add_language(name => 'English', code => 'en-US', voice => 'rachel');
    is(scalar @{$agent->languages}, 1, 'language added');

    $agent->add_pronunciation(replace => 'SW', with => 'SignalWire');
    is(scalar @{$agent->pronunciations}, 1, 'pronunciation added');

    $agent->set_param('temperature', 0.7);
    is($agent->params->{temperature}, 0.7, 'param set');

    $agent->set_params({ top_p => 0.9 });
    is($agent->params->{top_p}, 0.9, 'params merged');

    $agent->set_global_data({ key => 'value' });
    is($agent->global_data->{key}, 'value', 'global_data set');

    $agent->update_global_data({ key2 => 'value2' });
    is($agent->global_data->{key}, 'value', 'original key preserved');
    is($agent->global_data->{key2}, 'value2', 'new key added');

    $agent->set_native_functions(['check_for_input']);
    is($agent->native_functions->[0], 'check_for_input', 'native functions set');

    $agent->set_prompt_llm_params(temperature => 0.5);
    is($agent->prompt_llm_params->{temperature}, 0.5, 'prompt LLM params set');

    $agent->set_post_prompt_llm_params(temperature => 0.3);
    is($agent->post_prompt_llm_params->{temperature}, 0.3, 'post-prompt LLM params set');
};

# ============================================================
# 10. Verb management
# ============================================================
subtest 'verb management' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'verb_test');

    $agent->add_pre_answer_verb('play', { url => 'ringback.wav' });
    is(scalar @{$agent->pre_answer_verbs}, 1, 'pre-answer verb added');

    $agent->add_post_answer_verb('play', { url => 'welcome.wav' });
    is(scalar @{$agent->post_answer_verbs}, 1, 'post-answer verb added');

    $agent->add_post_ai_verb('hangup', {});
    is(scalar @{$agent->post_ai_verbs}, 1, 'post-AI verb added');

    $agent->clear_pre_answer_verbs;
    is(scalar @{$agent->pre_answer_verbs}, 0, 'pre-answer verbs cleared');

    $agent->clear_post_answer_verbs;
    is(scalar @{$agent->post_answer_verbs}, 0, 'post-answer verbs cleared');

    $agent->clear_post_ai_verbs;
    is(scalar @{$agent->post_ai_verbs}, 0, 'post-AI verbs cleared');
};

# ============================================================
# 11. render_swml (5-phase pipeline)
# ============================================================
subtest 'render_swml' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(
        name           => 'render_test',
        route          => '/test',
        auto_answer    => 1,
        record_call    => 1,
        record_format  => 'mp4',
        record_stereo  => 1,
    );

    $agent->prompt_add_section('Role', 'You are a test agent.');
    $agent->add_hint('test');
    $agent->set_param('temperature', 0.5);
    $agent->set_global_data({ mode => 'test' });

    $agent->define_tool(
        name        => 'test_tool',
        description => 'A test tool',
        parameters  => { type => 'object', properties => {} },
        handler     => sub { { response => 'ok' } },
    );

    my $swml = $agent->render_swml;

    # Check document structure
    is($swml->{version}, '1.0.0', 'version is 1.0.0');
    ok(exists $swml->{sections}{main}, 'main section exists');
    my @main = @{ $swml->{sections}{main} };
    ok(scalar @main >= 3, 'at least 3 verbs in main section');

    # Check answer verb
    my @answer_verbs = grep { exists $_->{answer} } @main;
    ok(scalar @answer_verbs >= 1, 'answer verb present');

    # Check record_call verb
    my @record_verbs = grep { exists $_->{record_call} } @main;
    ok(scalar @record_verbs >= 1, 'record_call verb present');

    # Check AI verb
    my @ai_verbs = grep { exists $_->{ai} } @main;
    is(scalar @ai_verbs, 1, 'one AI verb');
    my $ai = $ai_verbs[0]{ai};

    # Check prompt (POM mode)
    ok(exists $ai->{prompt}{pom}, 'POM prompt generated');
    is(ref $ai->{prompt}{pom}, 'ARRAY', 'POM is array');

    # Check hints
    ok(exists $ai->{hints}, 'hints included');

    # Check params
    ok(exists $ai->{params}, 'params included');
    is($ai->{params}{temperature}, 0.5, 'temperature param');

    # Check global_data
    ok(exists $ai->{global_data}, 'global_data included');
    is($ai->{global_data}{mode}, 'test', 'global_data content');

    # Check SWAIG functions
    ok(exists $ai->{SWAIG}, 'SWAIG block exists');
    ok(exists $ai->{SWAIG}{functions}, 'functions array exists');
    my @funcs = @{ $ai->{SWAIG}{functions} };
    is(scalar @funcs, 1, 'one function');
    is($funcs[0]{function}, 'test_tool', 'function name');
    ok(!exists $funcs[0]{_handler}, 'handler stripped from SWML output');
    ok(exists $funcs[0]{web_hook_url}, 'web_hook_url set');
};

# ============================================================
# 12. render_swml with raw text prompt
# ============================================================
subtest 'render_swml raw text' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(
        name    => 'raw_render',
        use_pom => 0,
    );
    $agent->set_prompt_text('Hello world');
    my $swml = $agent->render_swml;
    my @ai_verbs = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    my $ai = $ai_verbs[0]{ai};
    is($ai->{prompt}{text}, 'Hello world', 'raw text in prompt');
};

# ============================================================
# 13. Post prompt
# ============================================================
subtest 'post_prompt' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pp_test');
    $agent->set_post_prompt('Summarize the conversation.');
    my $swml = $agent->render_swml;
    my @ai_verbs = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    ok(exists $ai_verbs[0]{ai}{post_prompt}, 'post_prompt present in AI verb');
    is($ai_verbs[0]{ai}{post_prompt}{text}, 'Summarize the conversation.', 'post_prompt text');
};

# ============================================================
# 14. Webhook/callback setters
# ============================================================
subtest 'callback setters' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cb_test');

    $agent->set_web_hook_url('https://example.com/swaig');
    is($agent->webhook_url, 'https://example.com/swaig', 'webhook_url set');

    $agent->set_post_prompt_url('https://example.com/post_prompt');
    is($agent->post_prompt_url, 'https://example.com/post_prompt', 'post_prompt_url set');

    $agent->manual_set_proxy_url('https://proxy.example.com');
    is($agent->proxy_url_base, 'https://proxy.example.com', 'proxy_url_base set');

    $agent->add_swaig_query_params(key => 'value');
    is($agent->swaig_query_params->{key}, 'value', 'query params added');

    $agent->clear_swaig_query_params;
    is(scalar keys %{$agent->swaig_query_params}, 0, 'query params cleared');
};

# ============================================================
# 15. Dynamic config callback
# ============================================================
subtest 'dynamic config callback' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'dynamic_test');
    my $called = 0;
    $agent->set_dynamic_config_callback(sub {
        my ($q, $b, $h, $clone) = @_;
        $called = 1;
        $clone->set_prompt_text('Dynamic prompt');
    });
    ok(defined $agent->dynamic_config_callback, 'callback set');
};

# ============================================================
# 16. Summary callback
# ============================================================
subtest 'summary callback' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'summary_test');
    my $summary_data;
    $agent->on_summary(sub {
        my ($summary, $raw) = @_;
        $summary_data = $summary;
    });
    ok(defined $agent->summary_callback, 'summary callback set');
};

# ============================================================
# 17. PSGI app construction
# ============================================================
subtest 'psgi_app construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'psgi_test');
    my $app = $agent->psgi_app;
    is(ref $app, 'CODE', 'psgi_app returns coderef');

    # Test health endpoint
    my $health_res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/health',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });
    is($health_res->[0], 200, 'health returns 200');
    my $health_body = decode_json($health_res->[2][0]);
    is($health_body->{status}, 'healthy', 'health status');

    # Test ready endpoint
    my $ready_res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/ready',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });
    is($ready_res->[0], 200, 'ready returns 200');

    # Test auth required on main route (no auth header)
    my $noauth_res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
        'psgi.input'   => do { open my $fh, '<', \(''); $fh },
    });
    is($noauth_res->[0], 401, 'main route requires auth');
};

# ============================================================
# 18. PSGI app with auth
# ============================================================
subtest 'psgi_app with auth' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(
        name               => 'auth_test',
        basic_auth_user     => 'testuser',
        basic_auth_password => 'testpass',
    );
    my $app = $agent->psgi_app;

    my $auth = encode_base64('testuser:testpass', '');
    my $res = $app->({
        REQUEST_METHOD    => 'GET',
        PATH_INFO         => '/',
        SCRIPT_NAME       => '',
        SERVER_NAME       => 'localhost',
        SERVER_PORT       => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        'psgi.input'      => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 200, 'authenticated request succeeds');
    my $body = decode_json($res->[2][0]);
    is($body->{version}, '1.0.0', 'returns SWML document');
};

# ============================================================
# 19. Security headers in response
# ============================================================
subtest 'security headers' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'sec_test');
    my $app = $agent->psgi_app;

    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/health',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });
    my %headers = @{ $res->[1] };
    is($headers{'X-Content-Type-Options'}, 'nosniff', 'X-Content-Type-Options header');
    is($headers{'X-Frame-Options'}, 'DENY', 'X-Frame-Options header');
    is($headers{'Cache-Control'}, 'no-store', 'Cache-Control header');
};

# ============================================================
# 20. Context builder (lazy)
# ============================================================
subtest 'context builder (no-arg form returns ContextBuilder)' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ctx_test');
    my $builder = $agent->define_contexts;
    ok(defined $builder, 'context builder returned');
    isa_ok($builder, 'SignalWire::Contexts::ContextBuilder',
           'returns ContextBuilder');
    $builder->add_context('default');
    ok($builder->has_contexts, 'context added');
};

# Python parity: PromptMixin.define_contexts(contexts=None).
# Optional ``contexts`` arg accepts a hashref or a ContextBuilder
# and returns $self for chaining.
subtest 'define_contexts(hashref) applies config and returns self' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ctx_apply');
    my $ret = $agent->define_contexts({
        default => {
            steps => {
                greet => { task => 'Greet the user' },
            },
        },
    });
    is($ret, $agent, 'returns $self for chaining');
    ok($agent->context_builder->has_contexts, 'context applied');
    my $ctx = $agent->context_builder->get_context('default');
    ok(defined $ctx, 'default context exists');
    ok(defined $ctx->get_step('greet'), 'greet step added');
};

subtest 'define_contexts(ContextBuilder) attaches external builder' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ctx_external');
    my $external = SignalWire::Contexts::ContextBuilder->new;
    $external->add_context('default')->add_step('s1', task => 'do thing');
    my $ret = $agent->define_contexts($external);
    is($ret, $agent, 'returns $self when given a ContextBuilder');
};

# ============================================================
# 21. Clone for dynamic config
# ============================================================
subtest 'clone for request' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'clone_test');
    $agent->add_hint('original');
    $agent->set_global_data({ key => 'original' });
    $agent->define_tool(name => 'tool1', description => 'T1');

    my $clone = $agent->_clone_for_request;
    $clone->add_hint('clone_hint');
    $clone->update_global_data({ key2 => 'cloned' });

    # Verify original is untouched
    ok(!grep({ $_ eq 'clone_hint' } @{$agent->hints}), 'original hints unmodified');
    ok(!exists $agent->global_data->{key2}, 'original global_data unmodified');

    # Verify clone has everything
    ok(grep({ $_ eq 'original' } @{$clone->hints}), 'clone has original hint');
    ok(grep({ $_ eq 'clone_hint' } @{$clone->hints}), 'clone has new hint');
    is($clone->global_data->{key2}, 'cloned', 'clone has new global_data');
    ok(exists $clone->tools->{tool1}, 'clone has tool');
};

# ============================================================
# 22. get_full_url
# ============================================================
subtest 'get_full_url' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(
        name               => 'url_test',
        route              => '/myagent',
        host               => 'localhost',
        port               => 5000,
        basic_auth_user     => 'user',
        basic_auth_password => 'pass',
    );
    my $url = $agent->get_full_url;
    like($url, qr/localhost:5000\/myagent/, 'full URL includes host, port, route');

    my $auth_url = $agent->get_full_url(include_auth => 1);
    like($auth_url, qr/user:pass\@/, 'auth URL includes credentials');
};

# ============================================================
# 23. Method chaining
# ============================================================
subtest 'method chaining' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'chain_test');
    my $result = $agent
        ->set_prompt_text('Hello')
        ->set_post_prompt('Goodbye')
        ->add_hint('test')
        ->set_param('temp', 0.5)
        ->add_language(name => 'English', code => 'en-US')
        ->add_pronunciation(replace => 'AI', with => 'artificial intelligence')
        ->set_global_data({ key => 'val' })
        ->set_native_functions(['func1'])
        ->enable_debug_events(2)
        ->set_prompt_llm_params(temperature => 0.7)
        ->set_post_prompt_llm_params(temperature => 0.3);

    is($result, $agent, 'method chaining works');
    is($agent->prompt_text, 'Hello', 'chained set_prompt_text works');
    is($agent->debug_events_level, 2, 'chained enable_debug_events works');
};

# ============================================================
# 24. Internal fillers in render_swml
# ============================================================
subtest 'internal fillers in render' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'filler_test');
    $agent->set_internal_fillers(['one moment']);
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    ok(exists $ai[0]{ai}{params}{internal_fillers}, 'internal_fillers in params');
};

# ============================================================
# 25. Debug events in render_swml
# ============================================================
subtest 'debug events in render' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'debug_test');
    $agent->enable_debug_events(2);
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    is($ai[0]{ai}{params}{debug_events}, 2, 'debug_events level in params');
};

# ============================================================
# 26. Native functions in SWAIG
# ============================================================
subtest 'native functions in SWAIG' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'native_test');
    $agent->set_native_functions(['check_for_input']);
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    is_deeply($ai[0]{ai}{SWAIG}{native_functions}, ['check_for_input'], 'native functions in SWAIG');
};

# ============================================================
# 27. Function includes in SWAIG
# ============================================================
subtest 'function includes' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'include_test');
    $agent->add_function_include({ url => 'https://example.com/swaig', functions => ['func1'] });
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    ok(exists $ai[0]{ai}{SWAIG}{includes}, 'includes present');
};

# ============================================================
# 28. Pre/post answer verbs in render_swml
# ============================================================
subtest 'verb phases in render' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'phases_test');
    $agent->add_pre_answer_verb('play', { url => 'ring.wav' });
    $agent->add_post_answer_verb('play', { url => 'welcome.wav' });
    $agent->add_post_ai_verb('hangup', {});

    my $swml = $agent->render_swml;
    my @main = @{ $swml->{sections}{main} };

    # Pre-answer verb should come first
    ok(exists $main[0]{play}, 'pre-answer verb is first');

    # Post-AI verb should come last
    ok(exists $main[-1]{hangup}, 'post-AI verb is last');
};

# ============================================================
# 29. Prompt LLM params in render
# ============================================================
subtest 'LLM params in render' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'llm_test');
    $agent->set_prompt_text('test');
    $agent->set_prompt_llm_params(temperature => 0.7, top_p => 0.9);
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    is($ai[0]{ai}{prompt}{temperature}, 0.7, 'prompt LLM temp in SWML');
    is($ai[0]{ai}{prompt}{top_p}, 0.9, 'prompt LLM top_p in SWML');
};

# ============================================================
# 30. Timing-safe auth comparison
# ============================================================
subtest 'timing safe comparison' => sub {
    ok(SignalWire::Agent::AgentBase::_timing_safe_eq('abc', 'abc'), 'equal strings');
    ok(!SignalWire::Agent::AgentBase::_timing_safe_eq('abc', 'def'), 'different strings');
    ok(!SignalWire::Agent::AgentBase::_timing_safe_eq('abc', 'abcd'), 'different lengths');
};

done_testing;
