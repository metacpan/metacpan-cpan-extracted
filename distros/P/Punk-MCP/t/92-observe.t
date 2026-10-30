#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'Punk::Plugin::OpenTelemetry is not installed'
        unless eval { require Punk::Plugin::OpenTelemetry; 1 };
}

use JSON::PP ();
use Punk::Test;

my $J = JSON::PP->new->canonical;
my $n = 0;

sub otel_app {
    my ($sampler) = @_;
    my $pkg = 'PMCPOtel::T' . ++$n;
    eval qq{
        package $pkg;
        use Punk;
        use Punk::Plugin::OpenTelemetry;
        use Punk::Plugin::MCP;
        otel service_name => 't92', sampler => '$sampler';
        plugin 'OpenTelemetry';
        plugin 'MCP';
        mcp tool => echo => sub { 'hi' };
        mcp tool => boom => sub { die "no\\n" };
        mcp resource => 'books://{id}' => sub { 'a book' };
        mcp prompt => greet => sub { 'hello' };
        1;
    } or die $@;
    return ($pkg, Punk::Test->new($pkg));
}

sub send_msg {
    my ($t, $msg) = @_;
    $t->post_ok('/mcp', body => $J->encode({ jsonrpc => '2.0', %$msg }),
                type => 'application/json', headers => { Accept => 'application/json' });
}

# Every queued span, as { name => span hash }, the MCP ones and the server ones.
sub spans {
    my ($pkg) = @_;
    my $p = Punk::Plugin::OpenTelemetry->state_for($pkg)->{tracer}->drain(1000) or return [];
    return [ map { @{ $_->{spans} } } map { @{ $_->{scope_spans} } } @{ $p->{resource_spans} } ];
}

my ($pkg, $t) = otel_app('always_on');
send_msg($t, { id => 1, method => 'tools/call', params => { name => 'echo' } });
send_msg($t, { id => 'b', method => 'tools/call', params => { name => 'boom' } });
send_msg($t, { id => 3, method => 'tools/call', params => { name => 'nope' } });
send_msg($t, { id => 4, method => 'resources/read', params => { uri => 'books://7' } });
send_msg($t, { id => 5, method => 'prompts/get', params => { name => 'greet' } });
send_msg($t, { id => 6, method => 'tools/list' });
send_msg($t, { method => 'notifications/initialized' });

my @all = @{ spans($pkg) };
my %by = map { $_->{name} => $_ } @all;
my %server = map { $_->{span_id} => $_ } grep { $_->{name} eq 'POST /mcp' } @all;
is(scalar(keys %server), 7, 'a server span per request, as before');

my $echo = $by{'tools/call echo'};
ok($echo, 'a tool call makes a span named "{method} {tool}"');
is($echo->{kind}, 2, 'kind SERVER');
ok($echo->{parent_span_id} && $server{ $echo->{parent_span_id} },
   'a child of the request\'s server span');
is($echo->{trace_id}, $server{ $echo->{parent_span_id} }{trace_id}, 'in its trace');
is_deeply([ @{ $echo->{attributes} }{qw(mcp.method.name gen_ai.tool.name jsonrpc.request.id mcp.protocol.version)} ],
          ['tools/call', 'echo', '1', '2025-03-26'], 'with the MCP attributes');
ok(!exists $echo->{attributes}{'error.type'} && !$echo->{status}, 'no error on a good call');

my $boom = $by{'tools/call boom'};
is($boom->{attributes}{'error.type'}, 'tool_error', 'a tool error sets error.type tool_error');
ok(!$boom->{status}, 'and leaves the status unset: the call worked');
is($boom->{attributes}{'jsonrpc.request.id'}, 'b', 'a string id as given');

my $nope = $by{'tools/call nope'};
is($nope->{attributes}{'error.type'}, '-32602', 'a JSON-RPC error sets error.type to its code');
is($nope->{status}{code}, 2, 'and the status to ERROR');
is($nope->{status}{message}, 'unknown tool', 'with the message');

my $read = $by{'resources/read'};
is($read->{attributes}{'mcp.resource.uri'}, 'books://7', 'resources/read carries mcp.resource.uri');
ok(!exists $read->{attributes}{'gen_ai.tool.name'}, 'and no tool name');

is($by{'prompts/get greet'}{attributes}{'gen_ai.prompt.name'}, 'greet',
   'prompts/get carries gen_ai.prompt.name');
ok($by{'tools/list'}, 'a method with no target is named for the method alone');
is(scalar(grep { $_->{name} =~ /^notifications/ } @all), 0, 'a notification makes no span');

($pkg, $t) = otel_app('always_off');
send_msg($t, { id => 1, method => 'tools/call', params => { name => 'echo' } });
is_deeply(spans($pkg), [], 'an unsampled request makes no MCP span either');

done_testing;
