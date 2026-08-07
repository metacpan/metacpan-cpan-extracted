#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Router::Scope;

# The scope object itself (xs/scope.xs): what it records into the app, and
# the details that are easy to lose in a port - the '/' path edge cases, the
# guard chain being copied rather than shared, nesting keeping the subclass,
# and each verb reaching route with the right method.
#
# t/03-under.t covers scopes through a live app; this covers the object.

my @calls;
{
    package FakeApp;
    sub new       { bless {}, shift }
    sub route     { shift; push @calls, [ route     => @_ ]; return }
    sub websocket { shift; push @calls, [ websocket => @_ ]; return }
    sub api       { shift; push @calls, [ api       => @_ ]; return 'THE-MOUNT' }
}

my $app = FakeApp->new;
my $g1  = sub { 'g1' };
my $s   = Punk::Router::Scope->new(
    app => $app, prefix => '/admin', guards => [ $g1 ]);

isa_ok($s, 'Punk::Router::Scope');
is($s->prefix, '/admin', 'prefix');
is_deeply($s->guards, [ $g1 ], 'guards');
isnt($s->guards, $s->guards, 'guards hands back a fresh copy each time');

# ---- the verbs --------------------------------------------------------------

@calls = ();
$s->get('/books'  => 'T#a');
$s->post('/books' => 'T#b');
$s->put('/x'      => 'T#c');
$s->patch('/x'    => 'T#d');
$s->del('/x'      => 'T#e');
$s->any('/x'      => 'T#f');

is_deeply([ map $_->[1], @calls ], [ qw(GET POST PUT PATCH DELETE ANY) ],
    'each verb reaches route with its method');
is($calls[0][2], '/admin/books', 'the prefix concatenates');
is($calls[0][3], 'T#a',          'the target passes through');
is_deeply($calls[0][4], [ $g1 ], 'the guard chain comes along');
isnt($calls[0][4], $calls[1][4],
    'each route gets its own arrayref, not the scope\'s');

is($s->get('/c' => 'T#c'), $s, 'verbs chain');

# ---- the '/' edge cases -----------------------------------------------------

@calls = ();
$s->get('/' => 'T#root');
is($calls[0][2], '/admin', "a '/' path contributes nothing to the prefix");

my $root = Punk::Router::Scope->new(app => $app, prefix => '', guards => []);
@calls = ();
$root->get('/' => 'T#r');
is($calls[0][2], '/', 'an empty result is the root');

# ---- nesting ----------------------------------------------------------------

my $g2 = sub { 'g2' };
my $in = $s->under('/super' => $g2);

is($in->prefix, '/admin/super', 'nested prefix');
is_deeply($in->guards, [ $g1, $g2 ], 'the chain is outer-to-inner');
is_deeply($s->guards, [ $g1 ], 'and the outer scope is untouched');

@calls = ();
$in->get('/z' => 'T#z');
is($calls[0][2], '/admin/super/z', 'a nested route carries the full prefix');
is_deeply($calls[0][4], [ $g1, $g2 ], 'and both guards');

is_deeply($s->under('/plain')->guards, [ $g1 ],
    'under with no guard appends nothing');

{ package My::Scope; our @ISA = ('Punk::Router::Scope'); }
isa_ok(My::Scope->new(app => $app, prefix => '/s', guards => [])->under('/d'),
       'My::Scope', 'a nested subclass scope');

# ---- websocket and api ------------------------------------------------------

@calls = ();
is($s->websocket('/live' => 'T#l', { protocols => ['v1'] }), $s,
    'websocket chains');
is($calls[0][0], 'websocket',              'websocket recorded');
is($calls[0][1], '/admin/live',            'websocket takes the prefix');
is($calls[0][2], 'T#l',                    'websocket target');
is_deeply($calls[0][3], { protocols => ['v1'] }, 'websocket options');
is_deeply($calls[0][4], [ $g1 ],           'websocket takes the guards');

@calls = ();
is($s->api('spec.json', { stub => 1 }), 'THE-MOUNT',
    'api hands back the mount, not the scope');
is($calls[0][1], 'spec.json', 'api spec');
is($calls[0][3], $s,          'api passes the scope itself');

# ---- _route, and arity ------------------------------------------------------

@calls = ();
$s->_route('HEAD', '/h', 'T#h');
is($calls[0][1], 'HEAD', '_route takes an explicit method');

eval { $s->get('/only-one') };
like($@, qr/Usage.*::get\(self, path, target\)/,
    'a verb called wrong names itself');
eval { $s->_route('GET', '/a') };
like($@, qr/Usage.*_route/, 'and so does _route');

done_testing();
