#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp m_interpolate f_is_uniform /;
use File::Temp qw/tempfile/;

use Test::More tests => 10;

# For each file, rescale the frequency range smaller by 1kHz and then grow it
# back to see if the values are close.  Tolerance is a bit low, but thats ok
# because we know we are probably interpolating outside of frequency ranges:
my $tolerance = 1e-3;

my $datadir = 't/test-data';

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = map { "$datadir/$_" } grep { /\.s\d+p$/i } readdir($dir);
closedir($dir);

foreach my $fn (@files, @ARGV)
{
	my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp($fn);

	next unless $param_type eq 'S';
	next unless $f->nelem >= 4;
	next unless f_is_uniform($f);

	my $f_min = $f->copy->slice(0)->sclr;
	my $f_max = $f->copy->slice(-1)->sclr;
	my $f_count = $f->nelem;

	my $f_new_min = $f_min+1000;
	my $f_new_max = $f_max-1000;
	my $f_new_count = $f->nelem;

	my ($f_new, $m_new) =  m_interpolate($f, $m, "$f_new_min - $f_new_max x $f_new_count");

	# Quiet: don't warn, we know we are extrapolating back out beyond fmin/fmax:
	my ($f2, $m2) = m_interpolate($f_new, $m_new,
		{ freq_range => "$f_min - $f_max x$f_count", quiet => 1 });

	verify_one($f, $f2, "$fn: f");
	verify_one($m, $m2, "$fn: m");

	ok($f->nelem == $f_new->nelem && $f->nelem == $f2->nelem, "$fn: correct freq counts");
}

sub verify_one
{
	my ($m, $inverse, $file) = @_;

	my $re_err = sum(($m-$inverse)->re->abs);
	my $im_err = sum(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$file: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$file: imag error ($im_err) < $tolerance");
}

