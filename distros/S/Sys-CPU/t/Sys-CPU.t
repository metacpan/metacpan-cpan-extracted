# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Sys::CPU;
$loaded = 1;
print "ok 1\n";

$number = &Sys::CPU::cpu_count();
if (defined($number)) {
    print "ok 2 (CPU Count : $number)\n";
} else {
    print "not ok 2 (cpu_count failed)\n";
}

$speed = &Sys::CPU::cpu_clock();
if (defined($speed)) {
    print "ok 3 (CPU Speed : $speed)\n";
} elsif ( $^O eq 'MSWin32'){
    print "ok 3 (CPU Speed: test skipped on MSWin32)\n";
} else  {
    print "not ok 3 (cpu_clock undefined (ok if Win9x))\n";
}

$type = &Sys::CPU::cpu_type();
if (defined($type)) {
    print "ok 4 (CPU Type  : $type)\n";
} else {
    print "not ok 4 (cpu_type unavailable)\n";
}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

