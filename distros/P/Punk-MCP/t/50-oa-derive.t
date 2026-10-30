#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPOA;

my $t = oa_app(q{openapi => '*'});
my %tool = map { $_->{name} => $_ } @{ oa_list($t) };

is_deeply([sort keys %tool],
    [qw(add_book adminop deletebook dup_x dup_x_2 get_weird-name getbook listbooks replacebook)],
    "every operation a tool: lowercased, sanitised, _N on a collision, x-mcp's name, x-mcp: false left out");
ok(!exists $tool{hiddenop}, 'x-mcp: false leaves an operation out');

is($tool{listbooks}{description}, "List books\n\nEvery book, filtered.",
    'the description is the summary, then the description');
is($tool{add_book}{title}, 'Add a book', "x-mcp's title");
is_deeply([sort keys %{ $tool{listbooks}{inputSchema}{properties} }], [qw(X-Trace limit q tags)],
    'the inputSchema is the parameters, flat');
ok($tool{add_book}{inputSchema}{properties}{body}, 'and the body under body');
ok($tool{add_book}{inputSchema}{'$defs'}, 'with $defs');

my %ann = map { $_ => $tool{$_}{annotations} } keys %tool;
ok($ann{listbooks}{readOnlyHint} && !$ann{listbooks}{destructiveHint}, 'GET is read-only');
ok($ann{deletebook}{destructiveHint} && $ann{deletebook}{idempotentHint}, 'DELETE is destructive and idempotent');
ok($ann{replacebook}{idempotentHint} && !$ann{replacebook}{readOnlyHint}, 'PUT is idempotent');
ok(!$ann{add_book}{idempotentHint} && !$ann{add_book}{readOnlyHint}, 'POST is neither');
ok($ann{listbooks}{openWorldHint}, 'and every one is open world');
ok(JSON::PP::is_bool($ann{listbooks}{readOnlyHint}), 'as JSON booleans');

# ---- naming the mount -------------------------------------------------------------

for my $case ([q{openapi => $PMCPOA::MOUNT}, 'a mount object'],
              [q{openapi => $PMCPOA::SPEC}, 'the spec it was mounted from'],
              [q{openapi => ['*']}, "'*' in a list"]) {
    my ($opts, $name) = @$case;
    is(scalar @{ oa_list(oa_app($opts)) }, 9, "$name names it");
}
is(scalar @{ oa_list(oa_app(q{openapi => '/v1'}, under => '/v1')) }, 9, 'and so does its prefix');

eval { oa_app(q{openapi => 'nope.json'}) };
like($@, qr/openapi 'nope.json' names no api mount/, 'a name that matches no mount croaks');

# ---- ops ---------------------------------------------------------------------------

my @names = map { $_->{name} } @{ oa_list(oa_app(q{openapi => '*', ops => ['listBooks', 'getBook']})) };
is_deeply([sort @names], [qw(getbook listbooks)], 'ops is an allow-list of operationIds');
eval { oa_app(q{openapi => '*', ops => ['listBooks', 'noSuchOp']}) };
like($@, qr/ops names 'noSuchOp', which no named mount has/, 'an op that does not exist croaks');

# ---- alongside the DSL ------------------------------------------------------------------

@names = map { $_->{name} } @{ oa_list(oa_app(q{openapi => '*'}, decl => q{mcp tool => mine => 'T#a';})) };
ok((grep { $_ eq 'mine' } @names) && (grep { $_ eq 'listbooks' } @names),
    'DSL tools and OpenAPI tools share one list');
is_deeply(\@names, [sort @names], 'sorted together');

eval { oa_app(q{openapi => '*'}, decl => q{mcp tool => listbooks => 'T#a';}) };
like($@, qr/operation 'listBooks' becomes the tool 'listbooks', which the mcp keyword already declares/,
    'a collision with a DSL tool croaks rather than numbering round it');
eval { oa_app(q{openapi => '*'}, decl => q{mcp tool => add_book => 'T#a';}) };
like($@, qr/x-mcp name 'add_book' on operation 'createBook' is already a tool/,
    "and so does one with x-mcp's name");

done_testing;
