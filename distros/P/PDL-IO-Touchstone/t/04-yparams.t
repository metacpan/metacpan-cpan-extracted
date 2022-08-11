#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp s_to_y y_to_s /;
use File::Temp qw/tempfile/;

use Test::More tests => 10;

# Cumulative error in PDL-to-perl-scalar conversion for long-double builds
# requires a lower tolerance.  To prevent failing builds just because of
# floating point error we define a tolerance target and use it below.  Note
# that normal perl builds work at 1e-9, and longdouble builds work at 1e-8 so
# 1e-6 should certainly be safe.  Also 1e-6 is recommended by the PDL
# maintainers.
#
# See here: https://github.com/PDLPorters/pdl/issues/405
# and here: https://github.com/ebaudrez/Test-PDL/wiki/Rationale:-tolerances

my $tolerance = 1e-6;

my $datadir = 't/test-data';

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = grep { /\.s\d+p$/i } readdir($dir);
closedir($dir);

@files = grep { !/IDEAL_SHORT/ } @files;

# real examples:
my $S = pdl [
    [
      [0.7163927 + i() * -0.4504119, 0.2836073 + i() *  0.4504119],
      [0.2836073 + i() *  0.4504119, 0.7163927 + i() * -0.4504119]
    ]
  ];

my $Y = pdl [
    [
      [4.23578024552791e-06  + i() *  0.00628988381069261, -4.23578024552726e-06 + i() *-0.00628988381069261],
      [-4.23578024552791e-06 + i() * -0.00628988381069261,  4.23578024552726e-06 + i() * 0.00628988381069261]
    ]
  ];

verify_one(s_to_y($S, 50), $Y, "(builtin)");
verify_one(y_to_s($Y, 50), $S, "(builtin)");

foreach my $fn (@files)
{
	my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp("$datadir/$fn");

	next unless $param_type eq 'S';

	verify($m, $z0, "$fn (S->Y->S):", \&s_to_y => \&y_to_s);
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

