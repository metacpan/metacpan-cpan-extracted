#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Config ();

# ABI-skew guard: when JSON::Schema::Fast's _abi_ptr is unavailable or wrong,
# Open::API must croak at load with an upgrade message - never crash. We fake
# JSON::Schema::Fast in a subprocess (pre-seeding %INC so the BOOT-time
# require is a no-op and our stub _abi_ptr wins) and check the failure mode.

my @inc = map { "-I$_" } @INC;

# _abi_ptr returns 0 (no table)
{
    my $out = do {
        local $ENV{PERL5LIB};
        my $code = 'BEGIN { $INC{"JSON/Schema/Fast.pm"} = 1; '
                 . 'no warnings; *JSON::Schema::Fast::_abi_ptr = sub { 0 } } '
                 . 'require Open::API; print "LOADED\n"';
        qx{"$^X" @inc -e '$code' 2>&1};
    };
    unlike($out, qr/LOADED/, 'load fails when the ABI is unavailable');
    like($out, qr/requires JSON::Schema::Fast built with its C ABI/,
        'croak carries the upgrade message');
    unlike($out, qr/Segmentation|Bus error|core dumped/i, 'no crash');
}

# _abi_ptr croaks outright
{
    my $out = do {
        my $code = 'BEGIN { $INC{"JSON/Schema/Fast.pm"} = 1; '
                 . 'no warnings; *JSON::Schema::Fast::_abi_ptr = sub { die "nope" } } '
                 . 'require Open::API; print "LOADED\n"';
        qx{"$^X" @inc -e '$code' 2>&1};
    };
    unlike($out, qr/LOADED/, 'load fails when _abi_ptr dies');
    like($out, qr/requires JSON::Schema::Fast/, 'same clean croak');
}

done_testing();
