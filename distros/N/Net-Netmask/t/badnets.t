#!/usr/bin/perl -w

use strict;

use Test2::V0;

use Net::Netmask;

my $debug = 0;

ok( Net::Netmask->debug($debug) == $debug, "unable to set debug" );

# test a variety of ip's with bytes greater than 255.
# all these tests should return undef

my @tests = (
    {
        input => ['209.256.68.22:255.255.224.0'],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => ['209.180.68.22:256.255.224.0'],
        error => qr/^illegal netmask: /,
        type  => 'bad mask byte',
    },
    {
        input => [ '209.157.300.22', '255.255.224.0' ],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => [ '300.157.70.33', '0xffffe000' ],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => ['209.500.70.33/19'],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => ['140.999.82'],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => ['899.174'],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => ['900'],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => ['209.157.300/19'],
        error => qr/^could not parse /,
        type  => 'bad net byte',
    },
    {
        input => ['209.300.64.0-209.157.95.255'],
        error => qr/^illegal dotted quad/,
        type  => 'bad net byte',
    },
    # test ranges that are a power-of-two big, but are not legal blocks
    {
        input => ['218.0.0.0 - 211.255.255.255'],
        error => qr/^could not find exact fit/,
        type  => 'inexact fit',
    },
    # test some more bad nets/masks
    {
        input => ['218.0.0.4 - 218.0.0.11'],
        error => qr/^could not find exact fit/,
        type  => 'inexact fit',
    },
    {
        input => ['10.10.10.10#256.0.0.0'],
        error => qr/^illegal hostmask:/,
        type  => 'bad mask byte',
    },
    {
        input => [ '209.157.200.22', '256.255.224.0' ],
        error => qr/^illegal netmask:/,
        type  => 'bad mask byte',
    },
    {
        input => [ '10.10.10.10', '0xF' ],
        error => qr/^illegal netmask:/,
        type  => 'bad mask',
    },
    {
        input => ['209.200.70.33/33'],
        error => qr/^illegal number of bits/,
        type  => 'bad mask',
    },
    {
        input => ['209.200.64.0-309.157.95.255'],
        error => qr/^illegal dotted quad/,
        type  => 'bad mask byte',
    },
    # completely invalid args
    {
        input => ['foo'],
        error => qr/^could not parse /,
        type  => 'bad net',
    },
    {
        input => [ '10.10.10.10', 'foo' ],
        error => qr/^could not parse /,
        type  => 'bad mask',
    },
    {
        input => [ '10.10.10', 'foo' ],
        error => qr/^could not parse /,
        type  => 'bad mask',
    },
    {
        input => [ '10.10', 'foo' ],
        error => qr/^could not parse /,
        type  => 'bad mask',
    },
    {
        input => [ '10', 'foo' ],
        error => qr/^could not parse /,
        type  => 'bad mask',
    },
    {
        input => [ '10.10.10.10', '0xYYY' ],
        error => qr/^could not parse /,
        type  => 'bad mask',
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

# test whois numbers with space between dash (valid!)
ok( Net::Netmask->new2('209.157.64.0 - 209.157.95.255'), "whois with single space around dash" );
ok( Net::Netmask->new2('209.157.64.0   -   209.157.95.255'),
    "whois with mulitple spaces around dash" );

done_testing;

