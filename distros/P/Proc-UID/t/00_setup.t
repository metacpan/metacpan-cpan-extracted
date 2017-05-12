#!/usr/bin/perl -wT
use strict;
use Test;

# This file is used only to do setup during automated testing.  It only
# has an effect when run as root, as only then does it have permission to
# set permissions on the other files correctly.

my $SETUID_TEST = 65534;	# UID to use on setuid scripts.
my $SETGID_TEST = 65534;	# GID to use on setgid scripts.

BEGIN {
	if ($> != 0) {
		print "1..0 # Skipped, this setup can only be done as root.\n";
		exit 0;
	} else {
		plan tests => 4;
	}
}

ok(chown($SETUID_TEST, -1, "t/04_suid_tests.t2"),1,"Failed to chown t/04_suid_tests.t2");
ok(chmod(04755,"t/04_suid_tests.t2"),1,"Failed to chmod t/04_suid_tests.t2");

ok(chown(-1,$SETGID_TEST,"t/05_sgid_tests.t2"),1,"Failed to chown t/05_sgid_tests.t2");
ok(chmod(02755,"t/05_sgid_tests.t2"),1,"Failed to chmod t/05_sgid_tests.t2");
