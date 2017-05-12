#!perl -w

use warnings;
use strict;
use Test::More tests =>4;

BEGIN {
        use_ok( 'Samba::LDAP');
}

my $version = Samba::LDAP->new();
isa_ok ( $version, 'Samba::LDAP' );
can_ok( $version, qw( module_version ) );

is ( $version->module_version(), '0.05', 'Samba::LDAP version is currently
0.05' );
