use Test::More tests => 46;
use strict;

use_ok('Net::LDAP::Class');
use_ok('Net::LDAP::Class::User::AD');
use_ok('Net::LDAP::Class::Group::AD');

use lib 't/lib';
use Net::LDAP;
use Data::Dump qw( dump );
use LDAPTestAD;

ok( my $server = LDAPTestAD::spawn_server(), "spawn server" );
ok( my $ldap = Net::LDAP->new(
        LDAPTestAD::server_host(), port => LDAPTestAD::server_port()
    ),
    "connect to server"
);

{

    package MyLDAPUser;
    use base 'Net::LDAP::Class::User::AD';

    __PACKAGE__->metadata->setup(
        base_dn           => 'dc=test,dc=local',
        attributes        => __PACKAGE__->AD_attributes,
        unique_attributes => __PACKAGE__->AD_unique_attributes,
    );

    sub init_group_class {'MyLDAPGroup'}

}

{

    package MyLDAPGroup;
    use base 'Net::LDAP::Class::Group::AD';

    __PACKAGE__->metadata->setup(
        base_dn           => 'dc=test,dc=local',
        attributes        => __PACKAGE__->AD_attributes,
        unique_attributes => __PACKAGE__->AD_unique_attributes,
    );

    sub init_user_class {'MyLDAPUser'}
}

ok( $ldap->bind, "bind to server" );

ok( my $group = MyLDAPGroup->new(
        cn   => 'foogroup',
        ldap => $ldap,
    ),
    "new group"
);

ok( $group->create, "create $group" );

### Test of removing multiple users.
my $R = 3;
for my $n ( 1 .. $R ) {
    ok( my $u = MyLDAPUser->new(
            sAMAccountName => $n,
            ldap           => $ldap,
            groups         => [$group],
            cn             => $n,
        ),
        "new user $n"
    );
    ok( $u->create, "create user $u" );
}

ok( $group->read, "group update ok" );

for my $n ( 1 .. $R ) {
    ok( my $u = MyLDAPUser->new( ldap => $ldap, username => $n )->read,
        "user $n read ok" );
    ok( $group->has_user($u), "group has user $n" );
}

for my $n ( 1 .. $R ) {
    my $u = MyLDAPUser->new( ldap => $ldap, username => $n );
    ok( $group->remove_user($u), "removed user ok" );
}

ok( $group->update, "group update succeded" );

for my $n ( 1 .. $R ) {
    ok( my $u = MyLDAPUser->new( ldap => $ldap, username => $n )->read,
        "$n read ok" );
    ok( !$group->has_user($u), "group doesn't have user $n" );
}

### Test of adding multiple users.
ok( my $group2 = MyLDAPGroup->new(
        cn   => 'bargroup',
        ldap => $ldap,
    ),
    "new group2"
);

ok( $group2->create, "group2 create ok" );

for my $n ( 1 .. $R ) {
    ok( my $u = MyLDAPUser->new( ldap => $ldap, username => $n )->read,
        "user $n read ok" );
    ok( $group2->add_user($u), "added user $u ok" );
}

ok( $group2->update, "group2 update ok" );

for my $n ( 1 .. $R ) {
    ok( my $u = MyLDAPUser->new( ldap => $ldap, username => $n )->read,
        "user $n read ok" );
    ok( $group2->has_user($u), "has post-update user $u ok" );
}

