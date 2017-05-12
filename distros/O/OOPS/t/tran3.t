#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :inactivity Test::MultiFork);
use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;
use Clone::PP qw(clone);
use Test::MultiFork qw(stderr bail_on_bad_plan);

sub mconst;

$debug = 0;

#
# This one will fail if autocommit is on
# With mysql, this will also fail at the READ UNCOMMITTED transaction isolation level
#

FORK_ab:

ab:
my $pn = (procname())[1];

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
	mconst;
	$r1->commit;
#system("psql rectangle -c 'select * from attribute'");
	nocon;
	groupmangle('manygroups');

a:
	rcon;
	my $joe = $r1->{named_objects}{accounts}{joe};
	$joe->{balance} -= 10;
	$r1->rollback;
	$r1->DESTROY;
	rcon;
#system("psql rectangle -c 'select * from attribute'");
	mconst;
	$r1->DESTROY;
	nocon;

b:
	rcon;
	my $joe = $r1->{named_objects}{accounts}{joe};
	$joe->{balance} -= 10;
	my $jane = $r1->{named_objects}{accounts}{jane};
	$jane->{balance} += 10;
	$r1->commit;
	rcon;
#system("psql rectangle -c 'select * from attribute'");
	mconst;
	$r1->DESTROY;
	nocon;

ab:

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

sub mconst
{
	my $a = $r1->{named_objects}{accounts};
	my $tot = 0;
	for my $ac (keys %$a) {
# print "# $ac: $a->{$ac}{balance}\n";
		$tot += $a->{$ac}{balance};
	}
	my ($pkg, $file, $line) = caller;
	test($tot == 100, "balance at $line");
#system("psql rectangle -c 'select * from attribute'");
}

1;
