#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok('SWISH::Prog::Lucy');
    use_ok('Lucy');
}

diag(
    join( ' ',
        "Testing SWISH::Prog::Lucy $SWISH::Prog::Lucy::VERSION",
        "Lucy $Lucy::VERSION",
        ", Perl $], $^X" )
);
