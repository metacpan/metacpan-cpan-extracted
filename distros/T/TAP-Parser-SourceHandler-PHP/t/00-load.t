#!perl -T

use Test::More tests => 1;

use Test::Harness;

BEGIN {
    use_ok( 'TAP::Parser::SourceHandler::PHP' ) or die;
}

diag( "Testing TAP::Parser::SourceHandler::PHP $TAP::Parser::SourceHandler::PHP::VERSION with $Test::Harness::VERSION, Perl $], $^X" );
