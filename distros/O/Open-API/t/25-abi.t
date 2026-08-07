#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# The provider side of the shared C ABI (include/oa_abi.h): the versioned
# function-pointer table reached through Open::API::_abi_ptr, driven end to
# end in C by _abi_selftest, plus the EU::Depends provider config that lets a
# consumer (Punk) find the header without vendoring it.

# _abi_ptr returns the address of the process-wide table. It is an IV carrying
# a raw pointer, so it may legitimately be negative - Solaris x86-64 maps shared
# objects around 0xFFFFFC7F..., which sets the sign bit. INT2PTR round-trips the
# bits either way; what matters is that it is non-zero and stable, and
# _abi_selftest below is what proves the table actually works.
my $ptr = Open::API::_abi_ptr();
ok(defined $ptr && $ptr != 0, "_abi_ptr returns a table address ($ptr)");
is(Open::API::_abi_ptr(), $ptr, 'the table is static - same address');

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

# _abi_selftest resolves the table from that IV, checks abi_version, and drives
# api_of -> route -> op_id -> validate through the function pointers. Its
# result must match what the Perl-visible match/validate_request return - the
# ABI is the same behaviour with the Perl frames removed.

# ---- route: a match returns the operationId --------------------------------
{
    my ($op, $second, $third) = Open::API::_abi_selftest($api, 'GET', '/pets/1', undef);
    is($op, 'getPet', 'route through the table resolves the operationId');
    my ($mop) = $api->match('GET', '/pets/1');
    is($op, $mop, 'ABI route agrees with native match');
    is($second, undef, 'no allow list on a match');
    is($third,  undef, 'no params without a raw hash');
}

# ---- route: 405 hands back the Allow list ----------------------------------
{
    my ($op, $allow) = Open::API::_abi_selftest($api, 'PATCH', '/pets', undef);
    is($op, undef, '405: no operationId');
    is(ref $allow, 'ARRAY', '405: allow is an arrayref');
    is_deeply([ sort @$allow ], [ 'GET', 'POST' ], 'allow lists the methods');
    my (undef, $mallow) = $api->match('PATCH', '/pets');
    is_deeply([ sort @$allow ], [ sort @$mallow ],
        'ABI allow agrees with native match');
}

# ---- route: 404 is an empty result -----------------------------------------
{
    my ($op, $allow) = Open::API::_abi_selftest($api, 'GET', '/nope', undef);
    is($op,    undef, '404: no operationId');
    is($allow, undef, '404: no allow list');
    is_deeply([ $api->match('GET', '/nope') ], [], 'native match is a 404 too');
}

# ---- validate: success fills the typed params ------------------------------
{
    my ($op, $ok, $params) =
        Open::API::_abi_selftest($api, 'GET', '/pets/1',
            { path => { petId => 1 }, query => '', header => {} });
    is($op, 'getPet', 'validate path routed to getPet');
    is($ok, 1, 'validate through the table succeeds');
    is($params->{path}{petId}, 1, 'typed params carry the coerced petId');

    my ($nok, $nparams) = $api->validate_request('getPet',
        { path => { petId => 1 }, query => '', header => {} });
    is($ok, $nok, 'ABI validate agrees with native (ok)');
    is_deeply($params, $nparams, 'ABI validate agrees with native (params)');
}

# ---- validate: failure fills the errors, same shape ------------------------
{
    my ($op, $ok, $errs) =
        Open::API::_abi_selftest($api, 'GET', '/pets/abc',
            { path => { petId => 'abc' }, query => '', header => {} });
    is($op, 'getPet', 'bad request still routed');
    is($ok, 0, 'validate through the table fails on a bad path param');
    is($errs->[0]{in}, 'path', 'error carries the same in=path shape');
}

# ---- provider config: EU::Depends wrote Install::Files ----------------------
SKIP: {
    eval { require Open::API::Install::Files; 1 }
        or skip 'Install::Files not built (run make first)', 2;
    no warnings 'once';
    my $inc = $Open::API::Install::Files::inc;
    ok(defined $inc, 'Install::Files records an include config');
    my @deps = eval { Open::API::Install::Files->deps };
    ok(@deps > 0, 'Install::Files records the upstream ABI deps');
}

done_testing;
