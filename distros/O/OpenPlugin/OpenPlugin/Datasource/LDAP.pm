package OpenPlugin::Datasource::LDAP;

# $Id: LDAP.pm,v 1.14 2003/04/03 01:51:25 andreychek Exp $

use strict;
use Data::Dumper  qw( Dumper );
use Net::LDAP     qw();

@OpenPlugin::Datasource::LDAP::ISA      = ();
$OpenPlugin::Datasource::LDAP::VERSION  = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);

use constant LDAP_PORT    => 389;
use constant LDAP_DEBUG   => 0;
use constant LDAP_TIMEOUT => 120;
use constant LDAP_VERSION => 2;

sub connect {
    my ( $class, $OP, $ds_name, $ds_info ) = @_;

    unless ( ref $ds_info ) {
        die ( "Cannot create connection without datasource info!" );
    }

    unless ( $ds_name ) {
        $OP->log->warn( 'WARNING: Correct usage of connect() is' .
               '$class->connect( $ds_name, \%ds_info ). Will continue...' );
    }

    unless ( $ds_info->{host} ) {
        $OP->exception->throw( "Key 'host' must be defined in first " .
                                     "hashref of parameters." );
    }

    # Set defaults
    $ds_info->{port}    ||= LDAP_PORT;
    $ds_info->{debug}   ||= LDAP_DEBUG;
    $ds_info->{timeout} ||= LDAP_TIMEOUT;
    $ds_info->{version} ||= LDAP_VERSION;

    if( $OP->log->is_info ) {
        $OP->log->info( "Trying to connect to LDAP with information:\n",
                               Dumper( $ds_info ) );
    }

    my $ldap = Net::LDAP->new( $ds_info->{host},
                               timeout => $ds_info->{timeout},
                               port    => $ds_info->{port},
                               debug   => $ds_info->{debug},
                               version => $ds_info->{version} );

    unless ( $ldap ) {
        die ( "Connect failed: cannot create connection to LDAP directory." );
    }

    $OP->log->info( "New LDAP handle created ok." );

    if ( $ds_info->{perform_bind} ) {
        return $class->bind( $OP, $ldap, $ds_info );
    }

    return $ldap;
}


sub bind {
    my ( $self, $OP, $ldap, $ds_info ) = @_;

    my %bind_params = ();
    if ( $ds_info->{sasl} and $ds_info->{bind_dn} ) {
        eval { require Authen::SASL };
        if ( $@ ) {
            $OP->exception->throw( "You requested SASL authentication, " .
                              "but Authen::SASL could not be loaded: ($@)" );
        }

        $bind_params{sasl} = Authen::SASL->new( 'CRAM-MD5',
                                        password => $ds_info->{bind_password} );
    }
    elsif ( $ds_info->{bind_dn} ) {
        $bind_params{password} = $ds_info->{bind_password};
    }

    if( $OP->log->is_info ) {
        $OP->log->info(
                "Calling bind() with DN ($ds_info->{bind_dn}) and params:\n",
                 Dumper( \%bind_params ) );
    }
    my $bind_msg = $ldap->bind( $ds_info->{bind_dn}, %bind_params );

    if ( my $bind_code = $bind_msg->code ) {
        $OP->exception->throw( "Bind failed: " . $bind_msg->error .
                                     " (Code: $bind_code)" );
    }
    $OP->log->info( "Bind executed ok." );
    return $ldap;
}


sub connect_and_bind {
    my ( $self, $ds_info, @params ) = @_;
    my $ldap = $self->connect( $ds_info, @params );
    return $self->bind( $ldap, $ds_info );
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Datasource::LDAP - Centralized connection location to LDAP directories

=head1 SYNOPSIS

 # Define the parameters for an LDAP connection called 'primary'

 <datasource primary>
    type          = LDAP
    host          = localhost
    port          = 389
    base_dn       = dc=mycompany, dc=com
    timeout       = 120
    version       = 2
    sasl          =
    debug         =
    bind_dn       = cn=webuser, ou=People, dc=mycompany, dc=com
    bind_password = urkelnut
    perform_bind  = yes
 </datasource>

 # Request the datasource 'primary' from the $OP object

 my $ldap = $OP->datasource->connect( 'primary' );
 my $mesg =  $ldap->search( "urkelFan=yes" );
 ...

=head1 DESCRIPTION

Connect and/or bind to an LDAP directory.

=head1 METHODS

B<connect( $datasource_name, \%datasource_info )>

Parameters used in C<\%datsource_info>

=over 4

=item *

B<host>: host LDAP server is running on

=item *

B<port>: defaults to 389

=item *

B<debug>: see L<Net::LDAP|Net::LDAP> for what this will do

=item *

B<timeout>: defaults to 120

=item *

B<version>: defaults to 2; version of the LDAP protocol to use.

=item *

B<perform_bind>: if true, we perform a bind (using 'bind_dn' and
'bind_password') when we connect to the LDAP directory

=item *

B<bind_dn>: DN to bind with (if requested to bind)

=item *

B<bind_password>: password to bind with (if requested to bind)

=item *

B<sasl>: if true, use SASL when binding (if requested to bind)

=back

Returns:

If success, a valid L<Net::LDAP|Net::LDAP> connection handle is returned.

Failure will cause an exception to be thrown.

B<bind( $ldap_connection, \%bind_params )>

Bind an LDAP connection using a DN/password combination. With many
servers, you can do this more than once with a single connection.

Parameters used:

=over 4

=item *

B<bind_dn>: DN to bind as.

=item *

B<bind_password>: Password to use when binding.

=item *

B<sasl>: If set to true, use SASL for authentication. Note: this is
completely untested, and even if it works it only uses the C<CRAM-MD5>
method of authentication.

=back

Returns: LDAP handle with bind() run, or calls C<die> to explain why
it failed.

B<connect_and_bind( \%connect_params, \%other_params )>

Run both the C<connect()> and C<bind()> methods.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<Net::LDAP|Net::LDAP>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

Chris Winters <chris@cwinters.com>

=cut
