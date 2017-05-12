# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use MultiTail;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Cwd;
sub notify;
my $tail;
my $True=1;
my $False=0;

$dir=cwd();

$tail=MultiTail->new (  
					 OutputPrefix    => 'ft',
                RemoveDuplicate => $True,
                Files => ["${dir}/$0"],
                Pattern => ["script"],
                ExceptPattern => ["Bad"],
                Function => \&notify,
);

$tail->read;
$tail->print;

sub notify {
        my ($rArray)=shift;
				print STDOUT "Notify function test PASS ....\n"; 
}
# line1 of test script Pass...
# line2 of test script Pass...
# line3 of test script Pass...
# line4 of test script Pass...
# line4 of test script Pass...
# Bad line of test script you should not see this line Fail...
# line4 of test script Pass...
# line4 of test script Pass...
# line5 of test script Pass...
