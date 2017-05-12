#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('MooX::TaggedAttributes');
}

diag( "Testing MooX::TaggedAttributes $MooX::TaggedAttributes::VERSION, Perl $], $^X" );
