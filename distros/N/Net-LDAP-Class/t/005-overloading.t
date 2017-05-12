use Test::More tests => 11;
use strict;

use_ok('Net::LDAP::Class');
use_ok('Net::LDAP::Class::User::POSIX');
use_ok('Net::LDAP::Class::Group::POSIX');

use lib 't/lib';
use Net::LDAP;
use Data::Dump qw( dump );
use LDAPTestPOSIX;

ok( my $server = LDAPTestPOSIX::spawn_server(), "spawn server" );
ok( my $ldap = Net::LDAP->new(
        LDAPTestPOSIX::server_host(),
        port => LDAPTestPOSIX::server_port()
    ),
    "connect to server"
);

{

    package MyLDAPUser;
    use base 'Net::LDAP::Class::User::POSIX';

    __PACKAGE__->metadata->setup(
        base_dn           => 'dc=test,dc=local',
        attributes        => __PACKAGE__->POSIX_attributes,
        unique_attributes => __PACKAGE__->POSIX_unique_attributes,
    );

    sub init_group_class {'MyLDAPGroup'}

    sub init_ldap { return $ldap }

}

{

    package MyLDAPGroup;
    use base 'Net::LDAP::Class::Group::POSIX';

    __PACKAGE__->metadata->setup(
        base_dn           => 'dc=test,dc=local',
        attributes        => __PACKAGE__->POSIX_attributes,
        unique_attributes => __PACKAGE__->POSIX_unique_attributes,
    );

    sub init_user_class {'MyLDAPUser'}

    sub init_ldap { return $ldap }
}

ok( $ldap->bind, "bind to server" );

ok( my $group = MyLDAPGroup->new(
        gidNumber => 1000,
        cn        => 'foogroup',
        ldap      => $ldap,
    ),
    "new group"
);

ok( defined $group->cn(''), "set stringified value to empty string" );
ok( $group,                 "group still evaluates true" );
if ($group) {
    ok( 1, "group evaluates true in if" );
}
else {
    ok( 0, "group evaluates true in if" );
}

ok( $ldap->unbind(), 'unbind $ldap object from server' );
