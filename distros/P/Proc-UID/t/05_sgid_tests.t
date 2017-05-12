#!/usr/bin/perl -wT
use strict;

# This exists purely to call our child test script.

$ENV{PATH} = "/bin";
delete $ENV{ENV};

my $TEST_UID = 12345;	# Must be different from that in 00_setup.t

# Drop privs if we're running as root.  If this fails, the .t2 file
# *should* pick it up.

if ($> == 0) {
        $< = $TEST_UID;
        $> = $TEST_UID;
}


system("t/05_sgid_tests.t2");
