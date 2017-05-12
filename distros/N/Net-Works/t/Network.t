use strict;
use warnings;

use Test::More 0.88;

use Math::BigInt ();
use Math::Int128 qw(uint128);
use Net::Works::Address;
use Net::Works::Network;

{
    my $net = Net::Works::Network->new_from_string( string => '1.1.1.0/28' );

    is(
        $net->as_string(),
        '1.1.1.0/28',
        'as_string returns value passed to the constructor'
    );

    is(
        $net->prefix_length(),
        28,
        'prefix_length is 28'
    );

    my $first_ip = $net->first();
    isa_ok(
        $first_ip,
        'Net::Works::Address',
        'return value of ->first'
    );

    is(
        $first_ip->as_string(),
        '1.1.1.0',
        '->first returns the correct IP address'
    );

    my $last_ip = $net->last();
    isa_ok(
        $last_ip,
        'Net::Works::Address',
        'return value of ->last'
    );

    is(
        $last_ip->as_string(),
        '1.1.1.15',
        '->last returns the correct IP address'
    );

    _test_iterator(
        $net,
        16,
        [ map { "1.1.1.$_" } 0 .. 15 ],
    );

    is(
        "$net",
        '1.1.1.0/28',
        'stringification of network object works'
    );

    my $greater
        = Net::Works::Network->new_from_string( string => '2.0.0.0/24' );

    cmp_ok(
        $net, '<', $greater,
        'numeric overloading (<) on network objects works'
    );

    cmp_ok(
        $greater, '>', $net,
        'numeric overloading (>) on network objects works'
    );

    my $same_net
        = Net::Works::Network->new_from_string( string => '1.1.1.0/28' );

    cmp_ok(
        $net, '==', $same_net,
        'numeric overloading (==) on network objects works'
    );

    is(
        $net <=> $same_net,
        0,
        'comparison overloading (==) on network objects works'
    );

    my $greater_prefix
        = Net::Works::Network->new_from_string( string => '1.1.1.0/29' );

    cmp_ok(
        $net, '<', $greater_prefix,
        'numeric overloading (<) on network objects works (based on prefix length)'
    );

    cmp_ok(
        $greater_prefix, '>', $net,
        'numeric overloading (>) on network objects works (based on prefix length)'
    );
}

{
    my @networks
        = map { Net::Works::Network->new_from_string( string => $_ ) }
        qw(
        ::123.0.0.4/128
        2003::/96
        ::1.2.3.0/124
        abcd::1000/116
        ::255.255.0.0/112
        ::127.0.98.0/124
        ::127.0.98.0/120
    );

    my @sorted = qw(
        ::1.2.3.0/124
        ::123.0.0.4/128
        ::127.0.98.0/120
        ::127.0.98.0/124
        ::255.255.0.0/112
        2003::/96
        abcd::1000/116
    );

    is_deeply(
        [ map { $_->as_string() } sort { $a <=> $b } @networks ],
        \@sorted,
        'network objects sort numerically'
    );

    is_deeply(
        [ map { $_->as_string() } sort { $a cmp $b } @networks ],
        \@sorted,
        'network objects sort alphabetically'
    );
}

{
    my $net
        = Net::Works::Network->new_from_string( string => 'ffff::1200/120' );

    is(
        $net->as_string(),
        'ffff::1200/120',
        'as_string returns value passed to the constructor'
    );

    is(
        $net->prefix_length(),
        120,
        'prefix_length is 120',
    );

    my $first_ip = $net->first();
    isa_ok(
        $first_ip,
        'Net::Works::Address',
        'return value of ->first'
    );

    is(
        $first_ip->as_string(),
        'ffff::1200',
        '->first returns the correct IP address'
    );

    my $last_ip = $net->last();
    isa_ok(
        $last_ip,
        'Net::Works::Address',
        'return value of ->last'
    );

    is(
        $last_ip->as_string(),
        'ffff::12ff',
        '->last returns the correct IP address'
    );

    _test_iterator(
        $net,
        256,
        [ map { sprintf( 'ffff::12%02x', $_ ) } 0 .. 255 ],
    );
}

{
    my $net = Net::Works::Network->new_from_string( string => '1.1.1.1/32' );

    _test_iterator(
        $net,
        1,
        ['1.1.1.1'],
    );
}

{
    my $net = Net::Works::Network->new_from_string( string => '1.1.1.0/31' );

    _test_iterator(
        $net,
        2,
        [ '1.1.1.0', '1.1.1.1' ],
    );
}

{
    my $net = Net::Works::Network->new_from_string( string => '1.1.1.4/30' );

    _test_iterator(
        $net,
        4,
        [ '1.1.1.4', '1.1.1.5', '1.1.1.6', '1.1.1.7' ],
    );
}

{
    my %tests = (
        ( map { '100.99.98.0/' . $_ => 23 } 23 .. 32 ),
        ( map { '100.99.16.0/' . $_ => 20 } 20 .. 32 ),
        ( map { '1.1.1.0/' . $_     => 24 } 24 .. 32 ),
        ( map { 'ffff::/' . $_      => 16 } 16 .. 128 ),
        ( map { 'ffff:ff00::/' . $_ => 24 } 24 .. 128 ),
    );

    for my $subnet ( sort keys %tests ) {
        my $net = Net::Works::Network->new_from_string( string => $subnet );

        is(
            $net->max_prefix_length(),
            $tests{$subnet},
            "max_prefix_length for $subnet is $tests{$subnet}"
        );
    }
}

{
    my %contains = (
        '1.1.1.0/24' => {
            true => [
                qw( 1.1.1.0 1.1.1.1 1.1.1.254 1.1.1.254
                    1.1.1.0/24 1.1.1.0/26 1.1.1.255/32 )
            ],
            false => [
                qw( 1.1.2.0 1.1.0.255 240.1.2.3
                    1.1.0.0/16 1.1.0.0/24 11.12.13.14/32 )
            ],
        },
        '97.0.0.0/8' => {
            true => [
                qw( 97.0.0.0 97.1.2.3 97.200.201.203 97.255.255.254 97.255.255.255
                    97.9.0.0/24 97.55.0.0/16 97.0.0.0/8 97.255.255.255/32 )
            ],
            false => [
                qw( 96.255.255.255 98.0.0.0 1.1.1.32 240.1.2.3
                    96.0.0.0/4 98.0.0.0/8 11.12.13.14/32 )
            ],
        },
        '1000::/8' => {
            true => [
                qw( 1000:: 1000::1 10bc:def9:1234::0
                    10ff:ffff:ffff:ffff:ffff:ffff:ffff:fffe
                    10ff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
                    1000::/8 1000::/16 1034::1/128 10ff::/124
                    10ff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128 )
            ],
            false => [
                qw( 0fff:: 0fff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
                    f::f 1100::
                    1000::/4 2000::/120 ffff::/128 )
            ],
        },
    );

    for my $n ( sort keys %contains ) {
        my $network = Net::Works::Network->new_from_string( string => $n );

        for my $string ( @{ $contains{$n}{true} } ) {
            my $object = _objectify_string($string);
            ok(
                $network->contains($object),
                $network->as_string() . ' contains ' . $object->as_string()
            );
        }

        for my $string ( @{ $contains{$n}{false} } ) {
            my $object = _objectify_string($string);
            ok(
                !$network->contains($object),
                $network->as_string()
                    . ' does not contain '
                    . $object->as_string()
            );
        }
    }
}

{
    my @splits = (
        [ '1.1.1.0/24'   => [ '1.1.1.0/25',   '1.1.1.128/25' ] ],
        [ '1.1.1.128/25' => [ '1.1.1.128/26', '1.1.1.192/26' ] ],
        [ '1.1.1.192/26' => [ '1.1.1.192/27', '1.1.1.224/27' ] ],
        [ '1.1.1.224/27' => [ '1.1.1.224/28', '1.1.1.240/28' ] ],
        [ '1.1.1.240/28' => [ '1.1.1.240/29', '1.1.1.248/29' ] ],
        [ '1.1.1.248/29' => [ '1.1.1.248/30', '1.1.1.252/30' ] ],
        [ '1.1.1.252/30' => [ '1.1.1.252/31', '1.1.1.254/31' ] ],
        [ '1.1.1.254/31' => [ '1.1.1.254/32', '1.1.1.255/32' ] ],
        [ '9000::/8'     => [ '9000::/9',     '9080::/9' ] ],
        [ '9080::/9'     => [ '9080::/10',    '90c0::/10' ] ],
        [ '90c0::/10'    => [ '90c0::/11',    '90e0::/11' ] ],
        [ '90e0::/11'    => [ '90e0::/12',    '90f0::/12' ] ],
        [ '90f0::/12'    => [ '90f0::/13',    '90f8::/13' ] ],
        [ '90f8::/13'    => [ '90f8::/14',    '90fc::/14' ] ],
        [ '90fc::/14'    => [ '90fc::/15',    '90fe::/15' ] ],
        [ '90fe::/15'    => [ '90fe::/16',    '90ff::/16' ] ],
    );

    for my $pair (@splits) {
        my $original
            = Net::Works::Network->new_from_string( string => $pair->[0] );
        my @halves = $original->split();

        is_deeply(
            [ map { $_->as_string() } $original->split() ],
            $pair->[1],
            "$pair->[0] splits into $pair->[1][0] and $pair->[1][1]"
        );
    }

    is_deeply(
        [
            Net::Works::Network->new_from_string( string => '1.1.1.1/32' )
                ->split()
        ],
        [],
        'split() returns an empty list for single address IPv4 network'
    );

    is_deeply(
        [
            Net::Works::Network->new_from_string(
                string => '9999::abcd/128'
            )->split()
        ],
        [],
        'split() returns an empty list for single address IPv6 network'
    );
}

{
    my $net = Net::Works::Network->new_from_string( string => '::/0' );

    is( $net->as_string(), '::0/0', 'got subnet passed to constructor' );
    is(
        $net->first()->as_string(), '::0',
        'first address in network is ::0'
    );
}

for my $two ( uint128(2), Math::BigInt->new(2) ) {
    subtest 'using ' . ref($two) . ' integer' => sub {

        {
            my $int = $two * 0;
            my $net = Net::Works::Network->new_from_integer(
                integer       => $int,
                prefix_length => 32,
                version       => 4,
            );

            is(
                $net->as_string(), '0.0.0.0/32',
                'a network created via new_from_integer with version => 4 stringifies correctly'
            );
        }

        my $net = Net::Works::Network->new_from_integer(
            integer       => ( $two**32 ),
            prefix_length => 96,
        );

        is(
            $net->as_string(), '::1:0:0/96',
            'as_string for network created via new_from_integer with 2**32'
        );

        $net = Net::Works::Network->new_from_integer(
            integer       => ( $two**64 ),
            prefix_length => 96,
        );

        is(
            $net->as_string(), '0:0:0:1::/96',
            'as_string for network created via new_from_integer with 2**64'
        );

        $net = Net::Works::Network->new_from_integer(
            integer       => ( $two**96 ),
            prefix_length => 96,
        );

        is(
            $net->as_string(), '0:1::/96',
            'as_string for network created via new_from_integer with 2**96'
        );
    };
}

{
    my $net = Net::Works::Network->new_from_string( string => '128.0.0.0/1' );

    is(
        $net->last()->as_string(),
        '255.255.255.255',
        'last address for 128.0.0.0/1 is 255.255.255.255'
    );

    $net = Net::Works::Network->new_from_string( string => '0.0.0.0/0' );

    is(
        $net->last()->as_string(),
        '255.255.255.255',
        'last address for 0.0.0.0/0 is 255.255.255.255'
    );
}

{
    my $net = Net::Works::Network->new_from_string( string => '8000::/1' );

    is(
        $net->last()->as_string(),
        ( join ':', ('ffff') x 8 ),
        q{last address for 8000:/1 is all ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff}
    );

    $net = Net::Works::Network->new_from_string( string => '::0/0' );

    is(
        $net->last()->as_string(),
        ( join ':', ('ffff') x 8 ),
        q{last address for ::0/0 is all ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff}
    );
}

{
    my $from_string
        = Net::Works::Network->new_from_string( string => '::0/128' );
    is(
        $from_string->as_string(),
        '::0/128',
        q{net from string '::0/128' stringifies to '::0/128'}
    );

    my $from_integer = Net::Works::Network->new_from_integer(
        integer       => 0,
        prefix_length => 128,
        version       => 6,
    );
    is(
        $from_integer->as_string(),
        '::0/128',
        q{net from integer 0 (prefix length 128) stringifies to '::0/128'}
    );
}

{
    my @single = qw(
        0.0.0.0/32
        1.2.3.4/32
        255.255.255.255/32
        ::0/128
        ::a/128
        1234:5678:9abc:def0:1234:5678:9abc:def0/128
    );

    for my $s (@single) {
        ok(
            Net::Works::Network->new_from_string( string => $s )
                ->is_single_address,
            "$s is a single address network"
        );
    }

    my @multi = qw(
        0.0.0.0/31
        1.2.3.4/31
        63.255.255.255/2
        ::0/127
        ::a/1
        1234:5678:9abc:def0:1234::/78
    );

    for my $m (@multi) {
        ok(
            !Net::Works::Network->new_from_string( string => $m )
                ->is_single_address,
            "$m is not a single address network"
        );
    }
}

sub _test_iterator {
    my $net              = shift;
    my $expect_count     = shift;
    my $expect_addresses = shift;

    my $iter = $net->iterator();

    my @addresses;
    while ( my $address = $iter->() ) {
        push @addresses, $address;
    }

    is(
        scalar @addresses,
        $expect_count,
        "iterator returned $expect_count addresses"
    );

    is_deeply(
        [ map { $_->as_string() } @addresses ],
        $expect_addresses,
        "iterator returned $expect_addresses->[0] - $expect_addresses->[-1]"
    );
}

sub _objectify_string {
    my $string = shift;

    return $string =~ m{/}
        ? Net::Works::Network->new_from_string( string => $string )
        : Net::Works::Address->new_from_string( string => $string );
}

done_testing();
