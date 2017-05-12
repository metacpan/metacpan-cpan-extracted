#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :inactivity Test::MultiFork Time::HiRes);
use OOPS qw($transfailrx);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;
use Clone::PP qw(clone);
use Time::HiRes qw(sleep);
use Test::MultiFork qw(stderr bail_on_bad_plan);

my $looplength = 1000;
$looplength /= 20 unless $ENV{OOPSTEST_SLOW};
$OOPS::debug_dbidelay = 0;
$debug = 0;

sub sum;

FORK_ab:

ab:
my $pn = (procname())[1];
srand($$);

a:
	my $to = 'jane';
b:
	my $to = 'bob';

ab:
for my $x (0..$looplength) {
a:
	print "\n\n\n\n\n\n\n\n\n\n" if $debug;
	resetall; 
	%{$r1->{named_objects}} = (
		joe => {
			coin1 => 25,
			coin2 => 10,
		},
		jane => {
			coin3 => 5,
			coin4 => 10,
		},
		bob => {
			coin5 => 50,
		}
	);
	$r1->commit;
	nocon;
	groupmangle('manygroups');
	rcon;
	my (@bal) = map(values %{$r1->{named_objects}{$_}}, qw(joe jane bob));
	no warnings;
	test(sum(@bal) == 100, "coins @bal");
	use warnings;
	$r1->DESTROY;
	nocon;

ab:
	if ($x > $looplength/2) {
		$OOPS::debug_dbidelay = 1;
	}
	rcon;
	sleep(rand($OOPS::debug_tdelay)/1000) if $OOPS::debug_tdelay && $OOPS::debug_dbidelay;
	eval {
		my $no = $r1->{named_objects};
		$no->{$to}{coin1} = $no->{joe}{coin1};
		delete $no->{joe}{coin1};
		$r1->commit;
	};
	test(! $@ || $@ =~ /$transfailrx/, $@);
	$r1->DESTROY;
	nocon;
b:
	rcon;
	my (@bal) = map(values %{$r1->{named_objects}{$_}}, qw(joe jane bob));
	no warnings;
	test(sum(@bal) == 100, "coins @bal");
	use warnings;
	$r1->DESTROY;
	nocon;
ab:
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

sub sum
{
	my $s = 0;
	while (@_) {
		my $x = shift;
		$s += $x if defined $x;
	}
	return $s;
}

1;
