#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Client;

# Client-side validation fails BEFORE any I/O - no server is running, so a
# request that reached the wire would surface as a transport error, not a
# croak. Also construction rules and the AUTOLOAD sugar guards.

plan skip_all => 'Fetch not installed'
    unless eval { require Fetch; 1 };

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

# ---- construction ------------------------------------------------------------
{
    my $err;
    eval { Open::API::Client->new(base_url => 'http://x') } or $err = $@;
    like($err, qr/give 'api' or 'spec'/, 'api or spec required');

    undef $err;
    eval { Open::API::Client->new(api => $api) } or $err = $@;
    like($err, qr/'base_url' is required/, 'base_url required');

    undef $err;
    eval { Open::API::Client->new(api => {}, base_url => 'x') } or $err = $@;
    like($err, qr/must be an Open::API/, 'api type checked');
}

my $client = Open::API::Client->new(
    api      => $api,
    base_url => 'http://127.0.0.1:1',    # nothing listening
);
isa_ok($client, 'Open::API::Client');
is($client->api, $api, 'api accessor');

# ---- failures happen before I/O -----------------------------------------------
{
    my $err;
    eval { $client->call('nope') } or $err = $@;
    like($err, qr/unknown operationId 'nope'/, 'unknown op croaks');

    undef $err;
    eval { $client->call('getPet') } or $err = $@;
    like($err, qr/missing required path parameter 'petId'/,
        'missing required path param croaks');

    undef $err;
    eval { $client->call('getPet', petId => 'abc') } or $err = $@;
    like($err, qr/invalid path parameter 'petId'/, 'invalid param croaks');

    undef $err;
    eval { $client->call('createPet') } or $err = $@;
    like($err, qr/missing required body/, 'missing required body croaks');

    undef $err;
    eval { $client->call('createPet', body => { tag => 'x' }) } or $err = $@;
    like($err, qr/invalid body parameter/, 'invalid body croaks');

    undef $err;
    eval { $client->call('deletePet', petId => 1) } or $err = $@;
    like($err, qr/missing required cookie parameter 'session'/,
        'missing required cookie croaks');
}

# ---- valid input reaches the wire (transport failure, not croak) ----------------
{
    my $res = $client->call('getPet', petId => 5)->get;
    is($res->{status}, 0, 'transport failure resolves with status 0');
    ok($res->{error}, 'and carries an error message');
}

# ---- AUTOLOAD sugar ----------------------------------------------------------------
{
    my $err;
    eval { $client->definitelyNotAnOp } or $err = $@;
    like($err, qr/no such method or operation 'definitelyNotAnOp'/,
        'typo method croaks');

    ok($client->can('getPet'), 'can() true for an operation');
    ok(!$client->can('definitelyNotAnOp'), 'can() false for a typo');

    my $res = $client->getPet(petId => 7)->get;
    is($res->{status}, 0, 'sugar delegates to call (transport failure here)');
}

done_testing();
