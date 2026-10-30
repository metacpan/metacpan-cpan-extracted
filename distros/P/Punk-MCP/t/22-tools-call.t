#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $pkg = 'T22::A';
my $t = mcp_app(qq{
    package ${pkg}::Controller::T;
    sub echo {
        my (\$c) = \@_;
        return { q => \$c->param('q'), n => \$c->param('n'),
                 who => \$c->stash->{who}, user => \$c->mcp_user };
    }
    sub meta {
        my (\$c) = \@_;
        my \$m = \$c->mcp;
        return { method => \$m->method, name => \$m->name,
                 arguments => \$m->arguments, protocol => \$m->protocol,
                 progress => \$m->progress_token, cancelled => \$m->cancelled };
    }
    sub web    { my (\$c) = \@_; return \$c->text(defined \$c->mcp ? 'mcp' : 'web') }
    sub die_nl { die "shelf fell over\\n" }
    sub die_at { die "shelf fell over" }
    sub die_obj { die { code => 7 } }
    package $pkg;
    get '/web' => 'T#web';
    plugin 'MCP' => { session => 0 };
    mcp tool => echo => {
        input => { type => 'object', required => ['q'],
                   properties => { q => { type => 'string' }, n => { type => 'integer' } } },
    } => 'T#echo';
    mcp tool => meta    => 'T#meta';
    mcp tool => web     => 'T#web';
    mcp tool => die_nl  => 'T#die_nl';
    mcp tool => die_at  => 'T#die_at';
    mcp tool => die_obj => 'T#die_obj';
}, pkg => $pkg, pre => q{ $c->stash->{who} = 'alice'; $c->stash->{'mcp.user'} = 'u-42'; });

# ---- arguments, the stash, the call object -------------------------------------

my ($s, $r) = call_tool($t, 'echo', { q => 'perl', n => 3 });
is($s, 200, 'a call is 200');
is_deeply($r->{result}{structuredContent},
    { q => 'perl', n => 3, who => 'alice', user => 'u-42' },
    '$c->param reads the arguments, the stash carries over, mcp_user reads it');

(undef, $r) = rpc_msg($t, 'tools/call',
    { name => 'meta', arguments => { a => 1 }, _meta => { progressToken => 'p-9' } });
is_deeply($r->{result}{structuredContent}, {
    method => 'tools/call', name => 'meta', arguments => { a => 1 },
    protocol => '2025-11-25', progress => 'p-9', cancelled => 0,
}, '$c->mcp describes the call');

(undef, $r) = call_tool($t, 'web');
is($r->{result}{content}[0]{text}, 'mcp', 'inside a tool call $c->mcp is set');
$t->get_ok('/web');
is($t->body, 'web', 'and on the same action through its route it is undef');

(undef, $r) = call_tool($t, 'meta');
is_deeply($r->{result}{structuredContent}{arguments}, {}, 'no arguments is {}');

# ---- what is refused, and how ------------------------------------------------------

for my $case (
    [ { name => 'nope' },                        'unknown tool' ],
    [ {},                                        'a tool name is required' ],
    [ { name => 7 },                             'a tool name is required' ],
    [ { name => 'echo', arguments => [1] },      'arguments must be an object' ],
) {
    my ($params, $msg) = @$case;
    (undef, $r) = rpc_msg($t, 'tools/call', $params);
    is($r->{error}{code}, -32602, "$msg: -32602");
    is($r->{error}{message}, $msg, "$msg: says so");
}

# Argument validation: a tool error from 2025-11-25, a protocol error before (P5).
(undef, $r) = call_tool($t, 'echo', { n => 'x' });
ok($r->{result}{isError}, '2025-11-25: bad arguments are a tool error');
like($r->{result}{content}[0]{text}, qr/^invalid arguments: .*required/,
    'with the errors in words');
is(scalar @{ $r->{result}{structuredContent}{errors} }, 2,
    'and as data: the missing q and the bad n');

for my $v ('2025-06-18', '2025-03-26') {
    (undef, $r) = call_tool($t, 'echo', { n => 'x' }, $v);
    is($r->{error}{code}, -32602, "$v: bad arguments are -32602");
    is(scalar @{ $r->{error}{data}{errors} }, 2, "$v: with data.errors");
}

# ---- a die -----------------------------------------------------------------------

(undef, $r) = call_tool($t, 'die_nl');
ok($r->{result}{isError}, 'a die is a tool error');
is($r->{result}{content}[0]{text}, 'shelf fell over', 'with its message');

(undef, $r) = call_tool($t, 'die_at');
is($r->{result}{content}[0]{text}, 'shelf fell over',
    'the " at FILE line N." perl added is dropped');

(undef, $r) = call_tool($t, 'die_obj');
is($r->{result}{content}[0]{text}, 'the tool failed',
    'an exception object is not stringified as a hash address');

(undef, $r) = call_tool($t, 'echo', { q => 'after' });
is($r->{result}{structuredContent}{q}, 'after', 'and calls after a die are whole');

done_testing;
