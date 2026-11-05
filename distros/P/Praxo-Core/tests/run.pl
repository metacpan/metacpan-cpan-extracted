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

done_testing();
