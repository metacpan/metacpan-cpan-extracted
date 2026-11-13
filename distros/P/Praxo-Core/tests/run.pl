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
sub new { bless { types => [] }, shift }
sub emit { push @{ $_[0]{types} }, $_[1]{type} }
sub types { $_[0]{types} }

package TestModel;
sub new { bless { steps => $_[1], next => 0 }, shift }
sub generate {
    my ($self) = @_;
    my $step = $self->{steps}[ $self->{next}++ ];
    my @calls = map {
        Praxo::Models::tool_call(id => $_->{id}, name => $_->{name}, arguments => $_->{arguments})
    } @{ $step->{toolCalls} // [] };
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($step->{content} // '', \@calls),
    );
}

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

done_testing();
