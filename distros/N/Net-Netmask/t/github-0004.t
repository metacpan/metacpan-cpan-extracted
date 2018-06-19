#!/usr/bin/perl -w

use strict;

use utf8;
use Test2::V0;

use Net::Netmask;

my $debug = 0;

ok( Net::Netmask->debug($debug) == $debug, "unable to set debug" );

# test a variety of ip's with bytes greater than 255.
# all these tests should return undef

my @tests = (
    {
        input => ['١٠٠.١٠٠.١٠٠.١٠٠/32'],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
);

foreach my $test (@tests) {
    my $input = $test->{input};
    my $err   = $test->{error};
    my $name  = ( join ', ', @{ $test->{input} } );
    my $type  = $test->{type};

    my $result = Net::Netmask->new2(@$input);

    is( $result, undef, "$name $type" );
    like( Net::Netmask->errstr, $err, "$name errstr mismatch" );
}

done_testing;

