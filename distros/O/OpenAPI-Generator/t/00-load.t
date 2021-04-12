#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
  use_ok( 'OpenAPI::Generator' ) || print "Bail out!\n";

  for (qw(From::Pod From::Definitions Util)) {
    use_ok("OpenAPI::Generator::$_") || print "Bail out!\n"
  }
}

diag( "Testing OpenAPI::Generator $OpenAPI::Generator::VERSION, Perl $], $^X" );
