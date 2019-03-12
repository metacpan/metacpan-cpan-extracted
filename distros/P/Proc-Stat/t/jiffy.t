# jiffy.t
#
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Proc::Stat;

$loaded = 1;
print "ok 1\n";

use strict;
use diagnostics;

my $ps = new Proc::Stat;

unless ($ps->jiffy()) {
  print "/proc file system not supported\nnot";
} else {
  print "\t\tUSER_HZ $ps->{jiffy} ticks per second\n";
}
print "ok 2\n";
