#!perl -w

use warnings;
use strict;
use Test::More tests =>3;

BEGIN {
        use_ok( 'Samba::LDAP::User');
}

my $sid = Samba::LDAP::User->new();
isa_ok ( $sid, 'Samba::LDAP::User' );
can_ok( $sid, qw( is_samba_user is_unix_user is_nonldap_unix_user
is_valid_user disable_user delete_user get_homedir make_hash
change_password ) );
