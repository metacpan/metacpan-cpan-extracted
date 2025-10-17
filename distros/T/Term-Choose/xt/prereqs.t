use 5.22.0;
use warnings;
use strict;

use Test::More;
use Test::Prereq;

prereq_ok( undef, [
    qw(     Term::ReadKey
            Encode
            Encode::Locale
            Win32::Console
            Win32::Console::ANSI
            Win32::Console::PatchForRT33513

            Term::Choose
            Term::Choose::LineFold::PP

            Term::Form::ReadLine

            Data_Test_Arguments Data_Test_Choose
    )
] );
