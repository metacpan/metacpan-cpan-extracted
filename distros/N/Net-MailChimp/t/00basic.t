use Test::More (tests => 1);
use Test::Exception;

BEGIN {
  use_ok( 'Net::MailChimp' );
}

use Net::MailChimp;

diag( "Testing Net::MailChimp $Net::MailChimp::VERSION" );

done_testing();
