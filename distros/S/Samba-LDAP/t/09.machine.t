#!perl -w

use warnings;
use strict;
use Test::More tests =>3;

BEGIN {
        use_ok( 'Samba::LDAP::Machine');
}

my $machine = Samba::LDAP::Machine->new();
isa_ok ( $machine, 'Samba::LDAP::Machine' );
can_ok( $machine, qw( add_posix_machine add_samba_machine
add_samba_machine_smbpasswd ) );


