#!/usr/bin/perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'String::Clean' );
   can_ok('String::Clean', qw{
      replace
      replace_word
      strip
      strip_word
      clean_by_yaml
   });

}

diag( "Testing String::Clean $String::Clean::VERSION, Perl $], $^X" );
