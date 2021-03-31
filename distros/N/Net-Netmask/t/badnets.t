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
    # These do weird things that users almost certainly don't expect,
    # creating a potential security issue.  I.E. all of the below IP
    # addresses would be valid to inet_aton().
    {
        input => [ '1.131844', '32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '0192.0.1.2', '32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.00.1.2', '32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.0.01.2', '32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.0.1.02', '32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '0xC0.0x1.0x3.0x4', '32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '1.131844/32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '0192.0.1.2/32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.00.1.2/32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.0.01.2/32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.0.1.02/32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '0xC0.0x1.0x3.0x4/32' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '1.131844' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '0192.0.1.2' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.00.1.2' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '0192.0.01.2' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '192.0.1.02' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '0xC0.0x1.0x3.0x4' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10/8' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10.0/8' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10.0.0/8' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10', '8' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10.0', '8' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10.0.0', '8' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10', '8' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10.0' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '10.0.0' ],
        error => qr/^could not parse /,
        type  => 'ambiguous',
    },
    {
        input => [ '2001::/129' ],
        error => qr/^illegal number of bits/,
        type  => 'bad mask',
    },
);

foreach my $test (@tests) {
    my $input = $test->{input};
    my $err   = $test->{error};
    my $name  = ( join ', ', @{ $test->{input} } );
    my $type  = $test->{type};

    my $result = Net::Netmask->safe_new(@$input);
    is( $result, undef, "$name $type" );
    like( Net::Netmask->errstr, $err, "$name errstr mismatch" );

    warns { $result = Net::Netmask->new(@$input) };
    if ($result->{PROTOCOL} eq 'IPv4') {
        is( "$result", "0.0.0.0/0", "result is 0.0.0.0/0" );
    } else {
        is( "$result", "::/0", "result is 0.0.0.0/0" );
    }
}

# test whois numbers with space between dash (valid!)
ok( Net::Netmask->safe_new('209.157.64.0 - 209.157.95.255'), "whois with single space around dash" );
ok( Net::Netmask->safe_new('209.157.64.0   -   209.157.95.255'),
    "whois with mulitple spaces around dash" );

done_testing;

