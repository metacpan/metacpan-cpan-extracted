# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use RPM::VersionSort;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $counter = 2;
sub test {
    my $result = shift;
    my $expect = shift;

    my $phrase = "";
    if((($expect < 0) && ($result > -1))
       || ($expect > 0) && ($result < 1)
       || ($expect == 0) && ($result != 0)) {
	$phrase = "not ";
    }
    print "${phrase}ok $counter\n";
    $counter++;
}

test( rpmvercmp("1.0", "2.0"), -1 );
test( rpmvercmp("2.0", "1.0"), 1 );
test( rpmvercmp("2.0", "2.0"), 0 );
test( rpmvercmp("1.6.6-1_SL", "1.6.3p6-0.6x"), 1);
test( rpmvercmp("1.3.26_2.8.10_1.27-5", "1.3.19_2.8.1_1.25-3"), 1 );
