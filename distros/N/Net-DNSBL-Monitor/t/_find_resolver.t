# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 2;

BEGIN { use_ok ('Net::DNS::ToolKit'); }
my $loaded = 1;
END { print "not ok 1\n" unless $loaded; }

ok(@_ = &Net::DNS::ToolKit::get_ns(),'find resolver');

if (@_) {
  print STDERR "\n";
  foreach (@_) {
    print STDERR 'found nameserver ', &Net::DNS::ToolKit::inet_ntoa($_), "\n";
  }
}
