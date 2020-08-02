#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

can_ok( 'Net::IPAM::Block', 'new' );

my $cidrs = [
  qw(
    1.2.3.4-1.2.3.4
    fe80::1-fe80::1
    0.0.0.0
    255.255.255.255
    255.255.255.254-255.255.255.255
    10.11.12.13/8
    255.255.255.255/1
    255.255.255.255/2
    255.255.255.255/3
    255.255.255.255/4
    255.255.255.255/5
    255.255.255.255/6
    255.255.255.255/7
    ::
    ::ffff:0.0.0.0
    ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    FE80::/10
    10.0.0.0-10.0.0.31
    fe80::0-fe80::ffff
    ::ffff:1.2.3.0-::ffff:1.2.3.3
    )
];

my $ranges = [
  qw(
    255.255.255.253-255.255.255.255
    10.0.0.0-10.0.0.30
    fe80::0-fe80::fffe
    ::ffff:1.2.3.0-::ffff:1.2.3.2
    )
];

foreach my $tt (@$cidrs) {
  ok( Net::IPAM::Block->new($tt)->is_cidr, "is_cidr($tt)" );
}

foreach my $tt (@$ranges) {
  ok( !Net::IPAM::Block->new($tt)->is_cidr, "!is_cidr($tt)" );
}

done_testing();
