#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# match(): captures, 404 vs 405 + Allow, method case handling.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

# ---- static match ------------------------------------------------------------
{
    my ($id, $caps) = $api->match(GET => '/pets');
    is($id, 'listPets', 'GET /pets matches listPets');
    is_deeply($caps, {}, 'no captures on a static path');
}

# ---- capture match -----------------------------------------------------------
{
    my ($id, $caps) = $api->match(GET => '/pets/42');
    is($id, 'getPet', 'GET /pets/42 matches getPet');
    is_deeply($caps, { petId => '42' }, 'petId captured raw');
}
{
    my ($id, $caps) = $api->match(DELETE => '/pets/9');
    is($id, 'deletePet', 'DELETE matches the delete op on the same path');
    is_deeply($caps, { petId => '9' }, 'capture for delete too');
}

# ---- method case -------------------------------------------------------------
{
    my ($id) = $api->match(get => '/pets');
    is($id, 'listPets', 'lowercase method matches');
    ($id) = $api->match(GeT => '/pets');
    is($id, 'listPets', 'mixed-case method matches');
}

# ---- 404 ----------------------------------------------------------------------
{
    my @r = $api->match(GET => '/nope');
    is(scalar @r, 0, 'unknown path returns empty (404)');
    @r = $api->match(GET => '/pets/1/extra');
    is(scalar @r, 0, 'segment-count mismatch is a 404');
}

# ---- 405 + Allow ----------------------------------------------------------------
{
    my ($id, $allow) = $api->match(PATCH => '/pets');
    ok(!defined $id, 'wrong method: opId undef');
    is_deeply([sort @$allow], ['GET', 'POST'], '405 Allow list for /pets');

    ($id, $allow) = $api->match(POST => '/pets/1');
    ok(!defined $id, 'wrong method on captured path');
    is_deeply([sort @$allow], ['DELETE', 'GET'], 'Allow for /pets/{petId}');
}

# ---- trailing slash and duplicate slashes --------------------------------------
{
    my ($id) = $api->match(GET => '/pets/');
    is($id, 'listPets', 'trailing slash still matches');
    ($id) = $api->match(GET => '//pets//42');
    is($id, 'getPet', 'duplicate slashes collapse');
}

# ---- a concrete path beats a template, every time --------------------------
#
# The operation table is built by walking the `paths` hash, and perl randomises
# hash order per process. Before the table was given an explicit order, a path
# that two templates both fit routed to whichever the hash happened to hand
# over first: `/t/fixed` picked the TEMPLATE roughly one run in five. A single
# check cannot see that, so this builds the document repeatedly - and each
# iteration re-walks the hash.
#
# Note match() returns a LIST. In scalar context it yields the CAPTURES, and
# `{id => 'fixed'}` reads exactly like a match on the literal when it is really
# the template capturing it.
{
    my $spec = {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => {
            '/t/{id}'  => { get => { operationId => 'by_id',
                parameters => [ { name => 'id', in => 'path', required => \1,
                                  schema => { type => 'string' } } ],
                responses  => { 200 => { description => 'ok' } } } },
            '/t/fixed' => { get => { operationId => 'fixed',
                responses  => { 200 => { description => 'ok' } } } },
            '/t/{id}/sub'  => { get => { operationId => 'sub_by_id',
                parameters => [ { name => 'id', in => 'path', required => \1,
                                  schema => { type => 'string' } } ],
                responses  => { 200 => { description => 'ok' } } } },
            '/t/fixed/sub' => { get => { operationId => 'sub_fixed',
                responses  => { 200 => { description => 'ok' } } } },
        },
    };

    my (%literal, %templated, %deep);
    for (1 .. 25) {
        my $api = Open::API->new(spec => $spec);
        my ($a) = $api->match(GET => '/t/fixed');
        my ($b) = $api->match(GET => '/t/other');
        my ($c) = $api->match(GET => '/t/fixed/sub');
        $literal  { defined $a ? $a : '(none)' }++;
        $templated{ defined $b ? $b : '(none)' }++;
        $deep     { defined $c ? $c : '(none)' }++;
    }

    is_deeply([ sort keys %literal ], ['fixed'],
              'a literal path always beats a template that also fits');
    is_deeply([ sort keys %templated ], ['by_id'],
              'and the template still matches what only it fits');
    is_deeply([ sort keys %deep ], ['sub_fixed'],
              'the literal wins on a deeper segment too');
}

done_testing();
