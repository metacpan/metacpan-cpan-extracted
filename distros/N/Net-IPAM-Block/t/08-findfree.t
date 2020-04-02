#!perl -T

use Test::More;
use List::Util qw(shuffle);

use strict;
use warnings;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

my $outer = Net::IPAM::Block->new("192.168.2.0/24");
my @inner_str = qw(
  	192.168.2.0/26
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

my @free = $outer->find_free_cidrs(shuffle @inner);

my @free_str = map { $_->to_string } @free;
is_deeply(\@free_str, \@expected_str, 'IPv4 find_free_cidrs');

###############

$outer = Net::IPAM::Block->new("2001:db8::/32");
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

@free = $outer->find_free_cidrs(shuffle @inner);

@free_str = map { $_->to_string } @free;
is_deeply(\@free_str, \@expected_str, 'IPv6 find_free_cidrs');

###############

$outer = Net::IPAM::Block->new("2001:db8::/32");
@inner_str = qw(
  	fe80::/10
);

undef @inner;
foreach my $item (@inner_str) {
  push @inner, Net::IPAM::Block->new($item);
}

eval { $outer->find_free_cidrs() };
like( $@, qr/missing inner blocks/i, 'find_free_cidrs croaks on missing inner' );

eval { $outer->find_free_cidrs(@inner) };
like( $@, qr/is no subset nor equal to outer block/i, 'find_free_cidrs croaks on wrong inner' );

$outer = Net::IPAM::Block->new("2001:db8::-2001:db9::");
eval { $outer->find_free_cidrs(@inner) };
like( $@, qr/outer .* CIDR/i, 'find_free_cidrs croaks on wrong outer' );

$outer = Net::IPAM::Block->new("2001:db8::/32");
@inner = ( Net::IPAM::Block->new("2001:db8::/32") );

is_deeply([$outer->find_free_cidrs(@inner)], [], 'outer equal inner');
is_deeply(scalar $outer->find_free_cidrs(@inner), [], 'outer equal inner');

done_testing();
