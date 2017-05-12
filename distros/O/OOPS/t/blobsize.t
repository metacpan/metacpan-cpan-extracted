#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :slow);
use OOPS::TestCommon;
use strict;
use warnings;
use diagnostics;

print "1..43048\n";

sub selector {
	my $number = shift;
	return 1 if 1; # $number > 3;
	return 0;
}

my $FAIL = <<'END';
END
my $tests = <<'END';
	T=-1 0 +1
	U=0.5 1 2 3
	X=0.5 1 2 3
	$root->{X} = "-001-"  x ($bbs / length("-as1-") * $subtest2 + $subtest);
	---
	$root->{X} = "-002-"  x ($bbs / length("-as1-") * $subtest3 + 0)

	T=-1 0 +1
	U=0.5 1 2 3
	X=0.5 1 2 3
	$root->{X} = "-003-"  x ($bbs / length("-as1-") * $subtest2 + $subtest);
	---
	$root->{X} = "-004-"  x ($bbs / length("-as1-") * $subtest3 + 1)

	T=-1 0 +1
	U=0.5 1 2 3
	X=0.5 1 2 3
	$root->{X} = "-005-"  x ($bbs / length("-as1-") * $subtest2 + $subtest);
	---
	$root->{X} = "-006-"  x ($bbs / length("-as1-") * $subtest3 - 1)

	T=-1 0 +1
	U=0.5 1 2 3
	$root->{X} = "-007-"  x ($bbs / length("-as1-") * $subtest2 + $subtest);
	---
	$root->{X} = [ 'xyd' ];

	T=-1 0 +1
	U=0.5 1 2 3
	$root->{X} = [ 'xya' ];
	---
	$root->{X} = "-008-"  x ($bbs / length("-as1-") * $subtest2 + $subtest);

	T=-1 0 +1
	U=-1 0 +1
	$root->{X} = "-009-"  x ($ocut / length("-as1-") + $subtest);
	---
	$root->{X} = "-010-"  x ($ocut / length("-as1-") + $subtest2)

	T=-1 0 +1
	U=0.5 1 2 3
	$root->{X} = "-011-"  x ($ocut / length("-as1-") + $subtest);
	---
	$root->{X} = [ 'xyb' ];

	T=-1 0 +1
	$root->{X} = [ 'xyc' ];
	---
	$root->{X} = "-012-"  x ($ocut / length("-as1-") + $subtest);
END

my $x;
supercross1($tests, {
		skey => 'sval',
		rkey => \$x,
		akey => [ 'hv1' ],
		hkey => { skey2 => 'sval2' },
	}, \&selector);
	

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

