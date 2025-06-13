use 5.22.0;
use warnings;
use strict;

use Test::More;
use Test::Prereq;


prereq_ok( undef, [
    qw(
        Term::Choose::LineFold::XS
    )
] );
