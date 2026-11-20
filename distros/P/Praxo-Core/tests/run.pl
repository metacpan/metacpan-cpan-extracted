#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Praxo::Json ();
use Praxo::Models ();
use Praxo::Toolcall ();
use Praxo::JsonSchema ();
use Praxo::Plugin ();
use Praxo::Runtime ();
use Praxo::Middleware ();
use Praxo::Agent ();
use Praxo::Adapters::OpenAICompatible ();
use Praxo::Adapters::Anthropic ();
use Praxo::Adapters::Gemini ();
use Praxo::Adapters::MCP ();
use Praxo::Adapters::MCPHTTP ();
use Praxo::Adapters::Harmovela ();
use Praxo::Adapters::Otel ();
use Praxo::Adapters::Retriever ();
use Praxo::Adapters::Delegation ();

my $call = Praxo::Toolcall::parse_toolcall('{"name":"echo","input":{"text":"hi"}}');
ok(defined $call, 'toolcall parsed');
is($call->{name}, 'echo', 'toolcall name');
is($call->{input}{text}, 'hi', 'toolcall input');
is(Praxo::Toolcall::strip_markup(
    'hello<tool_call name="echo">{"text":"hi"}</tool_call>world'
), 'helloworld', 'toolcall stripped');

my $schema = Praxo::Json::parse(
    '{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}'
);
my $errors = Praxo::JsonSchema::validate($schema, {});
is(scalar @$errors, 1, 'schema required');
is($errors->[0]{path}, '$.name', 'schema path');
is(scalar @{ Praxo::JsonSchema::validate($schema, { name => 'ok' }) }, 0, 'schema valid');

my $manifest = Praxo::Plugin::parse_manifest(
    '{"schemaVersion":1,"id":"com.example.echo","version":"1.0.0",'
    . '"kind":"tool.provider.v1","entrypoint":{"type":"process","command":"echo"},'
    . '"protocol":"jsonrpc-2","capabilities":[],"permissions":{},"limits":{},'
    . '"health":{},"isolation":"process"}'
);
is($manifest->{id}, 'com.example.echo', 'plugin manifest');

my $store = Praxo::Runtime::MemoryStore->new;
$store->put('s1', { id => 'm1', content => 'Alpha', createdAt => '2026-01-01T00:00:00Z' });
$store->put('s1', { id => 'm2', content => 'ALPHABET', createdAt => '2026-01-02T00:00:00Z' });
is_deeply([ map { $_->{id} } $store->search('s1', 'alpha', 10) ], ['m2', 'm1'], 'memory');

my $allow = Praxo::Runtime::CheckpointAllowlist->new;
$allow->register('spec.payload');
my $data = $allow->marshal('spec.payload', { value => 'x' });
is_deeply($allow->unmarshal($data), { value => 'x' }, 'checkpoint roundtrip');

my $root = tempdir(CLEANUP => 1);
my $grant = File::Spec->catdir($root, 'root');
make_path($grant);
my $checker = Praxo::Runtime::PathChecker->new([
    { root => $grant, access => 'readwrite' },
]);
ok($checker->check(File::Spec->catfile($grant, 'a.txt'), 'read')->{allowed}, 'policy allow');
ok(!$checker->check(File::Spec->catfile($root, 'root-evil', 'x.txt'), 'read')->{allowed},
    'policy sibling');

my @messages = (
    Praxo::Models::message_text('system', 'sys'),
    (map { Praxo::Models::message_text('user', "message $_") } 0 .. 9),
);
is(Praxo::Runtime::estimate_tokens(\@messages), 64, 'context estimate');
my ($out, $ok) = Praxo::Runtime::ContextBudget->new(
    max_tokens => 30, keep_recent => 2,
)->compact(\@messages);
ok($ok, 'context compact');
is(Praxo::Runtime::estimate_tokens($out), 25, 'context compact tokens');
is($out->[1]{content}, '[context compacted: 8 older messages omitted]', 'context marker');

is(Praxo::Middleware::redact('email a@b.com'), 'email [REDACTED:email]', 'pii');
my ($structured, $structured_error) = Praxo::Middleware::structured_apply(
    { type => 'object', properties => { value => { type => 'integer' } }, required => ['value'] },
    '{"value":1}', 0, undef,
);
is($structured, '{"value":1}', 'structured output');
ok(!defined $structured_error, 'structured output no error');

my $limit = Praxo::Middleware::CallLimit->new(model_limit => 1, tool_limit => 0);
eval { $limit->before_model };
ok(!$@, 'call limit first');
my $caught = 0;
eval { $limit->before_model };
$caught = 1 if $@;
ok($caught, 'call limit second fails');

my $selection = Praxo::Middleware::ToolSelection->new(['echo']);
is_deeply($selection->filter([
    Praxo::Models::tool_spec(name => 'echo'),
    Praxo::Models::tool_spec(name => 'other'),
])->[0]{name}, 'echo', 'tool selection');

my $fallback = Praxo::Middleware::fallback_model(sub {
    Praxo::Models::response(message => Praxo::Models::message_assistant('fallback'));
})->(sub { Praxo::Errors::praxo_error('PRIMARY_FAILED', 'primary') });
is($fallback->(Praxo::Models::request())->{message}{content}, 'fallback', 'fallback');

package TestSink;
sub new { bless { types => [], events => [] }, shift }
sub emit {
    push @{ $_[0]{types} }, $_[1]{type};
    push @{ $_[0]{events} }, $_[1];
}
sub types { $_[0]{types} }
sub events { $_[0]{events} }

package TestModel;
sub new { bless { steps => $_[1], next => 0, requests => [] }, shift }
sub generate {
    my ($self, $request) = @_;
    push @{ $self->{requests} }, {
        %$request,
        messages => [ @{ $request->{messages} // [] } ],
    };
    my $step = $self->{steps}[ $self->{next}++ ];
    my @calls = map {
        Praxo::Models::tool_call(id => $_->{id}, name => $_->{name}, arguments => $_->{arguments})
    } @{ $step->{toolCalls} // [] };
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($step->{content} // '', \@calls),
    );
}

sub requests { $_[0]{requests} }

package main;

my $invocations = 0;
my $registry = Praxo::Agent::ToolRegistry->new;
$registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo', sub {
    $invocations++;
    return $_[0];
}));
my $sink = TestSink->new;
my $options = Praxo::Agent::AgentOptions->new(TestModel->new([
    { content => '', toolCalls => [{ id => 'c1', name => 'echo', arguments => { text => 'hi' } }] },
    { content => 'done' },
]));
$options->{tools} = $registry;
$options->{events} = $sink;
my $result = Praxo::Agent::run_agent($options, Praxo::Models::session(id => 's1'), 'go');
is($result->{output}, 'done', 'agent output');
is($result->{steps}, 2, 'agent steps');
is($invocations, 1, 'agent tool invocation');
is_deeply($sink->types, [qw(run.started tool.call run.completed)], 'agent events');

my $policy_guard_options = Praxo::Agent::AgentOptions->new(TestModel->new([
    { content => 'done' },
]));
$policy_guard_options->{require_policy} = 1;
my $policy_guard_ok = eval {
    Praxo::Agent::run_agent($policy_guard_options, Praxo::Models::session(id => 's1'), 'go');
    1;
};
my $policy_guard_error = $@;
is($policy_guard_ok, undef, 'require policy guard');
is(Praxo::Errors::error_code($policy_guard_error), 'AGENT_INVALID_OPTIONS',
    'require policy guard code');
is("$policy_guard_error", 'agent: require policy: policy is required',
    'require policy guard message');

my $policy_configured_options = Praxo::Agent::AgentOptions->new(TestModel->new([
    { content => 'done' },
]));
$policy_configured_options->{require_policy} = 1;
$policy_configured_options->{policy} = sub { { allowed => 1 } };
my $policy_configured_result = Praxo::Agent::run_agent(
    $policy_configured_options, Praxo::Models::session(id => 's1'), 'go',
);
is($policy_configured_result->{output}, 'done', 'require policy configured');

my $scope_guard_options = Praxo::Agent::AgentOptions->new(TestModel->new([
    { content => 'done' },
]));
$scope_guard_options->{require_tool_scope} = 1;
my $scope_guard_ok = eval {
    Praxo::Agent::run_agent($scope_guard_options, Praxo::Models::session(id => 's1'), 'go');
    1;
};
my $scope_guard_error = $@;
is($scope_guard_ok, undef, 'require tool scope guard');
is(Praxo::Errors::error_code($scope_guard_error), 'AGENT_INVALID_OPTIONS',
    'require tool scope guard code');
is("$scope_guard_error", 'agent: require tool scope: allowed_tools must not be empty',
    'require tool scope guard message');

my $scope_configured_options = Praxo::Agent::AgentOptions->new(TestModel->new([
    { content => 'done' },
]));
$scope_configured_options->{require_tool_scope} = 1;
$scope_configured_options->{allowed_tools} = ['echo'];
my $scope_configured_result = Praxo::Agent::run_agent(
    $scope_configured_options, Praxo::Models::session(id => 's1'), 'go',
);
is($scope_configured_result->{output}, 'done', 'require tool scope configured');

my $default_guard_options = Praxo::Agent::AgentOptions->new(TestModel->new([
    { content => 'done' },
]));
my $default_guard_result = Praxo::Agent::run_agent(
    $default_guard_options, Praxo::Models::session(id => 's1'), 'go',
);
is($default_guard_result->{output}, 'done', 'agent guards default off');

my $captured;
my $adapter = Praxo::Adapters::OpenAICompatible->new(
    base_url => 'http://example.test/v1',
    model => 'test-model',
    transport => sub {
        my ($path, $payload) = @_;
        $captured = [$path, $payload];
        return {
            choices => [{
                message => {
                    role => 'assistant',
                    content => '',
                    tool_calls => [{
                        id => 'call-1',
                        type => 'function',
                        function => { name => 'echo', arguments => '{"text":"hi"}' },
                    }],
                },
                finish_reason => 'tool_calls',
            }],
            usage => { prompt_tokens => 3, completion_tokens => 2 },
        };
    },
);
my $adapter_request = Praxo::Models::request(
    messages => [Praxo::Models::message_text('user', 'hello')],
    tools => [Praxo::Models::tool_spec(
        name => 'echo', description => 'Echo', parameters => { type => 'object' },
    )],
    tool_choice => 'auto',
);
my $adapter_response = $adapter->generate($adapter_request);
is($captured->[0], '/chat/completions', 'openai path');
is($captured->[1]{model}, 'test-model', 'openai model');
is($captured->[1]{messages}[0]{content}, 'hello', 'openai message content');
is($captured->[1]{tools}[0]{function}{name}, 'echo', 'openai tool name');
is($captured->[1]{tool_choice}, 'auto', 'openai tool choice');
is($adapter_response->{message}{toolCalls}[0]{name}, 'echo', 'openai tool call parsed');
is_deeply($adapter_response->{message}{toolCalls}[0]{arguments}, { text => 'hi' }, 'openai tool arguments');
is($adapter_response->{usage}{inputTokens}, 3, 'openai input tokens');
is($adapter_response->{usage}{outputTokens}, 2, 'openai output tokens');
is($adapter_response->{finishReason}, 'tool_calls', 'openai finish reason');

my $stream_payload;
my $stream_adapter = Praxo::Adapters::OpenAICompatible->new(
    base_url => 'http://example.test/v1',
    model => 'test-model',
    stream_transport => sub {
        my ($path, $payload) = @_;
        is($path, '/chat/completions', 'openai stream path');
        $stream_payload = $payload;
        return <<'SSE';
data: {"choices":[{"delta":{"content":"he"}}]}

data: {"choices":[{"delta":{"content":"llo"}}]}

data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call-1","function":{"name":"ec","arguments":"{\"text\":"}}]}}]}

data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"name":"ho","arguments":"\"hi\"}"}}]}}],"usage":{"prompt_tokens":4,"completion_tokens":2}}

data: {"choices":[{"delta":{},"finish_reason":"tool_calls"}]}

data: [DONE]
SSE
    },
);
my @stream_deltas;
my $stream_response = $stream_adapter->generate_stream(
    $adapter_request,
    sub { push @stream_deltas, $_[0] },
);
is($stream_payload->{stream}, 1, 'openai stream flag');
is_deeply(\@stream_deltas, ['he', 'llo'], 'openai stream deltas');
is($stream_response->{message}{content}, 'hello', 'openai stream content');
is($stream_response->{message}{toolCalls}[0]{id}, 'call-1', 'openai stream call id');
is($stream_response->{message}{toolCalls}[0]{name}, 'echo', 'openai stream call name');
is_deeply($stream_response->{message}{toolCalls}[0]{arguments}, { text => 'hi' },
    'openai stream arguments');
is($stream_response->{usage}{inputTokens}, 4, 'openai stream input tokens');
is($stream_response->{usage}{outputTokens}, 2, 'openai stream output tokens');
is($stream_response->{finishReason}, 'tool_calls', 'openai stream finish reason');

my @agent_stream_deltas;
my $agent_stream_adapter = Praxo::Adapters::OpenAICompatible->new(
    base_url => 'http://example.test/v1',
    model => 'test-model',
    stream_transport => sub {
        return <<'SSE';
data: {"choices":[{"delta":{"content":"ok"}}]}

data: {"choices":[{"delta":{},"finish_reason":"stop"}]}

data: [DONE]
SSE
    },
);
my $agent_stream_options = Praxo::Agent::AgentOptions->new($agent_stream_adapter);
$agent_stream_options->{on_delta} = sub { push @agent_stream_deltas, $_[0] };
my $agent_stream_result = Praxo::Agent::run_agent(
    $agent_stream_options,
    Praxo::Models::session(id => 's1'),
    'go',
);
is($agent_stream_result->{output}, 'ok', 'openai agent stream output');
is_deeply(\@agent_stream_deltas, ['ok'], 'openai agent stream deltas');

my $assistant = Praxo::Models::message_assistant(
    '',
    [Praxo::Models::tool_call(id => 'call-2', name => 'echo', arguments => { text => 'bye' })],
);
$adapter->generate(Praxo::Models::request(messages => [$assistant]));
is($captured->[1]{messages}[0]{tool_calls}[0]{function}{arguments}, '{"text":"bye"}',
    'openai assistant tool call encoded');

my $harmovela_captured;
my $harmovela = Praxo::Adapters::Harmovela->new(
    base_url => 'http://example.test/aep/api/',
    clock => sub { return (1700000000, 123456789) },
    transport => sub {
        my ($path, $body, $headers) = @_;
        $harmovela_captured = { path => $path, body => $body, headers => $headers };
        return { status => 200, body => '' };
    },
);
my $harmovela_event = Praxo::Models::event(
    type => 'tool.call', session_id => 's1', run_id => 'run-123',
    data => { name => 'echo' },
);
$harmovela->emit($harmovela_event);
is($harmovela_captured->{path}, '/events', 'harmovela path');
is($harmovela_captured->{headers}{'content-type'}, 'application/json',
    'harmovela content type');
my $harmovela_envelope = Praxo::Json::parse($harmovela_captured->{body});
is($harmovela_envelope->{spec_version}, '0.2', 'harmovela spec version');
is($harmovela_envelope->{id}, 'run-123-1700000000123456789', 'harmovela id');
is($harmovela_envelope->{type}, 'tool.call', 'harmovela type');
is($harmovela_envelope->{source}, 'praxo-core', 'harmovela source');
is($harmovela_envelope->{created_at}, '2023-11-14T22:13:20.123456789Z',
    'harmovela created at');
is_deeply(
    $harmovela_envelope->{payload},
    { name => 'echo', session_id => 's1', run_id => 'run-123' },
    'harmovela payload',
);

my $harmovela_failed = Praxo::Adapters::Harmovela->new(
    base_url => 'http://example.test/aep/api',
    clock => sub { return (1700000000, 123456789) },
    transport => sub { return { status => 500, body => 'boom' } },
);
my $harmovela_error;
eval {
    $harmovela_failed->emit($harmovela_event);
    1;
} or $harmovela_error = $@;
ok(defined $harmovela_error, 'harmovela non-2xx raises');
is(
    Praxo::Errors::error_code($harmovela_error),
    'HARMOVELA_HTTP',
    'harmovela non-2xx code',
);
like("$harmovela_error", qr/500/, 'harmovela non-2xx status');
like("$harmovela_error", qr/boom/, 'harmovela non-2xx body');

my $anthropic_captured;
my $anthropic = Praxo::Adapters::Anthropic->new(
    model => 'claude-test',
    api_key => 'ak',
    transport => sub {
        my ($path, $payload) = @_;
        $anthropic_captured = [$path, $payload];
        return {
            content => [
                { type => 'text', text => 'hello' },
                { type => 'tool_use', id => 'tool-1', name => 'echo', input => { text => 'hi' } },
            ],
            stop_reason => 'end_turn',
            usage => { input_tokens => 3, output_tokens => 4, cache_read_input_tokens => 2 },
        };
    },
);
my $anthropic_response = $anthropic->generate(Praxo::Models::request(
    messages => [
        Praxo::Models::message_text('system', 'be brief'),
        Praxo::Models::message_text('user', 'hi'),
    ],
    tools => [Praxo::Models::tool_spec(
        name => 'echo', description => 'Echo', parameters => { type => 'object' },
    )],
));
is($anthropic_captured->[0], '/v1/messages', 'anthropic path');
is($anthropic_captured->[1]{system}, 'be brief', 'anthropic system');
is($anthropic_captured->[1]{tools}[0]{input_schema}{type}, 'object', 'anthropic tools');
is($anthropic_response->{message}{content}, 'hello', 'anthropic content');
is($anthropic_response->{message}{toolCalls}[0]{id}, 'tool-1', 'anthropic call id');
is($anthropic_response->{usage}{cachedTokens}, 2, 'anthropic cached tokens');

my @anthropic_events = (
    { type => 'message_start', message => { usage => { input_tokens => 4, cache_read_input_tokens => 1 } } },
    { type => 'content_block_start', index => 0, content_block => { type => 'text', text => '' } },
    { type => 'content_block_delta', index => 0, delta => { type => 'text_delta', text => 'he' } },
    { type => 'content_block_delta', index => 0, delta => { type => 'text_delta', text => 'llo' } },
    { type => 'content_block_start', index => 1, content_block => { type => 'tool_use', id => 'call-1', name => 'echo', input => {} } },
    { type => 'content_block_delta', index => 1, delta => { type => 'input_json_delta', partial_json => '{"text":' } },
    { type => 'content_block_delta', index => 1, delta => { type => 'input_json_delta', partial_json => '"hi"}' } },
    { type => 'message_delta', delta => { stop_reason => 'tool_use' }, usage => { output_tokens => 2 } },
    { type => 'message_stop' },
);
my $anthropic_stream_text = join("\n\n", map {
    'data: ' . Praxo::Json::stringify($_)
} @anthropic_events);
my $anthropic_stream = Praxo::Adapters::Anthropic->new(
    model => 'claude-test',
    api_key => 'ak',
    stream_transport => sub {
        my ($path, $payload) = @_;
        is($path, '/v1/messages', 'anthropic stream path');
        ok($payload->{stream}, 'anthropic stream flag');
        return $anthropic_stream_text;
    },
);
my @anthropic_deltas;
my $anthropic_stream_response = $anthropic_stream->generate_stream(
    Praxo::Models::request(messages => [Praxo::Models::message_text('user', 'hi')]),
    sub { push @anthropic_deltas, $_[0] },
);
is_deeply(\@anthropic_deltas, ['he', 'llo'], 'anthropic stream deltas');
is($anthropic_stream_response->{message}{content}, 'hello', 'anthropic stream content');
is($anthropic_stream_response->{message}{toolCalls}[0]{id}, 'call-1', 'anthropic stream call id');
is_deeply($anthropic_stream_response->{message}{toolCalls}[0]{arguments}, { text => 'hi' },
    'anthropic stream args');
is($anthropic_stream_response->{usage}{inputTokens}, 4, 'anthropic stream input tokens');
is($anthropic_stream_response->{usage}{outputTokens}, 2, 'anthropic stream output tokens');
is($anthropic_stream_response->{usage}{cachedTokens}, 1, 'anthropic stream cached');
is($anthropic_stream_response->{finishReason}, 'tool_use', 'anthropic stream finish');

my $gemini_captured;
my $gemini = Praxo::Adapters::Gemini->new(
    model => 'gemini-test',
    api_key => 'gk',
    transport => sub {
        my ($path, $payload) = @_;
        $gemini_captured = [$path, $payload];
        return {
            candidates => [{
                content => { parts => [
                    { text => 'hello' },
                    { functionCall => { name => 'echo', args => { text => 'hi' } } },
                ] },
                finishReason => 'STOP',
            }],
            usageMetadata => { promptTokenCount => 3, candidatesTokenCount => 4 },
        };
    },
);
my $gemini_response = $gemini->generate(Praxo::Models::request(
    messages => [
        Praxo::Models::message_text('system', 'be brief'),
        Praxo::Models::message_text('user', 'hi'),
    ],
    tools => [Praxo::Models::tool_spec(
        name => 'echo', description => 'Echo', parameters => { type => 'object' },
    )],
));
like($gemini_captured->[0], qr/:generateContent$/, 'gemini path');
is($gemini_captured->[1]{system_instruction}{parts}[0]{text}, 'be brief', 'gemini system');
is($gemini_captured->[1]{toolConfig}{functionCallingConfig}{mode}, 'AUTO', 'gemini tool mode');
is($gemini_response->{message}{content}, 'hello', 'gemini content');
is($gemini_response->{message}{toolCalls}[0]{name}, 'echo', 'gemini call name');
is($gemini_response->{usage}{inputTokens}, 3, 'gemini usage');

my $gemini_stream_captured;
my $gemini_stream = Praxo::Adapters::Gemini->new(
    model => 'gemini-test',
    api_key => 'gk',
    stream_transport => sub {
        my ($path, $payload) = @_;
        $gemini_stream_captured = [$path, $payload];
        return join("\n\n",
            'data: {"candidates":[{"content":{"parts":[{"text":"he"}]}}]}',
            'data: {"candidates":[{"content":{"parts":[{"text":"llo"},'
                . '{"functionCall":{"name":"echo","args":{"text":"hi"}}}]},'
                . '"finishReason":"STOP"}],"usageMetadata":{"promptTokenCount":4,'
                . '"candidatesTokenCount":2,"cachedContentTokenCount":1}}',
        );
    },
);
my @gemini_deltas;
my $gemini_stream_response = $gemini_stream->generate_stream(
    Praxo::Models::request(
        messages => [Praxo::Models::message_text(Praxo::Models::USER(), 'hi')],
    ),
    sub { push @gemini_deltas, $_[0] },
);
like($gemini_stream_captured->[0], qr/:streamGenerateContent/, 'gemini stream path');
like($gemini_stream_captured->[0], qr/alt=sse/, 'gemini stream alt');
is(join('', @gemini_deltas), 'hello', 'gemini stream deltas');
is($gemini_stream_response->{message}{content}, 'hello', 'gemini stream content');
is($gemini_stream_response->{message}{toolCalls}[0]{name}, 'echo', 'gemini stream call');
is($gemini_stream_response->{usage}{inputTokens}, 4, 'gemini stream usage');
is($gemini_stream_response->{usage}{outputTokens}, 2, 'gemini stream output');
is($gemini_stream_response->{usage}{cachedTokens}, 1, 'gemini stream cached');
is($gemini_stream_response->{finishReason}, 'STOP', 'gemini stream finish');
ok($gemini_stream_captured->[1]{contents}, 'gemini stream payload');


my $mcp = Praxo::Adapters::MCP->new(
    transport => sub {
        my ($method, $params) = @_;
        if ($method eq 'initialize') {
            return { protocolVersion => '2024-11-05', serverInfo => { name => 'fake' } };
        }
        if ($method eq 'tools/list') {
            return { tools => [{ name => 'echo' }] } if $params->{cursor};
            return { tools => [{ name => 'add' }], nextCursor => 'next' };
        }
        if ($method eq 'tools/call') {
            return { structuredContent => { ok => 1 } } if $params->{name} eq 'echo';
            return { content => [{ type => 'text', text => 'hello' }] }
                if $params->{name} eq 'text';
            return { isError => 1 } if $params->{name} eq 'fail';
        }
        return {};
    },
);
$mcp->start;
is($mcp->protocol_version, '2024-11-05', 'mcp protocol version');
is_deeply($mcp->list_tools, [{ name => 'add' }, { name => 'echo' }],
    'mcp paginated tools');
is_deeply($mcp->call_tool('echo'), { ok => 1 }, 'mcp structured tool');
is($mcp->call_tool('text'), 'hello', 'mcp text tool');
my $mcp_error;
eval { $mcp->call_tool('fail') };
$mcp_error = $@;
is(Praxo::Errors::error_code($mcp_error), 'MCP_TOOL_ERROR', 'mcp tool error');
$mcp->close;

{
    package TestHTTPMCP;
    our @ISA = ('Praxo::Adapters::MCPHTTP');

    sub _post {
        my ($self, $method, $body, $headers) = @_;
        push @{ $self->{seen} }, { method => $method, headers => $headers };
        return (200, {}, '') if $method eq 'DELETE';
        my $message = JSON::PP::decode_json($body);
        my $name = $message->{method} // '';
        my $id = $message->{id};
        if ($name eq 'initialize') {
            return (200, {
                'mcp-session-id' => 'sess-1',
                'content-type' => 'application/json',
            }, JSON::PP::encode_json({
                jsonrpc => '2.0',
                id => $id,
                result => {
                    protocolVersion => '2025-03-26',
                    capabilities => {},
                    serverInfo => { name => 'fake-http' },
                },
            }));
        }
        if ($name =~ m{^notifications/}) {
            return (202, {}, '');
        }
        if ($name eq 'tools/list') {
            return (200, { 'content-type' => 'application/json' },
                JSON::PP::encode_json({
                    jsonrpc => '2.0',
                    id => $id,
                    result => {
                        tools => [{
                            name => 'echo',
                            description => 'Echo input',
                            inputSchema => {
                                type => 'object',
                                properties => { text => { type => 'string' } },
                                required => ['text'],
                            },
                        }],
                    },
                }));
        }
        if ($name eq 'tools/call') {
            my $payload = JSON::PP::encode_json({
                jsonrpc => '2.0',
                id => $id,
                result => { content => [{ type => 'text', text => 'sse-ok' }] },
            });
            return (200, { 'content-type' => 'text/event-stream' },
                "event: message\ndata: $payload\n\n");
        }
        return (200, { 'content-type' => 'application/json' },
            JSON::PP::encode_json({
                jsonrpc => '2.0',
                id => $id,
                result => {},
            }));
    }
}

my $http = TestHTTPMCP->new(endpoint => 'http://127.0.0.1/mcp');
my $http_client = Praxo::Adapters::MCP->new(
    transport => $http,
    protocol_version => '2025-03-26',
);
$http_client->start;
is($http_client->protocol_version, '2025-03-26', 'http mcp protocol version');
is_deeply(
    [map { $_->{name} } @{ $http_client->list_tools }],
    ['echo'],
    'http mcp tools'
);
is($http_client->call_tool('echo', { text => 'hi' }), 'sse-ok', 'http mcp sse call');
$http_client->close;
my ($listed) = grep {
    $_->{method} eq 'POST'
        && ($_->{headers}{'mcp-session-id'} // '') eq 'sess-1'
} @{ $http->{seen} };
ok($listed, 'http mcp session header');
my ($protocol) = grep {
    ($_->{headers}{'mcp-protocol-version'} // '') eq '2025-03-26'
} @{ $http->{seen} };
ok($protocol, 'http mcp protocol header');
ok((grep { $_->{method} eq 'DELETE' } @{ $http->{seen} }), 'http mcp delete');

my $http_rejected;
eval { Praxo::Adapters::MCPHTTP->new(endpoint => 'http://example.com/mcp') };
$http_rejected = $@;
is(
    Praxo::Errors::error_code($http_rejected),
    'MCP_TRANSPORT',
    'http mcp https required'
);

my $otel_captured;
my $otel = Praxo::Adapters::Otel->new(
    endpoint => 'https://otel.test/v1/traces',
    allowed_data_keys => ['name'],
    clock => sub { return 1794294000000000000 },
    transport => sub {
        my ($url, $body, $headers) = @_;
        $otel_captured = { url => $url, body => $body, headers => $headers };
        return { status => 200, body => '' };
    },
);
my $otel_event = Praxo::Models::event(
    type => 'tool.call', session_id => 's1', run_id => 'run-123',
    data => { name => 'echo', secret => 'hidden' },
);
$otel->emit($otel_event);
is($otel_captured->{url}, 'https://otel.test/v1/traces', 'otel url');
is($otel_captured->{headers}{'content-type'}, 'application/json',
    'otel content type');
my $otel_payload = Praxo::Json::parse($otel_captured->{body});
my $otel_span = $otel_payload->{resourceSpans}[0]{scopeSpans}[0]{spans}[0];
is($otel_span->{name}, 'praxo.tool.call', 'otel span name');
is(length($otel_span->{traceId}), 32, 'otel trace id');
is(length($otel_span->{spanId}), 16, 'otel span id');
is($otel_span->{startTimeUnixNano}, '1794294000000000000',
    'otel timestamp');
my %otel_keys = map { $_->{key} => 1 } @{ $otel_span->{attributes} };
ok($otel_keys{'praxo.event.data.name'}, 'otel allowed data');
ok(!$otel_keys{'praxo.event.data.secret'}, 'otel hidden data');

my $otel_failed = Praxo::Adapters::Otel->new(
    endpoint => 'https://otel.test/v1/traces',
    transport => sub { return { status => 503, body => 'unavailable' } },
);
my $otel_error;
eval {
    $otel_failed->emit($otel_event);
    1;
} or $otel_error = $@;
is(
    Praxo::Errors::error_code($otel_error),
    'OTEL_HTTP',
    'otel non-2xx code',
);

my $retriever = Praxo::Adapters::Retriever::func_retriever(sub {
    my ($query, $limit) = @_;
    return [Praxo::Adapters::Retriever::document(
        id => 'doc-1',
        content => "$query:$limit",
    )];
});
my $documents =
    Praxo::Adapters::Retriever::retrieve_documents($retriever, 'hello', 3);
is(scalar @$documents, 1, 'retriever count');
is($documents->[0]{content}, 'hello:3', 'retriever query');
my $retriever_error;
eval {
    Praxo::Adapters::Retriever::retrieve_documents($retriever, 'hello', -1);
    1;
} or $retriever_error = $@;
is(
    Praxo::Errors::error_code($retriever_error),
    'RETRIEVER_INVALID',
    'retriever invalid limit',
);

my $request = {
    parentSessionId => 'parent',
    agentId => 'child',
    prompt => 'look up',
    mode => 'fork',
};
my $task = Praxo::Adapters::Delegation::subagent_run(
    sub {
        my ($request) = @_;
        return {
            taskId => 'task-1',
            agentId => $request->{agentId},
            output => 'done',
        };
    },
    $request,
);
is($task->{status}, 'completed', 'delegate completed');
is($task->{mode}, 'fork', 'delegate mode');
is($task->{output}, 'done', 'delegate output');
my $failed_task = Praxo::Adapters::Delegation::subagent_run(
    sub { Praxo::Errors::praxo_error('BOOM', 'boom') },
    $request,
);
is($failed_task->{status}, 'failed', 'delegate failed status');
is($failed_task->{error}, 'BOOM', 'delegate failed code');
my $delegate_error;
eval {
    Praxo::Adapters::Delegation::subagent_run(
        sub { return { output => 'never' } },
        { parentSessionId => '', agentId => 'child', prompt => 'look up' },
    );
    1;
} or $delegate_error = $@;
is(
    Praxo::Errors::error_code($delegate_error),
    'SUBAGENT_INVALID',
    'delegate invalid',
);

my $schema_registry = Praxo::Agent::ToolRegistry->new;
$schema_registry->register(Praxo::Agent::FuncTool->new(
    'record',
    'Record a target.',
    sub { return 'recorded' },
    {
        type => 'object',
        required => ['target'],
        properties => { target => { type => 'string' } },
    },
    'write',
));
my $schema_spec = $schema_registry->specs->[0];
is($schema_spec->{parameters}{required}[0], 'target', 'tool schema parameters');
is($schema_spec->{risk}, 'write', 'tool schema risk');

my $interrupt_steps = [
    {
        content => '',
        toolCalls => [{
            id => 'interrupt-1',
            name => 'echo',
            arguments => { text => 'hi' },
        }],
    },
    { content => 'done' },
];

my $approve_invocations = 0;
my $approve_registry = Praxo::Agent::ToolRegistry->new;
$approve_registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo', sub {
    $approve_invocations++;
    return $_[0];
}));
my $approve_sink = TestSink->new;
my $approve_model = TestModel->new($interrupt_steps);
my $approve_options = Praxo::Agent::AgentOptions->new($approve_model);
$approve_options->{tools} = $approve_registry;
$approve_options->{events} = $approve_sink;
$approve_options->{interrupt_on} = ['echo'];
my $approved_interrupt;
$approve_options->{on_interrupt_decision} = sub {
    $approved_interrupt = $_[0];
    return Praxo::Models::interrupt_decision(
        action => Praxo::Models::INTERRUPT_APPROVE(),
    );
};
my $approve_result = Praxo::Agent::run_agent(
    $approve_options, Praxo::Models::session(id => 'hitl-approve'), 'go',
);
is($approve_result->{output}, 'done', 'hitl approve output');
is($approve_invocations, 1, 'hitl approve invokes tool');
is_deeply(
    $approve_sink->types,
    [qw(run.started tool.interrupt tool.call run.completed)],
    'hitl approve events',
);
is($approve_sink->events->[1]{data}{name}, 'echo', 'hitl interrupt event name');
is_deeply(
    $approve_sink->events->[1]{data}{arguments},
    { text => 'hi' },
    'hitl interrupt event arguments',
);
is($approved_interrupt->{runId}, $approve_result->{runId},
    'hitl interrupt run id');
is($approved_interrupt->{sessionId}, 'hitl-approve', 'hitl interrupt session id');
is($approved_interrupt->{call}{name}, 'echo', 'hitl interrupt call name');

my $edit_invocations = 0;
my $edit_registry = Praxo::Agent::ToolRegistry->new;
$edit_registry->register(Praxo::Agent::FuncTool->new('write_note', 'Write', sub {
    $edit_invocations++;
    return 'written';
}));
my $edit_options = Praxo::Agent::AgentOptions->new(TestModel->new([
    {
        content => '',
        toolCalls => [{
            id => 'edit-1',
            name => 'write_note',
            arguments => { text => 'hello', visibility => 'public' },
        }],
    },
    { content => 'done' },
]));
$edit_options->{tools} = $edit_registry;
$edit_options->{allowed_tools} = ['write_note'];
$edit_options->{interrupt_on} = ['write_note'];
$edit_options->{policy} = sub {
    my ($action) = @_;
    if ($action->{kind} eq 'model.generate') {
        return Praxo::Models::decision(allowed => 1);
    }
    my $public = ($action->{arguments}{visibility} // '') eq 'public';
    return Praxo::Models::decision(
        allowed => $public,
        reason => 'only public notes are permitted',
    );
};
$edit_options->{on_interrupt_decision} = sub {
    return Praxo::Models::interrupt_decision(
        action => Praxo::Models::INTERRUPT_EDIT(),
        arguments => { text => 'hello', visibility => 'private' },
    );
};
my $edit_ok = eval {
    Praxo::Agent::run_agent(
        $edit_options, Praxo::Models::session(id => 'hitl-edit'), 'go',
    );
    1;
};
my $edit_error = $@;
is($edit_ok, undef, 'hitl edit rejected');
is(Praxo::Errors::error_code($edit_error), 'POLICY_ERROR',
    'hitl edit reauthorization code');
is($edit_invocations, 0, 'hitl edit has no effects');

my $reject_invocations = 0;
my $reject_registry = Praxo::Agent::ToolRegistry->new;
$reject_registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo', sub {
    $reject_invocations++;
    return $_[0];
}));
my $reject_sink = TestSink->new;
my $reject_options = Praxo::Agent::AgentOptions->new(TestModel->new($interrupt_steps));
$reject_options->{tools} = $reject_registry;
$reject_options->{events} = $reject_sink;
$reject_options->{interrupt_on} = ['echo'];
$reject_options->{on_interrupt_decision} = sub {
    return Praxo::Models::interrupt_decision(
        action => Praxo::Models::INTERRUPT_REJECT(),
        reason => 'not allowed',
    );
};
my $reject_ok = eval {
    Praxo::Agent::run_agent(
        $reject_options, Praxo::Models::session(id => 'hitl-reject'), 'go',
    );
    1;
};
my $reject_error = $@;
is($reject_ok, undef, 'hitl reject fails run');
is(Praxo::Errors::error_code($reject_error), 'AGENT_APPROVAL_DENIED',
    'hitl reject code');
like("$reject_error", qr/not allowed/, 'hitl reject reason');
is($reject_invocations, 0, 'hitl reject has no effects');
is_deeply(
    $reject_sink->types,
    [qw(run.started tool.interrupt run.failed)],
    'hitl reject events',
);

my $respond_invocations = 0;
my $respond_registry = Praxo::Agent::ToolRegistry->new;
$respond_registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo', sub {
    $respond_invocations++;
    return $_[0];
}));
my $respond_sink = TestSink->new;
my $respond_model = TestModel->new($interrupt_steps);
my $respond_options = Praxo::Agent::AgentOptions->new($respond_model);
$respond_options->{tools} = $respond_registry;
$respond_options->{events} = $respond_sink;
$respond_options->{interrupt_on} = ['echo'];
$respond_options->{on_interrupt_decision} = sub {
    return Praxo::Models::interrupt_decision(
        action => Praxo::Models::INTERRUPT_RESPOND(),
        response => 'human answer',
    );
};
my $respond_result = Praxo::Agent::run_agent(
    $respond_options, Praxo::Models::session(id => 'hitl-respond'), 'go',
);
is($respond_result->{output}, 'done', 'hitl respond output');
is($respond_invocations, 0, 'hitl respond skips tool');
is_deeply(
    $respond_sink->types,
    [qw(run.started tool.interrupt run.completed)],
    'hitl respond events',
);
my $respond_requests = $respond_model->requests;
is(
    $respond_requests->[1]{messages}[-1]{content},
    Praxo::Json::stringify('human answer'),
    'hitl respond feeds response to model',
);

my $unhandled_registry = Praxo::Agent::ToolRegistry->new;
$unhandled_registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo', sub {
    return $_[0];
}));
my $unhandled_sink = TestSink->new;
my $unhandled_options = Praxo::Agent::AgentOptions->new(TestModel->new($interrupt_steps));
$unhandled_options->{tools} = $unhandled_registry;
$unhandled_options->{events} = $unhandled_sink;
$unhandled_options->{interrupt_on} = ['echo'];
my $unhandled_ok = eval {
    Praxo::Agent::run_agent(
        $unhandled_options, Praxo::Models::session(id => 'hitl-unhandled'), 'go',
    );
    1;
};
my $unhandled_error = $@;
is($unhandled_ok, undef, 'hitl unhandled fails run');
is(Praxo::Errors::error_code($unhandled_error), 'AGENT_INTERRUPT_UNHANDLED',
    'hitl unhandled code');
ok(!(grep { $_ eq 'tool.interrupt' } @{ $unhandled_sink->types }),
    'hitl unhandled emits no interrupt event');

my $invalid_registry = Praxo::Agent::ToolRegistry->new;
$invalid_registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo', sub {
    return $_[0];
}));
my $invalid_options = Praxo::Agent::AgentOptions->new(TestModel->new($interrupt_steps));
$invalid_options->{tools} = $invalid_registry;
$invalid_options->{interrupt_on} = ['echo'];
$invalid_options->{on_interrupt_decision} = sub {
    return Praxo::Models::interrupt_decision(action => 'invalid');
};
my $invalid_ok = eval {
    Praxo::Agent::run_agent(
        $invalid_options, Praxo::Models::session(id => 'hitl-invalid'), 'go',
    );
    1;
};
my $invalid_error = $@;
is($invalid_ok, undef, 'hitl invalid fails run');
is(Praxo::Errors::error_code($invalid_error), 'AGENT_INTERRUPT_DECISION_INVALID',
    'hitl invalid code');

my $edit_missing_options = Praxo::Agent::AgentOptions->new(TestModel->new($interrupt_steps));
$edit_missing_options->{tools} = $invalid_registry;
$edit_missing_options->{interrupt_on} = ['echo'];
$edit_missing_options->{on_interrupt_decision} = sub {
    return Praxo::Models::interrupt_decision(
        action => Praxo::Models::INTERRUPT_EDIT(),
    );
};
my $edit_missing_ok = eval {
    Praxo::Agent::run_agent(
        $edit_missing_options, Praxo::Models::session(id => 'hitl-edit-missing'), 'go',
    );
    1;
};
my $edit_missing_error = $@;
is($edit_missing_ok, undef, 'hitl edit without arguments fails run');
is(
    Praxo::Errors::error_code($edit_missing_error),
    'AGENT_INTERRUPT_DECISION_INVALID',
    'hitl edit without arguments code',
);

my $legacy_invocations = 0;
my $legacy_registry = Praxo::Agent::ToolRegistry->new;
$legacy_registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo', sub {
    $legacy_invocations++;
    return $_[0];
}));
my $legacy_options = Praxo::Agent::AgentOptions->new(TestModel->new($interrupt_steps));
$legacy_options->{tools} = $legacy_registry;
$legacy_options->{interrupt_on} = ['echo'];
$legacy_options->{on_interrupt} = sub { 1 };
my $legacy_result = Praxo::Agent::run_agent(
    $legacy_options, Praxo::Models::session(id => 'hitl-legacy-approve'), 'go',
);
is($legacy_result->{output}, 'done', 'hitl legacy approval output');
is($legacy_invocations, 1, 'hitl legacy approval invokes tool');

my $legacy_denied_options = Praxo::Agent::AgentOptions->new(TestModel->new($interrupt_steps));
$legacy_denied_options->{tools} = $legacy_registry;
$legacy_denied_options->{interrupt_on} = ['echo'];
$legacy_denied_options->{on_interrupt} = sub { 0 };
my $legacy_denied_ok = eval {
    Praxo::Agent::run_agent(
        $legacy_denied_options,
        Praxo::Models::session(id => 'hitl-legacy-deny'),
        'go',
    );
    1;
};
my $legacy_denied_error = $@;
is($legacy_denied_ok, undef, 'hitl legacy denial fails run');
is(
    Praxo::Errors::error_code($legacy_denied_error),
    'AGENT_APPROVAL_DENIED',
    'hitl legacy denial code',
);

done_testing();
