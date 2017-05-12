#!/usr/bin/perl -wT
use strict;
use Test;
my @subs_to_test;
BEGIN { 

	my $EXTRA_TESTS = 6;

	@subs_to_test= qw(
		getruid geteuid getrgid getegid
		setruid seteuid setrgid setegid
		getsuid getsgid setsuid setsgid
		suid_is_cached
		drop_uid_temp drop_uid_perm restore_uid
		drop_gid_temp drop_gid_perm restore_gid
	);
	
	plan tests => @subs_to_test + $EXTRA_TESTS;
}

# These are for clean-testing with older Perls when using taint.
use lib "blib/lib";
use lib "blib/arch";

use Proc::UID;

# Extra Test 1.
ok(1);	# Module loaded.

# Extra Test 2.
# Ensure that attempting to check a non-existant subroutine fails.
# This is a sanity check.

{
	no warnings 'once';
	ok(defined(*{Proc::UID::no_such_sub}{CODE}),"",
		"no_such_sub appears defined.\n");
}

foreach my $sub (@subs_to_test) {
	no strict 'refs';
	ok(defined(*{"Proc::UID::$sub"}{CODE}),1,"$sub is not defined");
}

# Extra Test 3 & 4
# Test getting our saved UID.

ok(Proc::UID::getsuid() != -1,1,"Failed call to getsuid");
ok(Proc::UID::getsuid(),$<,"Saved UID is not equal to Real UID");

# Extra Test 3 & 4
# Test getting our saved GID.

ok(Proc::UID::getsgid() != -1,1,"Failed call to getsgid");
ok(Proc::UID::getsgid(),$(+0,"Saved GID is not equal to Real GID");
