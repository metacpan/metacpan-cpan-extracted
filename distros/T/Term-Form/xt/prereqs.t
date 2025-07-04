use 5.22.0;
use warnings;
use strict;
use Test::More;

use Test::Prereq;

prereq_ok( undef, [ qw(
        Win32::Console::ANSI

        Term::Choose::Constants
        Term::Choose::LineFold
        Term::Choose::Linux
        Term::Choose::Screen
        Term::Choose::ValidateOptions
        Term::Choose::Win32
        Term::Form
        Term::Form::ReadLine

        Data_Test_Arguments
        Data_Test_Readline
    )
] );
