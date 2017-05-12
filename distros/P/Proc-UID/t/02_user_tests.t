#!/usr/bin/perl -wT
use strict;
use Test;

# These tests are to ensure that Proc::UID's provide sane results.
# These do not assume any special privileges.

BEGIN { plan tests => 18; }

# These are for clean-testing with older Perls when using taint.
use lib "blib/lib";
use lib "blib/arch";

use Proc::UID qw(:funcs :vars);

my $TEST_UID = 1000;	# Any non-root UID.
my $TEST_GID = 1000;

ok(1);	# Loaded Proc::UID.						#1

# These make sure that our functions agree with our variables.

ok(geteuid(),$>,"geteuid not the same as \$>");				#2
ok(getruid(),$<,"getruid not the same as \$<");				#3
ok(getsuid(),$>,"getsuid not the same as original \$>");		#4

# Make sure our variables look sensible.

ok($SUID,getsuid(),"\$SUID and getsuid() do not match");		#5
ok($SGID,getsgid(),"\$SGID and getsgid() do not match");		#6

ok($RUID,getruid(),"\$RUID and getruid() do not match");		#7
ok($RGID,getrgid(),"\$RGID and getrgid() do not match");		#8

ok($EUID,geteuid(),"\$EUID and geteuid() do not match");		#9
ok($EGID,getegid(),"\$EGID and getegid() do not match");		#10

# We should never be able to change our UID or GID to anything
# else.  If we're root, we should drop our privileges first.

if ($EUID == 0) {
	eval {drop_gid_perm($TEST_GID);};
	if ($@) {
		ok(0,undef,"Dropping group privileges failed");	#11
	} else {
		ok(1);						#11
	}
	eval {drop_uid_perm($TEST_UID);};
	if ($@) {
		ok(0,undef,"Dropping root privileges failed");	#12
	} else {
		ok(1);						#12
	}
} else {
	skip("Running as non-root, no need to drop group",1);	#11
	skip("Running as non-root, no need to drop privileges",1);#12
}

eval {$EUID = 0;}; ok($@,qr/./,"Unexpectedly set EUID = 0");	#13
eval {$RUID = 0;}; ok($@,qr/./,"Unexpectedly set RUID = 0");	#14

if (suid_is_cached()) {
	skip("Cannot set saved-UID directly on this system",1);		#15
} else {
	eval {$SUID = 0;}; ok($@,qr/./,"Unexpectedly set SUID = 0");	#15
}

eval {$EGID = 0;}; ok($@,qr/./,"Unexpectedly set EGID = 0");	#16
eval {$RGID = 0;}; ok($@,qr/./,"Unexpectedly set RGID = 0");	#17

if (suid_is_cached()) {
	skip("Cannot set saved-GID correctly on this system",1);	#18
} else {
	eval {$SGID = 0;}; ok($@,qr/./,"Unexpectedly set SGID = 0");	#19
}
