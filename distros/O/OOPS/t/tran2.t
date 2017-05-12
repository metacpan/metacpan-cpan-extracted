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

my $itarations = 200;
$itarations /= 10 unless $ENV{OOPSTEST_SLOW};

my $common;
$debug = 0;

# 
# simple test of transaction()
#

FORK_ab:

ab:
my $pn = (procname())[1];

a:
lockcommon;
setcommon({});
unlockcommon;

ab:

# --------------------------------------------------
for my $x (1..$itarations) {
a:
	print "\n\n\n\n\n\n\n\n\n\n" if $debug;
	resetall; 
	$r1->{named_objects}{root} = {};
	$r1->commit;
	nocon;
ab:
	lockcommon();
	$common = getcommon;
	$common->{$pn} = 0;
	setcommon($common);
	unlockcommon();
a:
	rcon;
	$r1->{named_objects}{root}{$pn} = $$;
	$r1->commit;
	nocon;
b:
	rcon;
	$r1->{named_objects}{root}{$pn} = $$;
	$r1->commit;
	nocon;
ab:
	transaction(sub {
		rcon;
		$r1->{named_objects}{root}{d} = "x$$";
		$r1->{named_objects}{root}{$pn} = "x$$";
		$r1->commit;
	});
	nocon;
ab:
	rcon;
	my $r = $r1->{named_objects}{root};
	test($r->{d}, "a victor: $r->{d}");
	if ($r->{d} eq "x$$") {
		test($r->{$pn} eq "x$$", "confirmation");
	}
	nocon;
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

1;
