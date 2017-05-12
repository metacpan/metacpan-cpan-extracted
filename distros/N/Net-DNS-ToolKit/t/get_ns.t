# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);

BEGIN { use_ok('Net::DNS::ToolKit', qw(get_ns inet_ntoa)); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

my @netaddrs = get_ns();
my $ip;
my $output = "\n\tlocal nameserver(s)\n";
if (@netaddrs) {
  foreach (@netaddrs) {
    ok( $ip = inet_ntoa($_), "NS IP array = $ip");
    $output .= "\t$ip\n";
  }
  print STDERR $output;

  $ip = get_ns();
  ok( $ip = inet_ntoa($ip), "NS IP scalar = $ip");


} else {
  select STDERR; $| = 1;
  select STDOUT;
  print STDERR q|
The resolver library did not return any nameservers. This could
mean that your system is not properly configured, or more likely
that the ToolKit.pm interface to the "C" resolver library is not
working properly.

This latter condition has been reported with versions of perl 5.8x
on some systems, however the author has not been able to duplicate
it on in house hosts. If you have a system that exhibits this problem
and can provide a shell account for debug purposes, please contact
the author, Michael Robinton <michael@bizsystems.com> .
|;
  sleep 1;
  ok( 0, '-' );
}
