package My::LDAPConnect;

# $Id: LDAPConnect.pm,v 3.0 2002/08/28 01:16:32 lachoy Exp $

# Simple LDAP connection manager -- change %DATASOURCE as needed for testing

use strict;
use Carp qw( cluck );

$My::LDAPConnect::VERSION = sprintf("%d.%02d", q$Revision: 3.0 $ =~ /(\d+)\.(\d+)/);

my %HANDLES = ();

my %DATASOURCE = (
   main   => { host    => 'localhost',
               base_dn => 'dc=mycompany,dc=com' },
   remote => { host    => 'localhost',
               port    => 3890,
               base_dn => 'dc=mycompany,dc=com' },
);

sub connection_info {
    my ( $class, $connect_key ) = @_;
    return \%{ $DATASOURCE{ $connect_key } };
}


sub global_datasource_handle {
    my ( $class, $connect_key ) = @_;
    cluck "Cannot retrieve handle without connect key!\n" unless ( $connect_key );

    unless ( $HANDLES{ $connect_key } ) {
        my $ldap_info = $class->connection_info( $connect_key );
        $ldap_info->{port} ||= 389;
        my $ldap = Net::LDAP->new( $ldap_info->{host},
                                   port => $ldap_info->{port} );
        unless ( $ldap ) { SPOPS::Exception->throw( "Cannot create LDAP connection: [$@]" ) }
        my ( %bind_params );
        if ( $ldap_info->{bind_dn} ) {
            $bind_params{dn}       = $ldap_info->{bind_dn};
            $bind_params{password} = $ldap_info->{bind_password};
        }
        my $bind_msg = $ldap->bind( %bind_params );
        if ( my $code = $bind_msg->code ) {
            SPOPS::Exception::LDAP->throw(
                              "Cannot bind to directory: " . $bind_msg->error,
                              { code => $code, action => 'global_datasource_handle' } );
        }
        $HANDLES{ $connect_key } = $ldap;
    }
    return $HANDLES{ $connect_key };
}

1;
