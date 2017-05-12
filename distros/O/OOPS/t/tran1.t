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

# 
# This forces a deadlock and then simulates the
# retry that would normally be handled by 
# transaction()
#

my $itarations = 200;
$itarations /= 10 unless $ENV{OOPSTEST_SLOW};

my $maxtries = 50;

my $common;

$debug = 0;

FORK_ab:

ab:
my $pn = (procname())[1];
srand($$);

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
	eval {
		rcon;
		$r1->{named_objects}{root}{$pn} = $$;
		$r1->commit;
	};
	die $@ if $@;
	$r1->DESTROY();
	nocon;
b:
	eval {
		rcon;
		$r1->{named_objects}{root}{$pn} = $$;
		$r1->commit;
	};
	die $@ if $@;
	$r1->DESTROY();
	nocon;
ab:
	rcon;
	no warnings;
	print "# <$pn> '$r1->{named_objects}{root}{$pn}' should be '$$' ($@)\n"
		unless $r1->{named_objects}{root}{$pn} && $r1->{named_objects}{root}{$pn} == $$;
	exit
		unless $r1->{named_objects}{root}{$pn} && $r1->{named_objects}{root}{$pn} == $$;
	use warnings;
	test($r1->{named_objects}{root}{$pn} && $r1->{named_objects}{root}{$pn} == $$);
	$r1->DESTROY();
	nocon;
ab:
	#
	# Using $common{$process_name} to moderate, we loop until
	# all processes have had a sucessful transaction
	#
	my $tries = 0;
	for(;;) {
		my $try = 0;
		my $done = 1;
		print STDERR "# top of loop [$pn]\n" if $debug;
		last if $tries++ >= $maxtries;
ab:
		print STDERR "# running [$pn]\n" if $debug;
		rcon;
		eval {
			$common = getcommon;
			for my $names (keys %$common) {
				print STDERR "# common->{$names} = '$common->{names}' [$pn]\n" if $debug;
				next if $common->{$names};
				$try = 1 if $names eq $pn;	# if we haven't done it yet
				$done = 0;			# someone hasn't finished yet
			}

			if ($try) {
				print STDERR "# trying...  setting d -> x$$ [$pn]\n" if $debug;
				$r1->{named_objects}{root}{d} = "x$$";
				$r1->{named_objects}{root}{$pn} = "x$$";
				$r1->commit;
			}
			$r1->DESTROY();
		};
		nocon;
		print STDERR "# eval done [$pn]\n" if $debug;
ab:
		print STDERR "# recording results [$pn]\n" if $debug;
		last if $done;
		if ($@) {
			if ($@ =~ /$transfailrx/) {
				print STDERR "# locking failure, must try again [$pn]\n";
			} else {
				my $x = $@;
				$x =~ s/\n/  /g;
				print "\nBail out! -- '$x'\n";
			}
		} elsif ($try) {
			print STDERR "# sucess! marking as done [$pn]\n" if $debug;
			lockcommon();
			$common = getcommon;
			$common->{$pn} = 1;
			setcommon($common);
			unlockcommon();
			print STDERR "# common unlocked [$pn]\n" if $debug;
		} else {
			print STDERR "# already done, waiting for peers [$pn]\n" if $debug;
		}
	}
	nocon;
	print STDERR "# at bottom [$pn]\n" if $debug;
ab:
	print STDERR "# past wait at bottom [$pn]\n" if $debug;
	rcon;
	my $r = $r1->{named_objects}{root};
	test($r->{d}, "a victor: $r->{d}");
	if ($r->{d} eq "x$$") {
		test($r->{$pn} eq "x$$", "confirmation");
	}
	$r1->DESTROY();
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

1;
