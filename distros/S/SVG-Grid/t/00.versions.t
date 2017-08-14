#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use SVG::Grid; # For the version #.

use Test::More;

use File::Slurper;
use Getopt::Long;
use Moo;
use Pod::Usage;
use strict;
use SVG;
use Types::Standard;
use utf8;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	File::Slurper
	Getopt::Long
	Moo
	Pod::Usage
	strict
	SVG
	Types::Standard
	utf8
	warnings
/;

diag "Testing SVG::Grid V $SVG::Grid::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
