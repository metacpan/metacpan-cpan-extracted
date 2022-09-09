#!/usr/bin/env perl

use 5.016;
use warnings;
use DDP;
use PDK::Device::Cisco;
use Time::HiRes qw/gettimeofday/;

my $start = sprintf("%d.%06d", Time::HiRes::gettimeofday);
print "start at $start\n";
my $fw = PDK::Device::Cisco->new(username => "admin", password => "Cisc0123", host => '192.168.8.201');

p $fw;
my $cmds = [
  'access-list inside extended permit tcp host 10.111.125.0 host 22.222.222.208 eq 22222',
  'access-list inside extended permit tcp host 10.111.125.2 host 22.222.222.208 eq 22222',
  'access-list inside extended permit tcp host 10.111.125.3 host 22.222.222.208 eq 22222',
  'access-list inside extended permit tcp host 10.111.125.4 host 22.222.222.208 eq 22222',
  'access-list inside extended permit tcp host 10.111.125.5 host 22.222.222.208 eq 22222',
  'access-list inside extended permit tcp host 10.111.125.6 host 22.222.222.208 eq 22222',
];

my $ret = $fw->execCommands('show version');

my $end = sprintf("%d.%06d", Time::HiRes::gettimeofday);
print "end at $end\n";
print "spend:" . ($end - $start) . "\n\n";
# p $ret;
# # 数据转储
use File::Slurp qw/write_file/;
write_file("ios.log", $ret->{config});