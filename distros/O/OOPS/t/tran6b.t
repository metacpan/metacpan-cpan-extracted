#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :inactivity Test::MultiFork Clone::PP);
use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;
use Clone::PP qw(clone);
use Test::MultiFork qw(stderr bail_on_bad_plan);

my $itarations = 200;
$itarations /= 10 unless $ENV{OOPSTEST_SLOW};
if ($ENV{OOPSTEST_DSN} && $ENV{OOPSTEST_DSN} =~ /^dbi:mysql/i) {
	printf STDERR "# mysql is very slow at this test, reducing iterations from %d to %d\n",
		$itarations, $itarations / 20;
	$itarations = int($itarations/20);
}

my $common;
$debug = 1;

# 
# simple test of transaction()
#

FORK_ab:

ab:
my $pn = (procname())[1];

a:
lockcommon;
setcommon({ values => {} });
unlockcommon;

ab:

# --------------------------------------------------
for my $x (1..$itarations) {
a:
	print "# #############################################################################################\n" if $debug;
	printf "# at %d\n", __LINE__ if $debug;
	resetall; 
	$r1->{named_objects}{root} = [ 1, 2, 4, 8, 16, 32 ];
	$r1->commit;
	nocon;
	printf "# at %d\n", __LINE__ if $debug;
ab:
	printf "# at %d\n", __LINE__ if $debug;
	my $sum = 0;
	for(;;) {
		my $done;
		my $did = 0;
		transaction(sub {
			$did = 0;
			rcon;
			my $todo = $r1->{named_objects}{root};
			for my $i (0..$#$todo) {
				next unless $todo->[$i];
				$r1->lock(\$todo->[$i]);
				$did += $todo->[$i];
				$todo->[$i] = 0;
				$r1->commit();
				last;
			}
		});
		$sum += $did;
		print "# $pn did $did\n";
		last unless $did;
		nocon;
	}
	nocon;
	printf "# at %d\n", __LINE__ if $debug;
ab:
	printf "# at %d\n", __LINE__ if $debug;
	lockcommon();
	$common = getcommon;
	$common->{values}{$pn} = $sum;
	print "# my total: $sum\n" if $debug;
	setcommon($common);
	unlockcommon();
	printf "# at %d\n", __LINE__ if $debug;
a:
	printf "# at %d\n", __LINE__ if $debug;
	lockcommon();
	$common = getcommon;
	my $total = 0;
	for my $n (keys %{$common->{values}}) {
		print "# total from $n: $common->{values}{$n}\n";
		$total += $common->{values}{$n};
	}
	test($total == 63, "Each item handled once");
	unlockcommon();
	printf "# at %d\n", __LINE__ if $debug;
ab:
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

1;
