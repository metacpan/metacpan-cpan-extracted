#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :inactivity Test::MultiFork);
use OOPS qw($transfailrx);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;
use Clone::PP qw(clone);
use Test::MultiFork qw(stderr bail_on_bad_plan);


$debug = 0;

my $itarations = 200;
$itarations /= 10 unless $ENV{OOPSTEST_SLOW};

#
# This tests for transaction isolation levels.
# READ COMMITTED and REPEATEABLE READ both fail
# on this.
#
# With mysql, SERIALIZABLE doesn't tolerate more
# than one OOPS active at the same time so we have
# to be careful to clear out the inactive ones.
#

FORK_ab:

ab:

my ($name,$pn,$number) = procname();

a:
	my $to = 'jane';
b:
	my $to = 'bob';

ab:

for my $x (0..$itarations) {
a:
	print "\n\n\n\n\n\n\n\n\n\n" if $debug;
	resetall; 
	$r1->{named_objects}{accounts} = {
		joe => {
			balance => 20,
		},
		jane => {
			balance => 50,
		},
		bob => {
			balance => 30,
		}
	};
	$r1->commit;
	$r1->DESTROY;
	nocon;
	groupmangle('manygroups');
ab:
	rcon;
	eval {
		my $joe = $r1->{named_objects}{accounts}{joe};
		$joe->{balance} -= 20;
		my $ato = $r1->{named_objects}{accounts}{$to};
		$ato->{balance} += 20;
		$r1->commit;
	};
	test(! $@ || $@ =~ /$transfailrx/, $@);
	$r1->DESTROY;
	nocon;
b:
	rcon;
	my (@bal) = map($r1->{named_objects}{accounts}{$_}{balance}, qw(joe jane bob));
	test($bal[0]+$bal[1]+$bal[2] == 100, "balances @bal");
	$r1->DESTROY;
	nocon;
ab:
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

1;
