use 5.10.1;
use warnings;
use strict;

use Test::More;
use Test::Prereq;
prereq_ok( undef, [
    'Term::Choose::Constants',
    'Term::Choose::LineFold',
    'Term::Choose::Linux',
    'Term::Choose::Screen',
    'Term::Choose::ValidateOptions',
    'Term::Choose::Win32'
] );
