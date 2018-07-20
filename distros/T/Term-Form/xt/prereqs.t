use 5.010000;
use warnings;
use strict;
use Test::More;

use Test::Prereq;

prereq_ok( undef, [ qw( constant Encode Encode::Locale Term::ReadKey Win32::Console Data_Test_Arguments Data_Test_Readline ) ] );
