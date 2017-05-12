#!perl -w

use warnings;
use strict;
use Test::More tests =>4;

BEGIN {
        use_ok( 'Samba::LDAP');
}

my $sid = Samba::LDAP->new();
isa_ok ( $sid, 'Samba::LDAP' );
can_ok( $sid, qw( get_local_sid ) );

SKIP: {

    skip 'Samba is already set up as a PDC, can not test for unconfigured PDC', 
    1 if $sid->get_local_sid() ne 'Can not find SID';
    
    is ( $sid->get_local_sid(), 'Can not find SID', 'Test for unconfigured PDC' );

}
