#!/usr/bin/perl -w
#
# Make sure the VT102 module can set its size OK.
#
# Copyright (C) Andrew Wood
# NO WARRANTY - see COPYING.
#

require Term::VT102;

@testsizes = (
  1, 1,
  80, 24,
  0, 0,
  -1000, -1000,
  1000, 1000
);

$nt = ($#testsizes + 1) / 2;		# number of sub-tests

foreach $i (1 .. $nt) {
	print "$i..$nt\n";

	$cols = shift @testsizes;
	$rows = shift @testsizes;

	my $vt = Term::VT102->new ('cols' => $cols, 'rows' => $rows);

	($ncols, $nrows) = $vt->size ();

	$cols = 80 if ($cols < 1);
	$rows = 24 if ($rows < 1);

	if (($cols != $ncols) or ($rows != $nrows)) {
		print "not ok $i\n";
		warn "returned size: $ncols x $nrows, wanted $cols x $rows\n";
	} else {
		print "ok $i\n";
	}
}

# EOF
