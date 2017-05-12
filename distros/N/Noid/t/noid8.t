# ------------------------------------
#
# Project:	Noid
#
# Name:		noid8.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Do a "dbcreate" using a variety of options to
#		test that the various options in the policy can
#		be turned on and off.
#
# Command line parameters:  none.
#
# Author:	Michael A. Russell
#
# Revision History:
#		7/21/2004 - MAR - Initial writing
#
# ------------------------------------

# Declare a subroutine we'll define later.
sub get_policy;

use Test::More tests => 9;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

system("$rm_cmd ; " .
	"$noid_cmd dbcreate .rde long 13030 cdlib.org noidTest >/dev/null");
# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate .rddk long 13030 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "GRANITE", "policy \"GRANITE\"");
	}
else {
	ok(0, "unable to get policy");
	}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate .rddk long 00000 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "-RANITE", "policy \"-RANITE\"");
	}
else {
	ok(0, "unable to get policy");
	}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate .sddk long 13030 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "G-ANITE", "policy \"G-ANITE\"");
	}
else {
	ok(0, "unable to get policy");
	}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst8.rdek long 13030 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "GR-NITE", "policy \"GR-NITE\"");
	}
else {
	ok(0, "unable to get policy");
	}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate .rddk medium 13030 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "GRA-ITE", "policy \"GRA-ITE\"");
	}
else {
	ok(0, "unable to get policy");
	}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate r-r.rdd long 13030 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "GRAN--E", "policy \"GRAN--E\"");
	}
else {
	ok(0, "unable to get policy");
	}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate .rdd long 13030 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "GRANI-E", "policy \"GRANI-E\"");
	}
else {
	ok(0, "unable to get policy");
	}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate a.rdd long 13030 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "GRANI--", "policy \"GRANI--\"");
	}
else {
	ok(0, "unable to get policy");
}

# Do dbcreate.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate a-a.seeeeee medium 00000 cdlib.org noidTest >/dev/null");

# Get and check the policy.
$policy = get_policy("$this_dir/NOID/README");
if (defined($policy)) {
	is($policy, "-------", "policy \"-------\"");
}
else {
	ok(0, "unable to get policy");
}


# ----
# Subroutine to get the policy out of the README file.
sub get_policy {
	my $file_name = $_[0];

	unless (open (README, "$file_name")) {
		diag("open of \"$file_name\" failed, $!");
		return(undef);
		}

	while (<README>) {
		if (/^Policy:\s+\(:((G|-)(R|-)(A|-)(N|-)(I|-)(T|-)(E|-))\)\s*$/)
			{
			close(README);
			return ($1);
			}
		}

	close(README);
	return(undef);
}
