use 5.010000;
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

            Data_Test_Arguments Data_Test_Choose
    )
] );
