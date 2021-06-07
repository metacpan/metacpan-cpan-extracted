use strict;
use Test::More;

package    # Hide from pause
    Net::Dropbear::Test002_1
{
  use Test::More;
  use Net::Dropbear::XS qw/HOOK_COMPLETE HOOK_CONTINUE HOOK_FAILURE/;

  is( HOOK_COMPLETE, Net::Dropbear::XS::HOOK_COMPLETE, 'HOOK_COMPLETE was exported correctly' );
  is( HOOK_CONTINUE, Net::Dropbear::XS::HOOK_CONTINUE, 'HOOK_CONTINUE was exported correctly' );
  is( HOOK_FAILURE,  Net::Dropbear::XS::HOOK_FAILURE,  'HOOK_FAAILURE was exported correctly' );
}

# Make sure it also works in SSHd since we claim it does
package    # Hide from pause
    Net::Dropbear::Test002_2
{
  use Test::More;
  use Net::Dropbear::SSHd qw/HOOK_COMPLETE HOOK_CONTINUE HOOK_FAILURE/;
  is( HOOK_COMPLETE, Net::Dropbear::XS::HOOK_COMPLETE, 'HOOK_COMPLETE was exported correctly' );
  is( HOOK_CONTINUE, Net::Dropbear::XS::HOOK_CONTINUE, 'HOOK_CONTINUE was exported correctly' );
  is( HOOK_FAILURE,  Net::Dropbear::XS::HOOK_FAILURE,  'HOOK_FAAILURE was exported correctly' );
}

done_testing;
