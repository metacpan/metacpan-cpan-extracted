#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp s_to_z z_to_s /;
use File::Temp qw/tempfile/;

use Test::More tests => 8;

my $tolerance = 1e-6;

my $datadir = 't/test-data';

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = map { "$datadir/$_" } grep { /\.s\d+p$/i } readdir($dir);
closedir($dir);

@files = grep { !/IDEAL_OPEN|IDEAL_SHORT/ } @files;

my $S = pdl [
    [
      [-0.00905768436807254 + i() *-0.339113546247171, -0.00126603635690153 + i() * 0.00115240842944411],
      [-4.87606117131843    + i() * 0.319593934067137, -0.158119297347863   + i() *-0.221266389928615]
    ]
  ];

my $Z = pdl [
    [
      [38.9972399072556 + i() *-30.5507338909623, -0.0420545946995648 + i() *0.129990734111929],
      [-325.140618399695 + i() *215.308489140597, 33.3391976155373 + i() *-16.4814165554864]
    ]
  ];


verify_one(s_to_z($S, 50), $Z, "(builtin)");
verify_one(z_to_s($Z, 50), $S, "(builtin)");

foreach my $fn (@files, @ARGV)
{
	my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp($fn);

	next unless $param_type eq 'S';

	verify($m, $z0, "$fn (S->Z->S):", \&s_to_z => \&z_to_s);
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

