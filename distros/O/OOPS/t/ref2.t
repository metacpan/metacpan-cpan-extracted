#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :slow);
use OOPS::TestCommon;
use strict;
use warnings;
use diagnostics;

print "1..128860\n";

sub selector {
	my $number = shift;
	return 1 if 1; # $number > 3;
	return 0;
}

my $FAIL = <<'END';
	#
	# This fails because we don't keep the bless 
	# information with the scalar but rather with the
	# ref.
	#
	$root->{x} = 'foobar';
	$root->{y} = \$root->{x};
	wa($root->{y});
	bless $y, 'baz';
	---
	$root->{y} = 7;
	---
	$root->{y} = \$root->{x};
	wa($root->{y});


END
my $tests = <<'END';
	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=0 1 2 3
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A57} = \$root->{hkey}{skey2};
	wa($root->{A57});
	$root->{B57} = \$root->{hkey}{skey2};
	wa($root->{B57});
	---
				delete $root->{hkey}{skey2};
	---
	$root->{C57} = \$root->{hkey}{skey2};
	wa($root->{C57});
	$root->{D57} = \$root->{hkey}{skey2};
	wa($root->{D57});
	---
				$root->{hkey}{skey2} = ($subtest & 1) ? undef : 'aftD57';
	---
	$root->{E57} = \$root->{hkey}{skey2};
	wa($root->{E57});
	$root->{F57} = \$root->{hkey}{skey2};
	wa($root->{F57});
	---
				%{$root->{hkey}} = ();
	---
	$root->{G57} = \$root->{hkey}{skey2};
	wa($root->{G57});
	$root->{H57} = \$root->{hkey}{skey2};
	wa($root->{H57});
	---
				$root->{hkey}{skey2} = ($subtest & 2) ? undef : 'aftH57';
	---
	$root->{I57} = \$root->{hkey}{skey2};
	wa($root->{I57});
	$root->{J57} = \$root->{hkey}{skey2};
	wa($root->{J57});
	---
				${$root->{B57}} = 'B57';
				${$root->{D57}} = 'D57';
				${$root->{F57}} = 'F57';
				${$root->{H57}} = 'H57';
				${$root->{J57}} = 'J57';



	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	$root->{N81} = \$root->{hkey}{skey2};
	wa($root->{N81});
	$root->{M81} = \$root->{hkey}{skey2};
	wa($root->{M81});
	---
	my $x = 'zz81x';
	$root->{M81} = \$x;
	delete $root->{hkey}{skey2};



	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	$root->{N81} = \$root->{hkey}{skey3};
	wa($root->{N81});
	$root->{M81} = \$root->{hkey}{skey3};
	wa($root->{M81});
	---
	my $x = 'zz81x';
	$root->{M81} = \$x;
	delete $root->{hkey}{skey3};



	C=0 1 2 3 4 7 8 15 16 31 32 63 64
	S=0 1 2 3 4 7 8 15 16 31 32 63 64
	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	$root->{hkey}{X84} = 'ZxZx84';
	$root->{N84} = \$root->{hkey}{X84};
	wa($root->{N84});
	---
	%{$root->{hkey}} = ();
	---
	$root->{Z84} = \$root->{hkey}{X84};
	wa($root->{Z84});
	---
	$root->{Y84} = \$root->{hkey}{X84};
	wa($root->{Y84});
	---
	${$root->{Z84}} = 'Bugallz84';



	C=0 1 2 3 4 7 8 15 16 31 32 63 64
	S=0 1 2 3 4 7 8 15 16 31 32 63 64
	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	$root->{hkey}{X72} = 'ZxZx72';
	---
	%{$root->{hkey}} = ();
	---
	$root->{Z72} = \$root->{hkey}{X72};
	wa($root->{Z72});
	---
	$root->{Y72} = \$root->{hkey}{X72};
	wa($root->{Y72});
	---
	${$root->{Z72}} = 'Bugallz72';



	C=0 1 2 3 4 7 8 15 16 31 32 63 64
	S=0 1 2 3 4 7 8 15 16 31 32 63 64
	T=delete shift nuke
	C=1
	S=0
	T=nuke
	delete $root->{skey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{X44} = \$root->{akey}[1];
	$root->{akey}[1] = 'cabbage44';
	---
	$root->{Y44} = \$root->{akey}[1];
	---
	if ($subtest eq 'nuke') {
		delete $root->{akey};
	} elsif ($subtest eq 'shift') {
		shift @{$root->{akey}};
	} elsif ($subtest eq 'delete') {
		delete $root->{akey}[1];
	} else {
		die;
	}
	---
	${$root->{X44}} = 'grape44';



	$root->{FOO} = "BAR";
	$root->{X9} = [ \$root->{FOO} ];
	wa($root->{X9}[0]);
	$root->{Y9} = [ \$root->{FOO} ];
	wa($root->{Y9}[0]);
	---
	${$root->{X9}[0]} = 'FOO9';


	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{a11} = \$root->{skey};
	wa($root->{a11});
	$root->{A11} = \$root->{a11};
	wa($root->{A11});
	---
	$root->{skey} = 'blah11';


	delete $root->{skey};
	delete $root->{akey};
	$root->{Z43} = \$root->{hkey}{skey2};
	wa($root->{Z43});
	$root->{rkey} = \$root->{hkey}{skey2};
	wa($root->{rkey});
	---
	delete $root->{hkey};
	---
	${$root->{Z43}} = 'nu43';



	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	$root->{hkey}{x} = { z => 'q' };
	---
	delete $root->{hkey}{x};
	---
	%$root = ();



	C=7
	S=0
	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{X82} = \$root->{skey};
	$root->{Y82} = \$root->{skey};
	---
	delete $root->{skey};
	---
	$root->{A82} = ${$root->{X82}};
	---
	${$root->{X82}} = 'ZZZ82';




	C=3
	my $x = 'X93';
	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{X93} = \$x;
	$root->{Y93} = \$x;
	$root->{Z93} = \'zz';
	---
	$root->{X93} = $root->{Z93};
	$root->{Y93} = $root->{Z93};
	$root->{Z93} = \'zzz';


	my $x = 'X92';
	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{X92} = \$x;
	$root->{Y92} = \$x;
	---
	${$root->{X92}} = 'Y92';


	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	%{$root->{hkey}} = ();
	---
	$root->{zed94} = exists $root->{hkey}{skey2}


	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	$root->{hkey}{x} = { z => 'q95' };
	---
	delete $root->{hkey}{x}{z};
	---
	delete $root->{hkey}{x};


	delete $root->{skey};
	delete $root->{akey};
	delete $root->{rkey};
	$root->{hkey}{x} = { z => 'q96' };
	---
	%{$root->{hkey}} = ();
	---
	delete $root->{hkey};


	delete $root->{skey};
	delete $root->{hkey};
	$root->{rkey} = \$root->{akey}[0];
	---
	$root->{akey}[0] = 'Nix97';

	
	delete $root->{skey};
	delete $root->{hkey};
	${$root->{rkey}} = \$root->{akey}[0];
	---
	$root->{akey}[0] = 'Nix32';


	my $x = 'zog';
	$root->{Z17} = \$x;
	---
	$root->{X17} = $root->{Z17};
	---
	my $y = 'zig';
	$root->{Z17} = \$y;

	
	$root->{X9} = [ \$root->{skey} ];
	wa($root->{X9}[0]);
	$root->{Y9} = [ \$root->{skey} ];
	wa($root->{Y9}[0]);
	---
	#${$root->{X9}[0]} = 'FOO9';
	my $x = $root->{X9}[0];
	$$x = 'FOOBAR9';

	$root->{X9} = [ \$root->{skey} ];
	wa($root->{X9}[0]);
	$root->{Y9} = [ \$root->{skey} ];
	wa($root->{Y9}[0]);
	delete $root->{skey};
	---
	${$root->{X9}[0]} = 'FOO9';

	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{a10} = \$root->{skey};
	wa($root->{a10});
	$root->{b10} = \$root->{skey};
	wa($root->{b10});
	---
	delete $root->{skey};
	${$root->{a10}} = 'nval';

	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{a} = \$root->{skey};
	wa($root->{a});
	---
	$root->{skey} = 'blah289';


	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{a} = \$root->{skey};
	wa($root->{a});
	1;
	---
	$root->{skey} = 'blah13';

	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{a} = \$root->{skey};
	wa($root->{a});
	---
	${$root->{a}} = 'foobar';

	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{a} = \$root->{skey};
	wa($root->{a});
	$root->{A18} = $root->{a};
	---
	$root->{C} = ${$root->{a}};

	$root->{akey}[0] = 'nv';

	$root->{zzzz} = \$root->{akey}[0];

	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	$root->{a12} = \$root->{skey};
	wa($root->{a12});
	---
	$root->{A12} = $root->{a12};
	wa($root->{A12});

	$root->{A14} = 'zzzz';
	$root->{a} = \$root->{A14};
	wa($root->{a});
	$root->{b14} = \$root->{A14};
	wa($root->{b14});
	${$root->{a}} = 'aaaa';
	---
	$root->{C} = ${$root->{b14}};

	$root->{A15} = 'zzzz';
	$root->{a} = \$root->{A15};
	$root->{b15} = \$root->{A15};
	${$root->{a}} = 'aaaa';
	---
	$root->{C} = ${$root->{b15}};

	$root->{A16} = 'zzzz';
	my $a = \$root->{A16};
	my $b = \$root->{A16};
	$$a = 'aaaa';
	$root->{C} = $$b;

	$root->{a} = \$root->{skey};
	$root->{A17} = \$root->{a};
	$root->{b15} = \$root->{A17};
	$root->{c} = \$root->{A17};

	$root->{www} = \$root->{skey};
	wa($root->{www});
	$root->{zzz} = \$root->{www};
	wa($root->{zzz});

	V=0
	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	delete $root->{skey};
	my $x = 'xxxxx';
	my $y = \$x;
	my $z = \$y;
	$root->{nnnn} = \$y;
	---
	${$root->{nnnn}} = 'qqqq'

	$root->{hkey}{skey3} = \$root->{akey}[0];
	---
	$root->{akey}[0] = 'nv';

	$root->{zzzz} = \$root->{akey}[0];
	---
	$root->{akey}[0] = 'nv';

	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	delete $root->{skey};
	my $x = 'xxxxx';
	my $y = \$x;
	my $z = \$y;
	$root->{nnnn} = \$y;
	---
	${${$root->{nnnn}}} = 'qqqq'

	my $x;
	$root->{zzzz} = \$x;
	$x = 82;
	---
	$root->{nnnn} = \$root->{zzzz};

	$root->{acircular} = [];
	push(@{$root->{acircular}}, $root->{acircular});

	V=0
	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=assign nuke splice move fetch
	E=$root->{akey} = [ 'BLORF', 'BLAF', 'BLOG' ];
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A33} = \$root->{akey}[1];
	wa($root->{A33});
	$root->{B33} = \$root->{akey}[1];
	wa($root->{B33});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{akey}[1];
	} elsif ($subtest eq 'assign') {
		$root->{akey}[1] = 'assign1';
	} elsif ($subtest eq 'nuke') {
		delete $root->{akey};
	} elsif ($subtest eq 'splice') {
		splice(@{$root->{akey}}, 1, 1);
	} elsif ($subtest eq 'move') {
		shift(@{$root->{akey}});
	} else {
		die;
	}
	---
	my $i = $subtest eq 'move' ? 0 : 1;
	$root->{C33} = \$root->{akey}[$i];
	wa($root->{C33});
	$root->{D33} = \$root->{akey}[$i];
	wa($root->{D33});
	---
	${$root->{B33}} = 'B33';
	${$root->{D33}} = 'D33';

	V=0
	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=fetch assign nuke splice move
	U=fetch assign nuke splice move
	E=$root->{akey} = [ 'BLORF', 'BLAF', 'BLOG' ];
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A29} = \$root->{akey}[1];
	wa($root->{A29});
	$root->{B29} = \$root->{akey}[1];
	wa($root->{B29});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{akey}[1];
	} elsif ($subtest eq 'assign') {
		$root->{akey}[1] = 'assign1';
	} elsif ($subtest eq 'nuke') {
		delete $root->{akey};
	} elsif ($subtest eq 'splice') {
		splice(@{$root->{akey}}, 1, 1);
	} elsif ($subtest eq 'move') {
		shift(@{$root->{akey}});
	} else {
		die;
	}
	---
	my $i = $subtest eq 'move' ? 0 : 1;
	$root->{C29} = \$root->{akey}[$i];
	wa($root->{C29});
	$root->{D29} = \$root->{akey}[$i];
	wa($root->{D29});
	---
	my $i = $subtest eq 'move' ? 0 : 1;
	if ($subtest2 eq 'fetch') {
		my $x = $root->{akey}[$i];
	} elsif ($subtest2 eq 'assign') {
		$root->{akey}[$i] = 'assign1';
	} elsif ($subtest2 eq 'nuke') {
		delete $root->{akey};
	} elsif ($subtest2 eq 'splice') {
		splice(@{$root->{akey}}, $i, 1);
	} elsif ($subtest2 eq 'move') {
		unshift(@{$root->{akey}}, 'a', 'b');
	} else {
		die;
	}
	---
	my $i = 1 + ($subtest eq 'move' ? -1 : 0) + ($subtest2 eq 'move' ? 2 : 0);
	$root->{E29} = \$root->{akey}[$i];
	wa($root->{E29});
	$root->{F29} = \$root->{akey}[$i];
	wa($root->{F29});
	---
	${$root->{B29}} = 'B29';
	${$root->{D29}} = 'D29';
	${$root->{F29}} = 'F29';


	V=0
	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=fetch assign nuke splice move
	U=fetch assign nuke splice move
	X=fetch assign nuke splice move
	E=$root->{akey} = [ 'BLORF', 'BLAF', 'BLOG' ];
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A27} = \$root->{akey}[1];
	wa($root->{A27});
	$root->{B27} = \$root->{akey}[1];
	wa($root->{B27});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{akey}[1];
	} elsif ($subtest eq 'assign') {
		$root->{akey}[1] = 'assign1';
	} elsif ($subtest eq 'nuke') {
		delete $root->{akey};
	} elsif ($subtest eq 'splice') {
		splice(@{$root->{akey}}, 1, 1);
	} elsif ($subtest eq 'move') {
		shift(@{$root->{akey}});
	} else {
		die;
	}
	---
	my $i = $subtest eq 'move' ? 0 : 1;
	$root->{C27} = \$root->{akey}[$i];
	wa($root->{C27});
	$root->{D27} = \$root->{akey}[$i];
	wa($root->{D27});
	---
	my $i = $subtest eq 'move' ? 0 : 1;
	if ($subtest2 eq 'fetch') {
		my $x = $root->{akey}[$i];
	} elsif ($subtest2 eq 'assign') {
		$root->{akey}[$i] = 'assign1';
	} elsif ($subtest2 eq 'nuke') {
		delete $root->{akey};
	} elsif ($subtest2 eq 'splice') {
		splice(@{$root->{akey}}, $i, 1);
	} elsif ($subtest2 eq 'move') {
		unshift(@{$root->{akey}}, 'a', 'b');
	} else {
		die;
	}
	---
	my $i = 1 + ($subtest eq 'move' ? -1 : 0) + ($subtest2 eq 'move' ? 2 : 0);
	$root->{E27} = \$root->{akey}[$i];
	wa($root->{E27});
	$root->{F27} = \$root->{akey}[$i];
	wa($root->{F27});
	---
	my $i = 1 + ($subtest eq 'move' ? -1 : 0) + ($subtest2 eq 'move' ? 2 : 0);
	if ($subtest eq 'fetch') {
		my $x = $root->{akey}[$i];
	} elsif ($subtest eq 'assign') {
		$root->{akey}[$i] = 'assign1';
	} elsif ($subtest eq 'nuke') {
		delete $root->{akey};
	} elsif ($subtest eq 'splice') {
		splice(@{$root->{akey}}, $i, 1);
	} elsif ($subtest eq 'move') {
		unshift(@{$root->{akey}}, 'x', 'y', 'z');
	} else {
		die;
	}
	---
	my $i = 1 
		+ ($subtest eq 'move' ? -1 : 0) 
		+ ($subtest2 eq 'move' ? 2 : 0)
		+ ($subtest3 eq 'move' ? 3 : 0);
	$root->{G27} = \$root->{akey}[$i];
	wa($root->{G27});
	$root->{H27} = \$root->{akey}[$i];
	wa($root->{H27});
	---
	${$root->{B27}} = 'B27';
	${$root->{D27}} = 'D27';
	${$root->{F27}} = 'F27';
	${$root->{H27}} = 'H27';



	T=workaround getref 
	V=virtual
	delete $root->{akey};
	delete $root->{hkey};
	delete $root->{rkey};
	if ($subtest eq 'getref') {
		$root->{a19} = getref(%$root, 'skey');
		$root->{b19} = getref(%$root, 'skey');
	} elsif ($subtest eq 'workaround') {
		$root->{a19} = \$root->{skey};
		wa($root->{a19});
		$root->{b19} = \$root->{skey};
		wa($root->{b19});
	} else {
		die;
	}
	---
	delete $root->{skey};
	${$root->{a19}} = 'nval';

END

my $x;
supercross1($tests, {
		skey => 'sval',
		rkey => \$x,
		akey => [ 'hv1' ],
		hkey => { skey2 => 'sval2' },
	}, \&selector);
	

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

