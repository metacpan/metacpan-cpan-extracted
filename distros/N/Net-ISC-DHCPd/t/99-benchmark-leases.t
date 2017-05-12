#!perl

use strict;
use warnings;
use lib './lib';
use Test::More;
use Benchmark;
use File::Temp;


plan skip_all => 'set environment variable DHCP_TORTURE_TEST to run this test' unless ($ENV{'DHCP_TORTURE_TEST'});

my $count  = $ENV{'COUNT'} || 1;
plan tests => 2 + 2 * $count;

my $fh = File::Temp->new();
my $data = do {local $/;<DATA>};

my $data_repeat = $ENV{'DHCP_TORTURE_TEST'} > 1 ? $ENV{'DHCP_TORTURE_TEST'} : 5000;
my $lines = ($data =~ tr/\n// + $data !~ /\n\z/) * $data_repeat;
my $file_size = length($data) * $data_repeat;

for(1..$data_repeat) {
    print $fh $data;
}

seek $fh, 0, 0;
is(($fh->stat)[7], $file_size, 'Is file size correct?');

use_ok("Net::ISC::DHCPd::Leases");

my $time = timeit($count, sub {

    seek $fh, 0, 0;
    my $leases = Net::ISC::DHCPd::Leases->new(fh => $fh);
    is($leases->parse(), $lines, 'all lines got parsed');
    is(scalar(@_=$leases->leases), 5*$data_repeat, 'Are there a bunch of leases?');
});

diag(($lines * $count) .": " .timestr($time));

__DATA__

# comments here

host zed {
  dynamic;
  hardware ethernet 66:11:33:55:66:11;
}

lease 10.19.83.199 {
  starts 0 2008/07/13 19:42:32;
  ends 1 2008/07/14 19:42:32;
  tstp 1 2008/07/14 19:42:32;
  binding state active;
#  binding state free;
  hardware ethernet 00:11:33:55:66:11;
# }
}

lease 10.19.83.198 {
  starts 5 2008/08/15 21:40:31;
  ends 6 2008/08/16 05:44:51;
  tstp 6 2008/08/16 05:44:51;
  binding state free;
  hardware ethernet AA:ff:33:55:22:11;
}

lease 10.19.83.196 {
  starts 5 2008/08/15 21:40:31;
  ends 6 2008/08/16 05:44:51;
  tstp 6 2008/08/16 05:44:51;
  binding state free;
  hardware ethernet AA:ff:33:55:22:11;
}

lease 10.19.83.195 {
  starts 5 2008/08/15 21:40:31;
  ends 6 2008/08/16 05:44:51;
  tstp 6 2008/08/16 05:44:51;
  binding state free;
  hardware ethernet AA:ff:33:55:22:11;
}

lease 10.19.83.194 {
  starts 5 2008/08/15 21:40:31;
  ends 6 2008/08/16 05:44:51;
  tstp 6 2008/08/16 05:44:51;
  binding state free;
  hardware ethernet AA:ff:33:55:22:11;
}


