#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp m_interpolate f_is_uniform /;
use File::Temp qw/tempfile/;

use Test::More tests => 8;
my $tolerance = 1e-6;

my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp('t/test-data/cha3024-99f-lna.s2p');


my ($f_new, $m_new) =  m_interpolate($f, $m, '1.5e9, 2e9 - 3e9 x5, 4e9 += 2e9 x3');
verify_one($f_new,
	pdl(1.5e+09, 2e+09, 2.25e+09, 2.5e+09, 2.75e+09, 3e+09, 4e+09, 6e+09, 8e+09),
	"range interpolation - text");

($f_new, $m_new) =  m_interpolate($f, $m, [1.5e9, '2e9 - 3e9 x5', '4e9 += 2e9 x3']);
verify_one($f_new,
	pdl(1.5e+09, 2e+09, 2.25e+09, 2.5e+09, 2.75e+09, 3e+09, 4e+09, 6e+09, 8e+09),
	"range interpolation - arrayref");

($f_new, $m_new) =  m_interpolate($f, $m,
	[ 1.5e+09, 2e+09, 2.25e+09, 2.5e+09, 2.75e+09, 3e+09, 4e+09, 6e+09, 8e+09 ]);
verify_one($f_new,
	pdl(1.5e+09, 2e+09, 2.25e+09, 2.5e+09, 2.75e+09, 3e+09, 4e+09, 6e+09, 8e+09),
	"range interpolation - arrayref scalar");

($f_new, $m_new) =  m_interpolate($f, $m,
	pdl [ 1.5e+09, 2e+09, 2.25e+09, 2.5e+09, 2.75e+09, 3e+09, 4e+09, 6e+09, 8e+09 ]);
verify_one($f_new,
	pdl(1.5e+09, 2e+09, 2.25e+09, 2.5e+09, 2.75e+09, 3e+09, 4e+09, 6e+09, 8e+09),
	"range interpolation - PDL");


sub verify_one
{
	my ($m, $inverse, $file) = @_;

	my $re_err = sum(($m-$inverse)->re->abs);
	my $im_err = sum(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$file: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$file: imag error ($im_err) < $tolerance");
}

