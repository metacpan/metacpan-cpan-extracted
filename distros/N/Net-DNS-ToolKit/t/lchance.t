# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use Socket;

BEGIN { use_ok('Net::DNS::ToolKit'); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

my @addrs = Net::DNS::ToolKit::lastchance();
my $ip;
foreach (@addrs) {
  ok( $ip = inet_ntoa($_), "NS IP = $ip");
}
