#!perl -T

use strict;
use warnings;

use Test::More;
use Net::BrowserID::Verify qw(verify_remotely);

diag( "Testing exported functions are exported" );

# check we can see verify_remotely
can_ok(__PACKAGE__, 'verify_remotely');

# when we add local verification
#TODO: {
#    can_ok(__PACKAGE__, 'verify_locally');
#}

done_testing();
