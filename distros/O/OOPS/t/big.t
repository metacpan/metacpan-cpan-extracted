#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :slow Data::Dumper Clone::PP);
use OOPS;
use OOPS::TestCommon;
use Clone::PP qw(clone);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;

print "1..3183\n";

resetall; # --------------------------------------------------
{
	my $FAIL = <<'END';
END
	my $tests = <<'END';
		%$root = (
			hdaslj4 => { aslx => 'slda4x' x 65},
		);
		$root->{xz1} = \$root->{hdaslj4};
		$root->{xz2} = \$root->{hdaslj4};
		---
		delete $root->{hdaslj4};
		---
		${$root->{xz1}} = 'asdl4j';

		%$root = (
			hdaslj3 => { aslx => 'slda3x' },
		);
		$root->{zz1} = \$root->{hdaslj3};
		$root->{zz2} = \$root->{hdaslj3};
		---
		delete $root->{hdaslj3};
		---
		${$root->{zz1}} = 'asdl3j' x 83;
			
		%$root = (
			hdaslj => { aslx => 'slda' x 90 },
		);
		$root->{yz1} = \$root->{hdaslj};
		$root->{yz2} = \$root->{hdaslj};
		---
		delete $root->{hdaslj};
		---
		${$root->{yz1}} = 'asdlfj' x 83;
			
		%$root = (
			a => [ 'xljasl' x 87 ],
			h1 => { x => 'asldjf' x 73 },
		);
		---
		$root->{h1}{z} = $root->{h1}{x};
		---
		unshift(@{$root->{a}}, 'aljdfads' x 56);
		undef $root->{h1}{x};
END
	
	for my $test (split(/^\s*$/m, $tests)) {
		#
		# commit after each test?
		# samesame after each not-final test?
		# samesame after final
		#
		my (@tests) = split(/\n\s+---\s*\n/, $test);
		my $noroot = ($tests[0] =~ s/\A[\s\n]*NOROOT[\s\n]*//);
		my (@func);
		for my $t (@tests) {
			eval "push(\@func, sub { my \$root = shift; $t })";
			die "eval <<$t>>of<$test>: $@" if $@;
		}

		my $mroot;
		my $proot;
		for my $vobj (qw(0 virtual)) {
			for my $docommit (0..2**(@tests)) {
				for my $dosamesame (0..2**(@tests -1)) {
					resetall;
					my $x = 'rval';
					$mroot = {
						skey => 'sval',
						rkey => \$x,
						akey => [ 'hv1' ],
						hkey => { skey2 => 'sval2' },
					};
					$mroot = {} if $noroot;

					$r1->{named_objects}{root} = clone($mroot);
					$r1->virtual_object($r1->{named_objects}{root}, $vobj) if $vobj;
					$r1->commit;
					rcon;

					my $sig = "$vobj.$docommit.$dosamesame-$test";

					for my $tn (0..$#func) {
						my $tf = $func[$tn];
						$proot = $r1->{named_objects}{root};

						&$tf($mroot);
						&$tf($proot);

						$r1->commit
							if $docommit & 2**$tn;
						samesame($mroot, $proot, "<$tn>$sig") 
							if $dosamesame & 2**$tn;
						rcon
							if $tn < $#func && $docommit & 2**$tn;
					}
					samesame($mroot,$proot, "<END>$sig");
				}
			}
		}

		rcon;
		delete $r1->{named_objects}{root};
		$r1->commit;
		rcon;
		notied;
	}
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

