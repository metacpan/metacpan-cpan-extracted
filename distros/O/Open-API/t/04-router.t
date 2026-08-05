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

done_testing();
