use Test::More tests => 2;

BEGIN {
  use_ok( 'Set::IntSpan::Fast' );
  use_ok( 'Set::IntSpan::Fast::PP' );
}

diag( "Testing Set::IntSpan::Fast $Set::IntSpan::Fast::VERSION" );
diag( "ISA @Set::IntSpan::Fast::ISA" );
