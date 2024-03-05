use Test::More (tests => 1);
use Test::Exception;

BEGIN {
  use_ok( 'Net::PaccoFacile' );
}

use Net::PaccoFacile;

diag( "Testing Net::PaccoFacile $Net::PaccoFacile::VERSION" );

done_testing();
