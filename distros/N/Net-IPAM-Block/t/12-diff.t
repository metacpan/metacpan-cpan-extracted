#!perl -T

use 5.10.0;
use strict;
use warnings;

use Test::More;
use List::Util qw(shuffle);

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

my $outer     = Net::IPAM::Block->new("192.168.2.0/24");
my @inner_str = qw(
  192.168.2.0/26
  192.168.2.240-192.168.2.244
  192.168.2.240-192.168.2.244
  192.168.2.240-192.168.2.244
  192.168.2.240-192.168.2.249
);

my @expected_str = qw(
  192.168.2.64-192.168.2.239
  192.168.2.250-192.168.2.255
);

my @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

my @diff = $outer->diff( shuffle @inner );

my @diff_str = map { $_->to_string } @diff;
is_deeply( \@diff_str, \@expected_str, 'IPv4 diff' );

###############
#
$outer     = Net::IPAM::Block->new("::/0");
@inner_str = qw(
        0000::/8
        0100::/8
        0200::/7
        0400::/6
        0800::/5
        1000::/4
        2000::/3
        4000::/3
        8000::/3
        a000::/3
        c000::/3
        e000::/4
        f000::/5
        f800::/6
        fe00::/9
        fe80::/10
        fec0::/10
        ff00::/8
);

@expected_str = qw(
  6000::/3
  fc00::/7
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

@diff = $outer->diff( shuffle @inner );

@diff_str = map { $_->to_string } @diff;
is_deeply( \@diff_str, \@expected_str, 'IANAv6 blocks' );

###############
#
$outer     = Net::IPAM::Block->new("192.168.1.1-192.168.2.255");
@inner_str = qw(
  192.168.1.17-192.168.1.99
  192.168.1.56-192.168.1.177
  192.168.2.4/26
  192.168.2.240-192.168.2.249
);

@expected_str = qw(
  192.168.1.1-192.168.1.16
  192.168.1.178-192.168.1.255
  192.168.2.64-192.168.2.239
  192.168.2.250-192.168.2.255
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

@diff = $outer->diff( shuffle @inner );

@diff_str = map { $_->to_string } @diff;
is_deeply( \@diff_str, \@expected_str, 'IPv4 diff' );

###############

$outer     = Net::IPAM::Block->new("2001:db8::/32");
@inner_str = qw(
  2001:db8:3100::/40
);

@expected_str = qw(
  2001:db8::-2001:db8:30ff:ffff:ffff:ffff:ffff:ffff
  2001:db8:3200::-2001:db8:ffff:ffff:ffff:ffff:ffff:ffff
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

@diff = $outer->diff( shuffle @inner );

@diff_str = map { $_->to_string } @diff;
is_deeply( \@diff_str, \@expected_str, 'IPv6 diff' );

###############

$outer     = Net::IPAM::Block->new("2001:db8::/32");
@inner_str = qw(
  fe80::/10
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

@diff = $outer->diff();
is_deeply( \@diff, [$outer], 'diff with missing @inner returns $outer' );

$outer = Net::IPAM::Block->new("2001:db8::/32");
@inner = ( Net::IPAM::Block->new("2001:db8::/32") );

is_deeply( [ $outer->diff(@inner) ], [], 'outer equal inner' );
is_deeply( scalar $outer->diff(@inner), [], 'outer equal inner' );

$outer = Net::IPAM::Block->new("2001:db8::/32");
@inner = ( Net::IPAM::Block->new("::/0") );
is_deeply( [ $outer->diff(@inner) ], [], 'v6: inner contains outer' );

$outer = Net::IPAM::Block->new("127.0.0.1/8");
@inner = ( Net::IPAM::Block->new("0.0.0.0/0") );
is_deeply( [ $outer->diff(@inner) ], [], 'v4: inner contains outer' );

$outer = Net::IPAM::Block->new("192.168.0.5-192.168.0.200");
@inner = ( Net::IPAM::Block->new("192.168.0.0-192.168.0.199") );
is_deeply( [ $outer->diff(@inner)], [ Net::IPAM::Block->new('192.168.0.200')], 'v4: left overlap' );

$outer = Net::IPAM::Block->new("192.168.0.5-192.168.0.200");
@inner = ( Net::IPAM::Block->new("192.168.0.6-192.168.0.255") );
is_deeply( [ $outer->diff(@inner)], [ Net::IPAM::Block->new('192.168.0.5')], 'v4: right overlap' );

$outer = Net::IPAM::Block->new("2001:db8::5-2001:db8::ffff");
@inner = ( Net::IPAM::Block->new("2001:db8::0-2001:db8::fffe") );
is_deeply( [ $outer->diff(@inner)], [ Net::IPAM::Block->new('2001:db8::ffff')], 'v6: left overlap' );

$outer = Net::IPAM::Block->new("2001:db8::5-2001:db8::ffff");
@inner = ( Net::IPAM::Block->new("2001:db8::6-2001:db8::1:ffff") );
is_deeply( [ $outer->diff(@inner)], [ Net::IPAM::Block->new('2001:db8::5')], 'v6: right overlap' );

done_testing();
