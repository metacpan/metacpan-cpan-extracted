#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :slow Data::Dumper);
use OOPS;
use OOPS::TestCommon;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;

print "1..5123\n";

resetall; # --------------------------------------------------
{
	# we're interested in sequences of ops with different 
	# kinds of values
	#
	# ops:
	#	exists
	#	delete
	#	fetch
	#	store scalar
	#	store ref
	#	store overflow
	#
	#	clear
	#
	# old values:
	#	scalar
	#	ref
	#	overflow
	#	undef
	#	
	# 3 op sequences:
	#	op1 op2 op3
	#

	my $t1 = sub {
		my $named = shift;
		my (@vset) = @{shift()};
		my (@op1) = @{shift()};
		my (@op2) = @{shift()};
		my (@op3) = @{shift()};
		my $root = $named->{root} = {};
		my $i;
		for my $vs (@vset) {
			for my $op1 (@op1) {
				for my $op2 (@op2) {
					for my $op3 (@op3) {
						my $k = "$vs.$op1.$op2.$op3";
						$i++;
						if ($vs eq 'os') {
							$root->{$k} = $i;
						} elsif ($vs eq 'or') {
							$root->{$k} = { $k => $i };
						} elsif ($vs eq 'oo') {
							$root->{$k} = $k x ($ocut / length($k) + 1);
						} elsif ($vs eq 'ou') {
							# don't set it!
						} else {
							die;
						}
					}
				}
				check_resources();
			}
		}
	};
	my $t2 = sub {
		my $named = shift;
		my (@vset) = @{shift()};
		my (@op1) = @{shift()};
		my (@op2) = @{shift()};
		my (@op3) = @{shift()};
		my $savecode = $_[0][0];
		my $clearcode = $_[1][0];
		my $root = $named->{root};
		my $i;
		my $n = 0;
		if ($clearcode & 1) {
			%$root = ();
		}
		for my $jj (0..2) {
			if ($savecode & (2**$n)) {
				$r1->save;
			}
			$n++;
			for my $vs (@vset) {
				for my $op1 (@op1) {
					for my $op2 (@op2) {
						for my $op3 (@op3) {
							my $k = "$vs.$op1.$op2.$op3";
							my $op = ($op1, $op2, $op3)[$jj];
							$i++;
							if ($op eq 'ex') {
								my $j = exists $root->{$k};
							} elsif ($op eq 'de') {
								delete $root->{$k};
							} elsif ($op eq 'fe') {
								my $j = $root->{$k};
							} elsif ($op eq 'ss') {
								$root->{$k} = "$i.$n";
							} elsif ($op eq 'sr') {
								$root->{$k} = { $k => "$i.$n" };
							} elsif ($op eq 'so') {
								$root->{$k} = "-$i.$n-" x ($ocut / length("-$i.$n-") + 1);
							} else {
								die;
							}
						}
					}
				}
				check_resources();
			}
			if ($clearcode & (2**$n)) {
				%$root = ();
			}
		}
	};
	for my $clear (1..15, 0) {
		for my $save (0) {
			runtests($t1, $t2, [qw(virt1 virt0)], [16..31, 0..15], [qw(os or oo ou)], [qw(ex de fe ss sr so)], [qw(ex de fe ss sr so)], [qw(ex de fe ss sr so)], [$save], [$clear]);
		}
	}
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

