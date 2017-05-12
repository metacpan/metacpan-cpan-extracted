#!perl

use warnings;
use strict;
use lib qw(lib);
use Net::DHCP::Info;
use Test::More tests => 3;


my $config = Net::DHCP::Info->new(\*DATA);

is(ref $config, "Net::DHCP::Info", "obj constructed");

my $lease = $config->fetch_lease;

is($lease->starts, "2007/09/19 17:51:41", "starts is ok");
is(ref $lease->starts_datetime, "DateTime", "datetime is ok");

__DATA__
lease 192.168.0.253 {
  starts 3 2007/09/19 17:51:41;
  ends 4 2007/09/20 17:51:41;
  tstp 4 2007/09/20 17:51:41;
  binding state free;
  hardware ethernet 00:0e:7b:cc:bb:aa;
  client-hostname "foo.com";
}
