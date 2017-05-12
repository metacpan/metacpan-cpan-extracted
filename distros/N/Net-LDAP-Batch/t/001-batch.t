use Test::More tests => 4;
use strict;

use_ok('Net::LDAP::Batch');

use Net::LDAP;
use Net::LDAP::Entry;
use Net::LDAP::Server::Test;

my $BaseDN = 'ou=People,dc=MyDomain';
my $server = Net::LDAP::Server::Test->new( 10636, auto_schema => 1 );
my $ldap   = Net::LDAP->new( '127.0.0.1', port => 10636 );

ok( my $batch = Net::LDAP::Batch->new( ldap => $ldap ), "new batch" );

ok( $batch->add_actions(
        add => [
            {   dn   => "cn=MyGroup,ou=Group,$BaseDN",
                attr => [
                    objectClass => [ 'top', 'posixGroup' ],
                    cn          => 'MyGroup',
                    gidNumber   => '1234',
                    foo         => [ 'bar', 'baz' ],
                ]
            }
        ],

        update => [
            {   search => [
                    base   => "ou=Group,$BaseDN",
                    scope  => 'sub',
                    filter => "(cn=MyGroup)"
                ],
                replace => { gidNumber => '5678' },
                delete  => { foo       => ['bar'] },
            }
        ],

        delete => [
            {   search => [
                    base   => "ou=Group,$BaseDN",
                    scope  => 'sub',
                    filter => "(cn=MyGroup)"
                ]
            }
        ],

    ),
    "add actions"
);

ok( $batch->do, " do batch" );
