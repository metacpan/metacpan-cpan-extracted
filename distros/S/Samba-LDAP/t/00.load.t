#!perl -w

use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
use_ok( 'Samba::LDAP' );
}

diag( "Testing Samba::LDAP $Samba::LDAP::VERSION" );
