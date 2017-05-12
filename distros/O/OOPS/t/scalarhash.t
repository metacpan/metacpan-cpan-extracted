#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter 5.000803 Data::Dumper Clone::PP);
use OOPS::TestCommon;
use OOPS;
use Clone::PP qw(clone);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;

print "1..1691\n";

resetall; # --------------------------------------------------
{
	my $number = 0;
	my $FAIL = <<'END';

END
	sub selector {
		return 1 if 1 || $number == 1;
		return 0;
	}
	my $tests = <<'END';
		my $x = exists $root->{h2}{b};
		%{$root->{h2}} = ();

		my $x = $root->{h2}{b};
		%{$root->{h2}} = ();

		$root->{h2}{b} = '22';
		%{$root->{h2}} = ();

		my $x = $root->{h2}{b};
		delete @{$root->{h2}}{'a','b'};

		$root->{h2}{b} = '22';
		delete @{$root->{h2}}{'a','b'};

		%{$root->{h2}} = ();
		---
		$root->{h2}{z} = 'q';
		---
		delete $root->{h2}{z};

		delete @{$root->{h2}}{'a','b'};

		my $x = exists $root->{h2}{b};
		delete @{$root->{h2}}{'a','b'};

		$root->{h1}{x} = 2;
		---
		delete $root->{h1}{x};

		%{$root->{h2}} = ();
END
	
	for my $test (split(/^\s*$/m, $tests)) {
		#
		# commit after each test?
		# samesame after each not-final test?
		# samesame after final
		#
		$number++;
		next unless &selector($number);
		my %conf;
		$test =~ s/\A[\n\s]+//;
		$conf{$1} = [ split(' ', $2) ]
			while $test =~ s/(V|S|C)=(.*)\n\s*//;
		my (@tests) = split(/\n\s+---\s*\n/, $test);
		my (@func);
		for my $t (@tests) {
			eval "push(\@func, sub { my \$root = shift; $t })";
			die "eval <<$t>>of<$test>: $@" if $@;
		}
		my (@virt) = $conf{V}
			? @{$conf{V}}
			: (qw(0 virtual));
		my (@commits) = $conf{C}
			? @{$conf{C}}
			: (0..2**(@tests));
		my (@ss) = $conf{S}
			? @{$conf{S}}
			: (0..2**(@tests -1));

		my $mroot;
		my $proot;
		for my $vobj (@virt) {
			for my $docommit (@commits) {
				for my $dosamesame (@ss) {
					resetall;
					my $x = 'rval';
					$mroot = {
						h1 => { },
						h2 => { a => 1, b => [] },
					};

					$r1->{named_objects}{root} = clone($mroot);
					$r1->virtual_object($r1->{named_objects}{root}{h1}, $vobj) if $vobj;
					$r1->virtual_object($r1->{named_objects}{root}{h2}, $vobj) if $vobj;
					$r1->commit;
					rcon;

					my $sig = "N=$number.V=$vobj.C=$docommit.S=$dosamesame-$test";

					for my $tn (0..$#func) {
						my $tf = $func[$tn];
						$proot = $r1->{named_objects}{root};

						print "# $sig\n" if $debug;
						print "# EXECUTING $tests[$tn]\n" if $debug;
						&$tf($mroot);
						&$tf($proot);

						$r1->commit
							if $docommit & 2**$tn;
						print "# COMPARING\n" 
							if $dosamesame & 2**$tn && $debug;
						test(sdocompare($mroot, $proot), "<$tn>$sig")
							if $dosamesame & 2**$tn;
						rcon
							if $tn < $#func && $docommit & 2**$tn;
					}
					print "# FINAL COMPARE\n" if $debug;
					test(sdocompare($mroot, $proot), "<END>$sig")
				}
			}
		}

		rcon;

		if (exists $r1->{named_objects}{root}{acircular}) {
			@{$r1->{named_objects}{root}{acircular}} = ();
			delete $r1->{named_objects}{root}{acircular};
		}
		delete $r1->{named_objects}{root};
		$r1->commit;
		rcon;
		notied;
	}
}

sub sdocompare
{
	my ($x, $y) = @_;

	for my $k (keys %$x) {
		next unless reftype($x->{$k}) eq 'HASH';
		next if !!scalar(%{$x->{$k}}) == !!scalar(%{$y->{$k}});
		print "# scalar(%{\$x->{$k}}) = ".scalar(%{$x->{$k}}).", scalar(%{\$y->{$k}}) = ".scalar(%{$y->{$k}})."\n";
		print "# keys %{\$x->{$k}} = ".join(' ', keys %{$x->{$k}})."\n";
		print "# keys %{\$y->{$k}} = ".join(' ', keys %{$y->{$k}})."\n";
		return 0;
	}

	my $r = compare($x, $y);
	return $r if $r;

	my $c1 = ref2string($x);
	my $c2 = ref2string($y);
	return 1 if $c1 eq $c2;
	# print "c1=$c1\nc2=$c2\n";

	return 0;
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

