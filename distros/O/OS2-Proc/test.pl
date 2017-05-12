# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use OS2::Proc;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $out = global_info();

require 'dumpvar.pl';
print "T: Global_info:\n";
dumpValue($out);

$out = OS2::Proc::proc_info_int($$);
print "T: proc_info_int(\$\$=$$):\n";
dumpValue($out);

$out = OS2::Proc::proc_info_int(0);
print "T: proc_info_int(0): mods: 1+$#{$out->[1]}, procs: 1+$#{$out->[0]}\n";
$threads = 0;
for (@{$out->[0]}) { $threads += $_->[7]; }
print "\tthreads: $threads\n";
dumpValue($out);

my ($procs, $modules) = proc_info($$);
print "T: proc_info(\$\$=$$):\n";
dumpValue([$procs, $modules]);

($procs, $modules) = proc_info(0);
print "T: proc_info(0):\n";
dumpValue([$procs, $modules]);

