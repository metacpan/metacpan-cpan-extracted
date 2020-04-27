#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::IP') || print "Bail out!\n"; }
can_ok( 'Net::IPAM::IP', 'getname' );
can_ok( 'Net::IPAM::IP', 'getaddrs' );

my @ips = Net::IPAM::IP->getaddrs( 'dns.google.', sub { } );
SKIP: {
  skip 'no DNS resolution, maybe no network connection', 2 unless @ips;
  ok( @ips, 'getaddrs for dns.google.' );
  my $ip = shift @ips;
  is( $ip->getname, 'dns.google', "($ip)->getname() is dns.google" );
}

#ok( !Net::IPAM::IP->getaddrs( 'rab_baz.foo_v.', sub { } ),
ok( !Net::IPAM::IP->getaddrs( 'rab_baz.foo_v.', ),
	"undef for getaddrs('rab_baz.foo_v.')" );

# valid
foreach my $txt (qw/:: fE80::0:1 1.2.3.4 ::ffff:127.0.0.1 ::ff:0 caFe::/) {
  ok( Net::IPAM::IP->getaddrs($txt), "is valid ($txt)" );
}

# invalid
foreach my $txt (
  qw/010.0.0.1 10.000.0.1 : ::cafe::affe cafe::: cafe::1:: cafe::1: :cafe:: ::cafe::
  cafe::1:2:3:4:5:6:7:8 1:2:3:4:5:6:7:8:9 ::1.2.3.4 cafe:affe:1.2.3.4 ::ff:1.2.3.4 ::dddd:1.2.3.4/
  )
{
  ok( !Net::IPAM::IP->getaddrs($txt), "is invalid ($txt)" );
}

done_testing();
