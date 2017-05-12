use Test::More tests => 1;

BEGIN {
  use_ok( 'Set::IntSpan::Fast::XS' );
}

diag(
  "Testing Set::IntSpan::Fast::XS $Set::IntSpan::Fast::XS::VERSION" );
diag( "ISA @Set::IntSpan::Fast::XS::ISA" );
