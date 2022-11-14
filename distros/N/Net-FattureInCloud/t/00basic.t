use Test::More (tests => 1);
use Test::Exception;

BEGIN {
  use_ok( 'Net::FattureInCloud' );
}

use Net::FattureInCloud;

diag( "Testing Net::FattureInCloud $Net::FattureInCloud::VERSION" );

done_testing();
