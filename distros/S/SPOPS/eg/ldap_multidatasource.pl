#!/usr/bin/perl

# $Id: ldap_multidatasource.pl,v 3.1 2004/01/10 02:49:58 lachoy Exp $

# ldap_multidatasource.pl
#   This is an example of how you can setup multiple datasources. You
#   will need to change the connection configuration information
#   located in eg/My/LDAPConnect.pm

use strict;
use Log::Log4perl;
Log::Log4perl::init( 'log4perl.conf' );
use SPOPS::Initialize;

{
    my $config = {
        user => {
          datasource   => [ 'main', 'remote' ],
          class        => 'My::LDAPUser',
          isa          => [ 'My::LDAPConnect', 'SPOPS::LDAP::MultiDatasource' ],
          field        => [ qw/ cn sn givenname displayname mail
                                telephonenumber objectclass uid ou / ],
          ldap_base_dn => 'ou=People',
          multivalue   => [ 'objectclass' ],
          id_field     => 'uid',
        },
    };

    SPOPS::Initialize->process({ config => $config });

    my $user_list = My::LDAPUser->fetch_group_all({ filter => 'givenname=User' });
    foreach my $user ( @{ $user_list } ) {
        print "I am ", $user->dn, " and I came from $user->{_datasource}\n";
    }
}
