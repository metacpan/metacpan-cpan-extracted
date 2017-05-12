use Test::More tests => 5;
use strict;
use Data::Dump qw( dump );

SKIP: {

    unless ( $ENV{TEST_LDAP_LOADER} ) {
        skip "set TEST_LDAP_LOADER envvar to test the Loader feature", 5;
    }

    use Net::LDAP::Class;
    ok( my $ldap = Net::LDAP->new( 'ldaps://lark.dtc.umn.edu', ),
        "new ldap object" );

    $ldap or die "can't connect to LDAP: $!";

    my $base_dn;
    ok( my $dse = $ldap->root_dse, "find dse'" );
BASE: foreach my $base ( $dse->get_value('namingContexts') ) {
        my $search = $ldap->search(
            base   => $base,
            filter => '(objectclass=dcObject)',
        );
    ENTRY: foreach my $entry ( $search->entries ) {

            #$entry->dump;
            if ( !$base_dn ) {
                $base_dn = $entry->dn;
                last BASE;
            }
        }
    }

    {

        package MyLDAPClass;
        @MyLDAPClass::ISA = qw( Net::LDAP::Class );

        MyLDAPClass->metadata->setup(
            use_loader => 1,
            ldap       => $ldap,
            base_dn    => $base_dn,    #"dc=DTC",

            # could get list of object_classes like Metadata does:
            # $ldap->schema->all_objectclasses
            object_classes => [qw( posixAccount )],
        );

    }

    ok( my $nlc = MyLDAPClass->new( ldap => $ldap ), "new MyLDAPClass" );
    is( scalar( @{ $nlc->attributes } ), 9, "found attributes" );
    is( $nlc->unique_attributes->[0], 'uid', "found unique attributes" );

    #dump $nlc

}
