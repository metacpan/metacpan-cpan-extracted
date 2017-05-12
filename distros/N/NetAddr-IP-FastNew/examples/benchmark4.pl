use strict;
use warnings;
use Benchmark qw( cmpthese timethese );
use lib './lib';
use NetAddr::IP::FastNew;
use NetAddr::IP;

cmpthese(-3, {
  'NetAddr_IP' => sub { NetAddr::IP->new("127.0.0.1"); },
  'NetAddr_IP_FastNew_new_ipv4' => sub { NetAddr::IP::FastNew->new_ipv4("127.0.0.1"); },
  'NetAddr_IP_FastNew_new_ipv4_mask' => sub { NetAddr::IP::FastNew->new_ipv4_mask("127.0.0.0", '255.255.255.0'); },
  'NetAddr_IP_FastNew_new_ipv4_cidr' => sub { NetAddr::IP::FastNew->new_ipv4_cidr('127.0.0.0/24'); },
});
