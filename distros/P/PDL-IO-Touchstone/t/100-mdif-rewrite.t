#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::MDIF;
use File::Temp qw/tempfile/;

use Test::More tests => 743;

my $tolerance = 1e-6;

use Data::Dumper;

my ($fh, $fn) = tempfile();
END {close $fh; unlink $fn};

my $mdf = rmdf('t/test-data/muRata/muRata-GQM-0402.mdf');
wmdf($fn, $mdf);

my $mdf2 = rmdf($fn);

ok(@$mdf == @$mdf2, "count");

for (my $i = 0; $i < @$mdf; $i++)
{
	my ($f1, $m1, $param_type1, $z01, $comments1, $fmt1, $funit1, $orig_f_unit1) = @{ $mdf->[$i]->{_data} };
	my ($f2, $m2, $param_type2, $z02, $comments2, $fmt2, $funit2, $orig_f_unit2) = @{ $mdf2->[$i]->{_data} };

	# These first three just check my code in this test:
	ok($$f1 != $$f2, "f refs are different");
	ok($$m1 != $$m2, "m refs are different");
	ok($$z01 != $$z02, "z0 refs are different");

	verify_one($f1, $f2, "freqs");
	verify_one($m1, $m2, "matrix");
	verify_one($z01, $z02, "z0");

	foreach my $n (qw/param_type comments fmt funit orig_f_unit/)
	{
		ok(eval "qq{\$${n}1} eq qq{\$${n}2}", "$n is correct");
	}
}

#print Dumper $mdf;

sub verify_one
{
	my ($m, $inverse, $file) = @_;

	my $re_err = sum(($m-$inverse)->re->abs);
	my $im_err = sum(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$file: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$file: imag error ($im_err) < $tolerance");
}
