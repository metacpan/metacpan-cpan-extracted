#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# Phase 01 of plan_openapi_v2: a Swagger 2.0 document gets through the gate.
#
# Written for phase 01, when nothing was converted yet; the subtest below was
# flipped by phase 05 and says so. A 2.0 parameter
# carries its type inline, and until phase 05 turns that into a `schema` the
# compiler has nothing to validate against (oa_compile.h: a parameter without
# a schema compiles with no handle). The subtest that pins that hole is named,
# so that phase 05 FLIPS a named assertion instead of discovering the hole was
# never pinned.

my $doc = {
    swagger => '2.0',
    info    => { title => 'Pets', version => '1.0.0' },
    paths   => {
        '/pets' => { get => {
            operationId => 'listPets',
            parameters  => [ { name => 'limit', in => 'query', type => 'integer' } ],
            responses   => { 200 => { description => 'ok' } },
        } },
        '/pets/{petId}' => { get => {
            operationId => 'getPet',
            parameters  => [ { name => 'petId', in => 'path', required => \1,
                               type => 'integer' } ],
            responses   => { 200 => { description => 'ok' } },
        } },
        '/health' => { get => {
            operationId => 'health',
            responses   => { 200 => { description => 'ok' } },
        } },
    },
};

my $api = Open::API->new(spec => $doc);
isa_ok($api, 'Open::API', 'a 2.0 document of GET operations loads');
is($api->openapi_version, '2.0', 'openapi_version is the swagger string');

my @ids = sort map { $_->{operationId} } @{ $api->operations };
is_deeply(\@ids, [qw(getPet health listPets)], 'all three operations compiled');

# ---- routing works today: the compiler reads `paths` directly -----------------
{
    my ($id, $caps) = $api->match(GET => '/pets/42');
    is($id, 'getPet', 'a path with a capture routes');
    is_deeply($caps, { petId => 42 }, 'the capture is named');
    ($id) = $api->match(GET => '/pets');
    is($id, 'listPets', 'the literal path routes');
    ($id) = $api->match(GET => '/nowhere');
    ok(!defined $id, 'an unknown path does not route');
    ($id) = $api->match(POST => '/pets');
    ok(!defined $id, 'an undeclared method does not route');
}

# ---- the hole phase 01 pinned by name, closed by phase 05 -----------------------
#
# Until phase 05 a 2.0 parameter's inline type never became a schema and the
# compiler validated nothing; this subtest asserted that by name so the fix
# would FLIP a named test rather than find the hole was never pinned. Flipped
# 11 October 2026.
subtest 'parameters ARE validated: the inline type is a schema (phase 05)' => sub {
    my ($bad) = $api->validate_request(getPet => { path => { petId => 'x' } });
    ok(!$bad, 'a non-integer petId is refused');
    my ($good, $res) = $api->validate_request(getPet => { path => { petId => '42' } });
    ok($good, 'an integer petId is accepted');
    is($res->{path}{petId}, 42, '...and coerced');
    ($bad) = $api->validate_request(listPets => { query => { limit => 'many' } });
    ok(!$bad, 'a non-integer limit is refused');
    ($good) = $api->validate_request(listPets => { query => { limit => '10' } });
    ok($good, 'an integer limit is accepted');
};

# ---- the normalised document round-trips through new() --------------------------
{
    my $again = Open::API->new(spec => $api->spec);
    is_deeply($again->spec, $api->spec, 'new(spec => ->spec) yields the same document');
    is($again->openapi_version, '2.0', '...still declaring 2.0');
    ok(!exists $api->spec->{openapi}, 'no openapi key was invented');
}

# ---- the scopes rule reads 2.0 as 3.0 ----------------------------------------------
#
# "For other security scheme types, the array MUST be empty" is 2.0's sentence
# as well as 3.0's; 3.1 allows role names. The compiler's rule is keyed on the
# version, and had the version read stayed a poke at the `openapi` string, a
# 2.0 document would silently have taken 3.1's permissive reading. Pinned with
# apiKey, the one scheme type 2.0 and 3.x spell the same way (basic is phase
# 03's), and placed under `components` because phase 03 has not yet moved
# securityDefinitions: phase 03 rewrites this block to the 2.0 spelling.
{
    my %d = (%$doc,
             components => { securitySchemes => {
                 k => { type => 'apiKey', name => 'X-K', in => 'header' } } },
             security => [ { k => ['s1'] } ]);
    my $err;
    eval { Open::API->new(spec => \%d) } or $err = $@;
    like($err, qr/must be an empty list/, '2.0 reads the scopes rule as 3.0 does');

    delete $d{swagger};
    $d{openapi} = '3.1.0';
    ok(eval { Open::API->new(spec => \%d) }, '...while 3.1 allows role names')
        or diag($@);
}

done_testing;
