#!/usr/bin/env perl
#
# This file is part of Padre::Plugin::ShellCommand
# 

use Test::More tests => 2;
use Padre;
use Padre::Plugin::Shell::Base;

diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();

BEGIN {
    use_ok( 'Padre::Plugin::Shell::Command' );
    use_ok( 'Padre::Plugin::ShellCommand' );
}

diag( "Testing Padre::Plugin::ShellCommand $Padre::Plugin::ShellCommand::VERSION, Perl $], $^X" );
