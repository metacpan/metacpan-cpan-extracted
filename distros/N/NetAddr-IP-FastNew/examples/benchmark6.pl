use strict;
use warnings;
use Benchmark qw( cmpthese timethese );
use lib './lib';
use NetAddr::IP::FastNew;
use NetAddr::IP;

cmpthese(-3, {
  'NetAddr_IP_ipv6' => sub { NetAddr::IP->new('fe80::/64'); },
  'NetAddr_IP_FastNew_new_ipv6' => sub { NetAddr::IP::FastNew->new_ipv6('fe80::/64'); },
});
