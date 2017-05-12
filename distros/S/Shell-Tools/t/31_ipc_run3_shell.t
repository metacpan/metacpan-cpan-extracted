#!/usr/bin/env perl
use warnings;
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

use Test::More $HAVE_REQUIRED_EXTRAS && $HAVE_MODULE{"IPC::Run3::Shell"} ? (tests=>4)
	: (skip_all=>'need IPC::Run3::Shell and extra modules for this test');

# these tests will fail if there is no "perl" in the PATH
# but experience from IPC::Run3::Shell has shown that's extremely unlikely

use Shell::Tools::Extra  Shell => ['perl', [ foo => 'perl', '-e', 'print "foo @ARGV"' ], ':run'];

is perl('-e','print "x @ARGV y"','a >b'), 'x a >b y', 'IPC::Run3::Shell 1';
is foo('bar'), 'foo bar', 'IPC::Run3::Shell 2';
is run('perl','-e','print "foo\tbar\n"'), "foo\tbar\n", 'IPC::Run3::Shell 3';

{
	package TestingShellTools;
	use Shell::Tools::Extra  Shell => 'perl';
	use Test::More import=>['is'];
	is perl('-e','print "x y z"'), "x y z", 'IPC::Run3::Shell 4';
}

done_testing;

