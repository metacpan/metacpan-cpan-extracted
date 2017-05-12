#! perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use Run ':NEW';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$pipe = (new_pipe "r", (new_system 'perl', '-le', 'print "ok 4"'))->run
  and print "ok 2\n";

@in = <$pipe> and print "ok 3\n";
print @in;

$pipe = (new_pipe "w", 
	 (new_system 'perl', '-e', 'print "ok $n" while $n = <>'))->run
  and print "ok 5\n";

print $pipe "6\n";
print $pipe "7\n";

close $pipe and (sleep 1, print "ok 8\n"); # Let the kid finish

$in = (new_readpipe new_system 'perl', '-le', 'print "ok 10";print "ok 11"')->run
  and print "ok 9\n";

print $in;

@in = (new_readpipe_split new_system 'perl', '-le', 'print "13 14";print 15')->run
  and print "ok 12\n";

for (@in) {
  print "ok $_\n";
}

(new_system 
 'perl', '-le', 'for (@ARGV) {print "ok $_"}',
 (new_readpipe_split new_system 'perl', '-le', 'print "16 17";print 18'))->run
  and print "ok 19\n";
