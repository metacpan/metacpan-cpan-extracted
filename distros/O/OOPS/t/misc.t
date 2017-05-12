#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :slow Data::Dumper Clone::PP);
use Clone::PP qw(clone);
use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;

print "1..7872\n";

resetall; # --------------------------------------------------
{
#					$mroot = {
#						skey => 'sval',
#						rkey => \$x,
#						akey => [ 'hv1' ],
#						hkey => { skey2 => 'sval2' },
#					};
	my $FAIL = <<'END';
END
	my $tests = <<'END';
		$root->{a} = 7;
		---
		$root->{A} = 8;

		$root->{a} = { ahash => 1};
		---
		$root->{a} = [ 'an array' ];

		NOROOT
		my $o1 = { o => 'oink' };
		$root->{xyz} = [ ['abc'], \$o1 ];
		---
		shift(@{$root->{xyz}});

		%$root = ();
		my $o1 = { oho => 1 };
		$root->{xyz} = \$o1;
		---
		$root->{abc} = $root->{xyz};
		$r1->workaround27555($root->{abc});
		delete $root->{xyz};

		%$root = ();
		my $o1 = { ooo => 1 };
		$root->{xyz} = [ ['1'], \$o1 ];

		%$root = ();
		my $u1 = undef;
		my $a1 = [ '1' ];
		my $o1 = { o => 1 };
		$root->{xyz} = [ ['1'], {h=>'2'}, {h=>'3'}, \$u1, \$a1, ['4'], ['5'], \$o1, {h=>6} ];
		---
		shift(@{$root->{xyz}});

		$root->{o} = { z => 7 };
		---
		bless($root->{o}, 'XZY');

		${$root->{rkey}} = [ 'xy02' ]
		---
		${$root->{rkey}} = 'ab05'

		${$root->{rkey}} = 'xy01'
		---
		${$root->{rkey}} = 'ab05'

		${$root->{rkey}} = 'ab04' x ($ocut / 4 + 1);
		---
		${$root->{rkey}} = 'ab05'

		$root->{newover} = 'ab01' x ($ocut / 4 + 1);
		---
		$root->{newover} = 'ab02';

		delete $root->{rkey};
		---
		delete $root->{akey};

		$root->{skey} = 'new value'
		---
		$root->{circle} = $root

		$root->{newover} = 'ab03' x ($ocut / 4 + 1);
		---
		delete $root->{newover};

		$root->{newover} = '0' x ($ocut + 1);
		---
		delete $root->{newover};

		$root->{newover} = '0' x ($ocut + 1);
		---
		$root->{newover} = 'xyz';

		${$root->{rkey}} = '0' x ($ocut + 1);
		---
		${$root->{rkey}} = 'xyz'

		${$root->{rkey}} = '0' x ($ocut + 1);
		---
		delete $root->{rkey}

		${$root->{rkey}} = 'ab06' x ($ocut / 4 + 1);
		---
		${$root->{rkey}} = undef;

		${$root->{rkey}} = 'ab07' x ($ocut / 4 + 1);
		---
		${$root->{rkey}} = undef;

		$root->{hkey}{newover} = 'ab08' x ($ocut / 4 + 1);
		---
		$root->{hkey}{newover} = 'ab09';

		$root->{hkey}{newover} = 'ab10' x ($ocut / 4 + 1);
		---
		delete $root->{hkey}{newover};

		$root->{hkey}{newover} = '0' x ($ocut + 1);
		---
		delete $root->{hkey}{newover};

		$root->{akey}[1] = 'ab11' x ($ocut / 4 + 1); 
		---
		$root->{akey}[1] = 'nbc';

		$root->{akey}[1] = 'ab12' x ($ocut / 4 + 1); 
		---
		$root->{akey}[1] = undef;

		$root->{akey}[1] = 'ab13' x ($ocut / 4 + 1); 
		---
		$root->{akey}[1] = '0';

		$root->{akey}[1] = 'ab14' x ($ocut / 4 + 1);
		---
		$root->{akey}[1] = '';

		$root->{akey}[1] = 'ab15' x ($ocut / 4 + 1);
		---
		$#{$root->{akey}} = 0;

		$root->{akey}[1] = '0' x ($ocut + 1);
		---
		$#{$root->{akey}} = 0;

		$root->{skey} = 'ab16' x ($ocut / 4 + 1);
		---
		$root->{skey} = 'ab17';

		$root->{akey}[0] = 'xy03';
		---
		$root->{akey}[0] = ''; # x

		$root->{akey}[0] = \'xy04';
		---
		$root->{akey}[0] = ''; # x

		$root->{akey}[0] = 'ab18' x ($ocut / 4 + 1); 
		---
		$root->{akey}[0] = ''; # x

		$root->{akey}[4] = 'ab19' x ($ocut / 4 + 1);
		---
		$root->{akey}[4] = ''; # y

		$root->{akey}[4] = 'ab20' x ($ocut / 4 + 1);
		---
		$#{$root->{akey}} = 2;

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

