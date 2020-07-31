#!perl -T

use Test::More;
use List::Util qw(shuffle);

use strict;
use warnings;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

my $outer     = Net::IPAM::Block->new("192.168.2.0/24");
my @inner_str = qw(
  192.168.2.0/26
  192.168.2.240-192.168.2.244
  192.168.2.240-192.168.2.249
);

my @expected_str = qw(
  192.168.2.64/26
  192.168.2.128/26
  192.168.2.192/27
  192.168.2.224/28
  192.168.2.250/31
  192.168.2.252/30
);

my @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

my @free = $outer->find_free_cidrs( shuffle @inner );

my @free_str = map { $_->to_string } @free;
is_deeply( \@free_str, \@expected_str, 'IPv4 find_free_cidrs' );

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
  192.168.1.1/32
  192.168.1.2/31
  192.168.1.4/30
  192.168.1.8/29
  192.168.1.16/32
  192.168.1.178/31
  192.168.1.180/30
  192.168.1.184/29
  192.168.1.192/26
  192.168.2.64/26
  192.168.2.128/26
  192.168.2.192/27
  192.168.2.224/28
  192.168.2.250/31
  192.168.2.252/30
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

@free = $outer->find_free_cidrs( shuffle @inner );

@free_str = map { $_->to_string } @free;
is_deeply( \@free_str, \@expected_str, 'IPv4 find_free_cidrs' );

###############

$outer     = Net::IPAM::Block->new("2001:db8::/32");
@inner_str = qw(
  2001:db8:3100::/40
);

@expected_str = qw(
  2001:db8::/35
  2001:db8:2000::/36
  2001:db8:3000::/40
  2001:db8:3200::/39
  2001:db8:3400::/38
  2001:db8:3800::/37
  2001:db8:4000::/34
  2001:db8:8000::/33
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

@free = $outer->find_free_cidrs( shuffle @inner );

@free_str = map { $_->to_string } @free;
is_deeply( \@free_str, \@expected_str, 'IPv6 find_free_cidrs' );

###############

$outer     = Net::IPAM::Block->new("2001:db8::/32");
@inner_str = qw(
  fe80::/10
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

@free = $outer->find_free_cidrs();
is_deeply( \@free, [$outer], 'find_free_cidrs with missing @inner returns $outer' );

$outer = Net::IPAM::Block->new("2001:db8::/32");
@inner = ( Net::IPAM::Block->new("2001:db8::/32") );

is_deeply( [ $outer->find_free_cidrs(@inner) ], [], 'outer equal inner' );
is_deeply( scalar $outer->find_free_cidrs(@inner), [], 'outer equal inner' );

$outer = Net::IPAM::Block->new("2001:db8::/32");
@inner = ( Net::IPAM::Block->new("::/0") );
is_deeply( [ $outer->find_free_cidrs(@inner) ], [], 'v6: inner contains outer' );

$outer = Net::IPAM::Block->new("127.0.0.1/8");
@inner = ( Net::IPAM::Block->new("0.0.0.0/0") );
is_deeply( [ $outer->find_free_cidrs(@inner) ], [], 'v4: inner contains outer' );

done_testing();
