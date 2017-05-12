use strict;
use warnings;
use Benchmark;
use lib './lib';
use NetAddr::IP::LazyInit;
use NetAddr::IP;

timethese(-3, {
  'NetAddr_IP' => sub { NetAddr::IP->new("127.0.0.1"); },
  'NetAddr_IP_mask' => sub { NetAddr::IP->new("127.0.0.1")->mask; },
  'NetAddr_IP_LazyInit_mask' => sub { NetAddr::IP::LazyInit->new("127.0.0.1")->mask; },
  'NetAddr_IP_LazyInit_2arg_mask' => sub { NetAddr::IP::LazyInit->new("127.0.0.1", "255.255.255.255")->mask; },
  'NetAddr_IP_LazyInit_IP' => sub { NetAddr::IP::LazyInit->new("127.0.0.1"); },
  'NetAddr_IP_LazyInit_addr' => sub { NetAddr::IP::LazyInit->new("127.0.0.1")->addr; },
  'NetAddr_IP_addr' => sub { NetAddr::IP->new("127.0.0.1")->addr; },
});
