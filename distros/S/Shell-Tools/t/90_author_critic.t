#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

# Tests for the Perl module Shell::Tools
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Shell_Tools_Testlib;

use File::Spec::Functions qw/catfile/;
our @PERLFILES;
BEGIN {
	@PERLFILES = (
		catfile($FindBin::Bin,qw/ .. lib Shell Tools.pm /),
		catfile($FindBin::Bin,qw/ .. lib Shell Tools Extra.pm /),
		glob("$FindBin::Bin/*.t"),
		glob("$FindBin::Bin/*.pm"),
		glob("$FindBin::Bin/*.pl"),
		catfile($FindBin::Bin,qw/ .. examples follow /),
	);
}

use Test::More $AUTHOR_TESTS ? (tests=>1*@PERLFILES)
	: (skip_all=>'author Perl::Critic tests (set $ENV{SHELL_TOOLS_AUTHOR_TESTS} to enable)');

use Test::Perl::Critic -profile=>catfile($FindBin::Bin,'perlcriticrc');

critic_ok($_) for @PERLFILES;

