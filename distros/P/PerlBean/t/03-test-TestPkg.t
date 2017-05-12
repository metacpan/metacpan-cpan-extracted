# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use strict;
use Error qw (:try);
use tmp::TestPkg;

my $isaBar = {};
bless ($isaBar, 'isaBar');
my %opt_ok = (
	b3 => 1,
	b4 => 0,
	s6 => 'valueBar',
	m2 => [qw (ape)],
	m3 => [$isaBar],
	m4 => [$isaBar],
	m5 => [$isaBar],
	m6 => [$isaBar],
	m7 => [$isaBar],
	m8 => [$isaBar],
	m9 => [$isaBar],
	m10 => [qw (mykey 123)],
);
my %opt = ();

# Test 1
%opt = %opt_ok;
my $t = tmp::TestPkg->new (\%opt);
ok (1);

# Test 2
%opt = %opt_ok;
delete ($opt{b3});
my $ok = 0;
try {
	my $t = tmp::TestPkg->new (\%opt);
} catch Error::Simple with {
	$ok = 1;
};
ok ($ok);

# Test 3
%opt = %opt_ok;
delete ($opt{b4});
$ok = 0;
try {
	my $t = tmp::TestPkg->new (\%opt);
} catch Error::Simple with {
	$ok = 1;
};
ok ($ok);

# Test 4
%opt = %opt_ok;
$opt{s6} = $isaBar;
$ok = 1;
try {
	my $t = tmp::TestPkg->new (\%opt);
} catch Error::Simple with {
	$ok = 0;
} otherwise {
	$ok = 0;
};
ok ($ok);
