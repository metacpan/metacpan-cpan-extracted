#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::IP') || print "Bail out!\n"; }

can_ok( 'Net::IPAM::IP', 'new' );

my $ip;

$ip = Net::IPAM::IP->new('1.2.3.4');
is( $ip->expand, '001.002.003.004', 'uncached expand for 1.2.3.4' );
is( $ip->expand, '001.002.003.004', 'cached expand for 1.2.3.4' );

$ip = Net::IPAM::IP->new('::ffff:127.0.0.1');
is(
  $ip->reverse,
  '1.0.0.0.0.0.f.7.f.f.f.f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0',
  'uncached reverse for ::ffff:1.2.3.4'
);
is(
  $ip->reverse,
  '1.0.0.0.0.0.f.7.f.f.f.f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0',
  'cached reverse for ::ffff:1.2.3.4'
);

done_testing();
