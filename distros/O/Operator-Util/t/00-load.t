#!perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok 'Operator::Util', qw(
        reduce  reducewith
        zip     zipwith
        cross   crosswith
        hyper   hyperwith
        applyop reverseop
    );
}

diag "Testing Operator::Util $Operator::Util::VERSION, Perl $], $^X";
