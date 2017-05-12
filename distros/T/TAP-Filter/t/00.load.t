#!perl
use Test::More tests => 2;

BEGIN {
    use_ok( 'TAP::Filter' );
    use_ok( 'TAP::Filter::Iterator' );
}

diag(   "Testing TAP::Filter $TAP::Filter::VERSION "
      . "against TAP::Parser $TAP::Parser::VERSION" );

