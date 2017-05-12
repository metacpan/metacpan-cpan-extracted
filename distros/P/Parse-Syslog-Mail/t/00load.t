#!perl -T
use Test::More tests => 1;

BEGIN {
  use_ok( 'Parse::Syslog::Mail' );
}

diag( "Testing Parse::Syslog::Mail $Parse::Syslog::Mail::VERSION" );
