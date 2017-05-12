#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter :slow);
use OOPS::TestCommon;
use strict;
use warnings;
use diagnostics;

print "1..299227\n";

sub selector {
	my $number = shift;
	return 1 if 1; # $number > 3;
	return 0;
}

my $FAIL = <<'END';
END
my $tests = <<'END';
	%$root = ();
	my $x = getref(%$root, 'FOO23');
	$root->{FOO23} = \$x;
	---
	delete $root->{FOO23};

	%$root = ();
	my $x = getref(%$root, 'FOO22');
	$root->{FOO22} = \$x;
	---
	$root->{BAR22} = ${$root->{FOO22}};
	delete $root->{FOO23};

	U=0 1
	T=skey2 newkey
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{hkey}{$subtest} = getref(%$root, $subtest);
	---
	$root->{eref35} = $root->{hkey}{$subtest};
	---
	if ($subtest2) { delete $root->{hkey} } else { delete $root->{hkey}{$subtest} }

	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{hkey}{X34} = getref(%$root, 'Y34');
	$root->{hkey}{Y34} = getref(%$root, 'X34');
	---
	delete $root->{hkey}{X34};
	---
	delete $root->{hkey}{Y34};

	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{hkey}{W30} = getref(%$root, 'Y30');
	$root->{hkey}{X30} = getref(%$root, 'Y30');
	$root->{hkey}{Y30} = getref(%$root, 'X30');
	$root->{hkey}{Z30} = getref(%$root, 'X30');
	---
	${$root->{W30}} = getref(%$root, 'Y30');

	U=0 1
	X=0
	X=0
	V=0
	C=5
	S=0
	U=0
	%$root = ();
	$root->{hkey}{skey68} = getref(%$root, 'jkey68');
	---
	$root->{eref68} = $root->{hkey}{skey68};
	---
	${$root->{eref68}} = 'FOOBAr68';
	---
	if ($subtest2) { delete $root->{hkey} } else { delete $root->{hkey}{$subtest} }

	T=skey2 newkey
	U=0 1
	X=0
	X=0
	X=0
	V=0
	C=5
	S=0
	T=skey2
	U=0
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{hkey}{$subtest} = getref(%$root, $subtest);
	---
	$root->{eref77} = $root->{hkey}{$subtest};
	---
	${$root->{eref77}} = getref(%$root, 'fo77');
	$root->{fo77} = 'seeme77';
	---
	if ($subtest2) { delete $root->{hkey} } else { delete $root->{hkey}{$subtest} }

	T=skey2 newkey
	U=0 1
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{hkey}{Z90} = 'ZZ90';
	$root->{hkey}{$subtest} = getref(%$root, $subtest);
	---
	delete $root->{hkey}{Z90};
	if ($subtest2) { delete $root->{hkey} } else { delete $root->{hkey}{$subtest} }

	V=0
	T=0 1
	U=0 1
	delete $root->{hkey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{akey}[$subtest] = \$root->{akey}[$subtest];
	---
	if ($subtest2) { delete $root->{akey} } else { delete $root->{akey}[$subtest] }

	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=fetch assign clear delete big
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A79} = \$root->{hkey}{skey2};
	wa($root->{A79});
	$root->{B79} = \$root->{hkey}{skey2};
	wa($root->{B79});
	bless $root->{B79}, 'BLESS79';
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C79} = \$root->{hkey}{skey2};
	wa($root->{C79});
	$root->{D79} = \$root->{hkey}{skey2};
	wa($root->{D79});
	---
	bless $root->{D79}, 'CURSE79';
	---
	${$root->{B79}} = 'B79';
	bless $root->{A79}, 'NOD79';
	${$root->{D79}} = 'D79';




	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=fetch assign clear delete big
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A76} = \$root->{hkey}{skey2};
	wa($root->{A76});
	$root->{B76} = \$root->{hkey}{skey2};
	wa($root->{B76});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C76} = \$root->{hkey}{skey2};
	wa($root->{C76});
	$root->{D76} = \$root->{hkey}{skey2};
	wa($root->{D76});
	---
	${$root->{B76}} = 'B76';
	${$root->{D76}} = 'D76';





	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=assign clear delete fetch big
	U=assign clear delete fetch big
	X=0 1
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A83} = \$root->{hkey}{skey2};
	wa($root->{A83});
	$root->{B83} = \$root->{hkey}{skey2};
	wa($root->{B83});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C83} = \$root->{hkey}{skey2};
	wa($root->{C83});
	$root->{D83} = \$root->{hkey}{skey2};
	wa($root->{D83});
	---
	if ($subtest2 eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest2 eq 'assign') {
		$root->{hkey}{skey2} = 'assign2';
	} elsif ($subtest2 eq 'big') {
		$root->{hkey}{skey2} = "-as2-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest2 eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest2 eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{E83} = \$root->{hkey}{skey2};
	wa($root->{E83});
	$root->{F83} = \$root->{hkey}{skey2};
	wa($root->{F83});
	---
	${$root->{B83}} = $subtest3 ? 'B83' : "-B83-"  x ($ocut / length("-as1-") + 1);
	${$root->{D83}} = $subtest3 ? 'D83' : "-D83-"  x ($ocut / length("-as1-") + 1);
	${$root->{F83}} = $subtest3 ? 'F83' : "-F83-"  x ($ocut / length("-as1-") + 1);






	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=delete clear assign big
	U=clear delete assign big
	X=delete clear assign big
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A80} = \$root->{hkey}{skey2};
	wa($root->{A80});
	$root->{B80} = \$root->{hkey}{skey2};
	wa($root->{B80});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C80} = \$root->{hkey}{skey2};
	wa($root->{C80});
	$root->{D80} = \$root->{hkey}{skey2};
	wa($root->{D80});
	---
	if ($subtest2 eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest2 eq 'assign') {
		$root->{hkey}{skey2} = 'assign2';
	} elsif ($subtest2 eq 'big') {
		$root->{hkey}{skey2} = "-as2-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest2 eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest2 eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{E80} = \$root->{hkey}{skey2};
	wa($root->{E80});
	$root->{F80} = \$root->{hkey}{skey2};
	wa($root->{F80});
	---
	if ($subtest3 eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest3 eq 'assign') {
		$root->{hkey}{skey2} = 'assign3';
	} elsif ($subtest3 eq 'big') {
		$root->{hkey}{skey2} = "-as3-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest3 eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest3 eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{G80} = \$root->{hkey}{skey2};
	wa($root->{G80});
	$root->{H80} = \$root->{hkey}{skey2};
	wa($root->{H80});
	---
	${$root->{B80}} = 'B80';
	${$root->{D80}} = 'D80';
	${$root->{F80}} = 'F80';
	${$root->{H80}} = 'H80';





	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=fetch assign clear delete big
	E=$root->{hkey}{skey2} = "-sval2-" x ($ocut / length("-sval2-") + 1);
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A78} = \$root->{hkey}{skey2};
	wa($root->{A78});
	$root->{B78} = \$root->{hkey}{skey2};
	wa($root->{B78});
	bless $root->{B78}, 'BLESS78';
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C78} = \$root->{hkey}{skey2};
	wa($root->{C78});
	$root->{D78} = \$root->{hkey}{skey2};
	wa($root->{D78});
	---
	bless $root->{D78}, 'CURSE78';
	---
	${$root->{B78}} = 'B78';
	bless $root->{A78}, 'NOD78';
	${$root->{D78}} = 'D78';





	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=fetch assign clear delete big
	E=$root->{hkey}{skey2} = "-sval2-" x ($ocut / length("-sval2-") + 1);
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A74} = \$root->{hkey}{skey2};
	wa($root->{A74});
	$root->{B74} = \$root->{hkey}{skey2};
	wa($root->{B74});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C74} = \$root->{hkey}{skey2};
	wa($root->{C74});
	$root->{D74} = \$root->{hkey}{skey2};
	wa($root->{D74});
	---
	${$root->{B74}} = 'B74';
	${$root->{D74}} = 'D74';


	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=assign clear delete fetch big
	U=assign clear delete fetch big
	X=0 1
	E=$root->{hkey}{skey2} = "-sval2-" x ($ocut / length("-sval2-") + 1);
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A53} = \$root->{hkey}{skey2};
	wa($root->{A53});
	$root->{B53} = \$root->{hkey}{skey2};
	wa($root->{B53});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C53} = \$root->{hkey}{skey2};
	wa($root->{C53});
	$root->{D53} = \$root->{hkey}{skey2};
	wa($root->{D53});
	---
	if ($subtest2 eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest2 eq 'assign') {
		$root->{hkey}{skey2} = 'assign2';
	} elsif ($subtest2 eq 'big') {
		$root->{hkey}{skey2} = "-as2-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest2 eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest2 eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{E53} = \$root->{hkey}{skey2};
	wa($root->{E53});
	$root->{F53} = \$root->{hkey}{skey2};
	wa($root->{F53});
	---
	${$root->{B53}} = $subtest3 ? 'B53' : "-B53-"  x ($ocut / length("-as1-") + 1);
	${$root->{D53}} = $subtest3 ? 'D53' : "-D53-"  x ($ocut / length("-as1-") + 1);
	${$root->{F53}} = $subtest3 ? 'F53' : "-F53-"  x ($ocut / length("-as1-") + 1);



	C=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	S=0 1 2 4 8 16 32 64 128 256 512 1024 2048
	T=delete clear assign big
	U=clear delete assign big
	X=delete clear assign big
	E=$root->{hkey}{skey2} = "-sval2-" x ($ocut / length("-sval2-") + 1);
	;
	delete $root->{akey};
	delete $root->{rkey};
	delete $root->{skey};
	$root->{A54} = \$root->{hkey}{skey2};
	wa($root->{A54});
	$root->{B54} = \$root->{hkey}{skey2};
	wa($root->{B54});
	---
	if ($subtest eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest eq 'assign') {
		$root->{hkey}{skey2} = 'assign1';
	} elsif ($subtest eq 'big') {
		$root->{hkey}{skey2} = "-as1-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{C54} = \$root->{hkey}{skey2};
	wa($root->{C54});
	$root->{D54} = \$root->{hkey}{skey2};
	wa($root->{D54});
	---
	if ($subtest2 eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest2 eq 'assign') {
		$root->{hkey}{skey2} = 'assign2';
	} elsif ($subtest2 eq 'big') {
		$root->{hkey}{skey2} = "-as2-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest2 eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest2 eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{E54} = \$root->{hkey}{skey2};
	wa($root->{E54});
	$root->{F54} = \$root->{hkey}{skey2};
	wa($root->{F54});
	---
	if ($subtest3 eq 'fetch') {
		my $x = $root->{hkey}{skey2};
	} elsif ($subtest3 eq 'assign') {
		$root->{hkey}{skey2} = 'assign3';
	} elsif ($subtest3 eq 'big') {
		$root->{hkey}{skey2} = "-as3-"  x ($ocut / length("-as1-") + 1);
	} elsif ($subtest3 eq 'clear') {
		%{$root->{hkey}} = ();
	} elsif ($subtest3 eq 'delete') {
		delete $root->{hkey}{skey2};
	} else {
		die;
	}
	---
	$root->{G54} = \$root->{hkey}{skey2};
	wa($root->{G54});
	$root->{H54} = \$root->{hkey}{skey2};
	wa($root->{H54});
	---
	${$root->{B54}} = 'B54';
	${$root->{D54}} = 'D54';
	${$root->{F54}} = 'F54';
	${$root->{H54}} = 'H54';


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

