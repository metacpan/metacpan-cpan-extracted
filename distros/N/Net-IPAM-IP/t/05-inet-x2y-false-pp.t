#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;
use Socket ();

BEGIN {
  no warnings 'redefine';

  # a really buggy implementation, test redefinition by 'use Net::IPAM::IP'
  *Socket::inet_pton = sub { undef };
  *Socket::inet_ntop = sub { undef };
}

BEGIN { use_ok('Net::IPAM::IP') || print "Bail out!\n"; }

# valid
foreach my $txt (qw/:: 0.0.0.0 fE80::0:1 1.2.3.4 1:2:3:4:5:6:7:8 ::ffff:127.0.0.1 ::ff:0 caFe:: fe80::ffff/)
{
  ok( Net::IPAM::IP->new($txt), "_inet_pton_pp: is valid ($txt)" );
}

# invalid
foreach my $txt (
  qw/010.0.0.1 10.000.0.1 : ::cafe::affe cafe::: cafe::1:: cafe::1: :cafe:: ::cafe::
  cafe::1:2:3:4:5:6:7:8 1:2:3:4:5:6 1:2:3:4:5:6:7:8:9 ::1.2.3.4 cafe:affe:1.2.3.4 ::ff:1.2.3.4 ::dddd:1.2.3.4
  ::12345 ffgd::1 fe80::: 127.0.0.X 300.0.0.1 030.0.0.1/
  )
{
  ok( !Net::IPAM::IP->new($txt), "_inet_pton_pp: is invalid ($txt)" );
}

my $t = {
  '0.0.0.0'          => '0.0.0.0',
  '1.1.1.1'          => '1.1.1.1',
  '1.2.3.4'          => '1.2.3.4',
  '::ffff:127.0.0.1' => '127.0.0.1',
  '::cafe:affe'      => '::cafe:affe',
  '0e80::1'          => 'e80::1',
  'fe80::1'          => 'fe80::1',
  'fe80::ffff'       => 'fe80::ffff',
  'fe80::'           => 'fe80::',
};

foreach my $k ( keys %$t ) {
  my $v  = $t->{$k};
  my $ip = Net::IPAM::IP->new($k);
  ok( $ip eq $v, "_inet_ntop_pp: $v" );
}

done_testing();
