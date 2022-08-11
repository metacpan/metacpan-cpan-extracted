#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone;
use File::Temp qw/tempfile/;


use Test::More tests => 4;


my $datadir = 't/test-data';

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = grep { /\.s\dp$/i } readdir($dir);
closedir($dir);

foreach my $fn (@files)
{
	my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp("$datadir/$fn");
	#print $m . "\n";
	ok($f->nelem > 0 && $m->nelem > 0, "$datadir/$fn");
}
