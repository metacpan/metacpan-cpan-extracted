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

my $itarations = 100;

#$itarations /= 10 unless $ENV{OOPSTEST_SLOW};
#if ($ENV{OOPSTEST_DSN} && $ENV{OOPSTEST_DSN} =~ /^dbi:mysql/i) {
#	printf STDERR "# mysql is very slow at this test, reducing iterations from %d to %d\n",
#		$itarations, $itarations / 20;
#	$itarations = int($itarations/20);
#}

if ($dbms eq 'sqlite') {
	# it deadlocks...
	$itarations = 20;
	$OOPS::transaction_maxtries = 30;
}

my $common;
$debug = 1;

my $upto = 3;

# 
# simple test of transaction()
#

FORK_ab:

ab:
my $pn = (procname())[1];

srand($$);

a:
lockcommon;
setcommon({ values => {} });
unlockcommon;

a:
	{
		nocon;
		resetall; 
		my $root = $r1->{named_objects}{root} = { };
		for my $i (1..$upto) {
			$root->{$i} = {};
		}
		$r1->commit;
	}

ab:
	for my $x (1..$itarations) {
		eval {
			transaction(sub {
				rcon;
				my $root = $r1->{named_objects}{root};
				for my $i (sort { ((rand(1) > 0.5) ? 1 : -1) } 1..$upto) {
					my %rev;
					my $r = int(rand($upto*2));
					my $count = 0;
					for my $k (keys %{$root->{$i}}) {
						die "Duplicate value in $i $k & $rev{$root->{$i}{$k}}" if $rev{$root->{$i}{$k}};
						$rev{$root->{$i}{$k}} = $k;
						$count++;
					}
					if ($count == $upto) {
						print "# working on reinitialize $i: $r => 1\n";
						$root->{$i} = { $r => 1 };
					} else {
						if (exists $root->{$i}{$r}) {
							print "# skipping $i: $r - already exists\n";
						} else {
							printf "# adding %d: %d => %d\n", $i, $r, $count+1;
							$root->{$i}{$r} = $count+1;
						}
					}
				}
				$r1->commit;
			});
		};
		checkerror();
		nocon;
	}
ab:

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

sub checkerror
{
	return unless $@;
	my $x = $@;
	$x =~ s/\n/  /g;
	print "\nBail out! -- '$x'\n";
}


1;
