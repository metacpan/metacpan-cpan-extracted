#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

can_ok( 'Net::IPAM::Block', 'new' );

my $tt = [
  [ qw(1.2.3.4-1.2.3.4),                                [qw(1.2.3.4/32)] ],
  [ qw(1.2.3.0-1.2.3.4),                                [qw(1.2.3.0/30 1.2.3.4/32)] ],
  [ qw(1.2.3.3-1.2.3.5),                                [qw(1.2.3.3/32 1.2.3.4/31)] ],
  [ qw(255.255.255.253-255.255.255.255),                [qw(255.255.255.253/32 255.255.255.254/31)] ],
  [ qw(fe80::1-fe80::1),                                [qw(fe80::1/128)] ],
  [ qw(fffd::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff), [qw(fffd::/16 fffe::/15)] ],
];

my $b;
my @cidrlist;
foreach my $t (@$tt) {
  $b = Net::IPAM::Block->new( $t->[0] );
  for my $c ( $b->to_cidrs ) {
    push @cidrlist, $c->to_string;
  }

  is_deeply( \@cidrlist, $t->[1], "cidrlist for " . $b->to_string . "=> '@cidrlist'" );
  undef @cidrlist;
}

my $clist = Net::IPAM::Block->new('1.2.3.3-1.2.3.5')->to_cidrs;
my $cidr1 = Net::IPAM::Block->new('1.2.3.3/32');
my $cidr2 = Net::IPAM::Block->new('1.2.3.4/31');
is_deeply( $clist, [ $cidr1, $cidr2 ], 'wantarray' );

$clist = Net::IPAM::Block->new('::/0')->to_cidrs;
is_deeply( $clist, [ Net::IPAM::Block->new('::/0') ], 'return the cidr' );

$clist = Net::IPAM::Block->new('::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe')->to_cidrs;
is( scalar @$clist, 128, '"::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe" -> long cidr list' );

done_testing();
