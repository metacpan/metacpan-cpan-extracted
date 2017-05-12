# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More tests => 3;

BEGIN { use_ok('Net::DNS::ToolKit', qw(inet_ntoa)); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

my $naddr;
my $ip;
ok( $naddr = Net::DNS::ToolKit::get_default(), "DEFAULT");
ok( $ip = inet_ntoa($naddr), "IP = $ip");
