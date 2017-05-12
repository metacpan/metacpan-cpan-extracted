#!perl -T

use Test::Most tests => 3, 'bail';

BEGIN {
    use_ok('Pod::Parser::Groffmom');
    use_ok('Pod::Parser::Groffmom::Color');
    use_ok('Pod::Parser::Groffmom::Entities');
}

diag(
    "Testing Pod::Parser::Groffmom $Pod::Parser::Groffmom::VERSION, Perl $], $^X"
);
