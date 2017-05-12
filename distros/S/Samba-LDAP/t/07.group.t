#!perl -w

use warnings;
use strict;
use Test::More tests =>3;

BEGIN {
        use_ok( 'Samba::LDAP::Group');
}

my $group = Samba::LDAP::Group->new();
isa_ok ( $group, 'Samba::LDAP::Group' );
can_ok( $group, qw( is_group_member add_group
add_to_group add_to_groups delete_group find_groups read_group_entry
read_group_entry_gid parse_group remove_from_group list_groups ) );


