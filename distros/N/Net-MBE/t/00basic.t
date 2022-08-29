use Test::More (tests => 1);
use Test::Exception;

BEGIN {
  use_ok( 'Net::MBE' );
}

use Net::MBE;

diag( "Testing Net::MBE $Net::MBE::VERSION" );

done_testing();
