#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Regexp::Parsertron; # For the version #.

use Test::More;

use Capture::Tiny;
use Data::Section::Simple;
use File::Slurper;
use Marpa::R2;
use Moo;
use Scalar::Does;
use strict;
use Tree;
use Try::Tiny;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Capture::Tiny
	Data::Section::Simple
	File::Slurper
	Marpa::R2
	Moo
	Scalar::Does
	strict
	Tree
	Try::Tiny
	Types::Standard
	warnings
/;

diag "Testing Regexp::Parsertron V $Regexp::Parsertron::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
