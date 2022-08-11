#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp s_to_abcd abcd_to_s /;
use File::Temp qw/tempfile/;

use Test::More tests => 8;

my $tolerance = 1e-6;

my $datadir = 't/test-data';

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = map { "$datadir/$_" } grep { /\.s2p$/i } readdir($dir);
closedir($dir);

@files = grep { !/IDEAL_OPEN/ } @files;

# real examples:
my $S = pdl [
		[
			[0.7163927 + i() * -0.4504119, 0.2836073 + i() *  0.4504119],
			[0.2836073 + i() *  0.4504119, 0.7163927 + i() * -0.4504119]
		]
	];

my $A = pdl [
		[
			[1 + i() * -1.60515694288942e-16, 0.107065112465306 + i() * -158.985376613117],
			[0 + i() *  0                   , 1                 + i() *   -1.60515694288942e-16]
		]
	];

verify_one(s_to_abcd($S, 50), $A, "(builtin)");
verify_one(abcd_to_s($A, 50), $S, "(builtin)");

foreach my $fn (@files, @ARGV)
{
	my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp($fn);

	next unless $param_type eq 'S';

	verify($m, $z0, "$fn (S->ABCD->S):", \&s_to_abcd => \&abcd_to_s);
}

sub verify
{
	my ($m, $z0, $file, $f, $f_inv) = @_;

	my $result = $f->($m, $z0);
	my $inverse = $f_inv->($result, $z0);
	
	return verify_one($m, $inverse, $file);
}

sub verify_one
{
	my ($m, $inverse, $file) = @_;

	my $re_err = sum(($m-$inverse)->re->abs);
	my $im_err = sum(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$file: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$file: imag error ($im_err) < $tolerance");
}

