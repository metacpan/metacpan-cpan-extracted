#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok('SWISH::Prog::KSx');
    use_ok('KinoSearch');
}

diag(
    join( ' ',
        "Testing SWISH::Prog::KSx $SWISH::Prog::KSx::VERSION",
        "KinoSearch $KinoSearch::VERSION",
        ", Perl $], $^X" )
);
