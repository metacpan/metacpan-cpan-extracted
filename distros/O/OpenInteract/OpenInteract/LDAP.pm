package OpenInteract::LDAP;

# $Id: LDAP.pm,v 1.6 2002/01/02 02:43:53 lachoy Exp $

use strict;
use Data::Dumper qw( Dumper );
use Net::LDAP    qw();

@OpenInteract::LDAP::ISA      = ();
$OpenInteract::LDAP::VERSION  = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use constant DEBUG        => 0;
use constant LDAP_PORT    => 389;
use constant LDAP_DEBUG   => 0;
use constant LDAP_TIMEOUT => 120;
use constant LDAP_VERSION => 2;

sub connect {
    my ( $class, $ldap_info, $p ) = @_;
    $p ||= {};

    # Allow callback to modify the connection info; note that we 
    # dereference $ldap_info for a reason here -- so we don't mess up the 
    # original information, say, in the config hashref

    if ( ref $p->{pre_connect} eq 'CODE' ) {
        DEBUG && _w( 1, "Before pre_connect code: ", Dumper( $ldap_info ) );
        my $new_ldap_info = $p->{pre_connect}->( \%{ $ldap_info } );
        $ldap_info = $new_ldap_info  if ( $new_ldap_info->{host} );
    }

    # Set defaults

    $ldap_info->{port}    ||= LDAP_PORT;
    $ldap_info->{debug}   ||= LDAP_DEBUG;
    $ldap_info->{timeout} ||= LDAP_TIMEOUT;
    $ldap_info->{version} ||= LDAP_VERSION;

    unless ( $ldap_info->{host} ) {
        die "Key 'host' must be defined in first hashref of parameters.\n";
    }

    # Make the actual connection

    DEBUG && _w( 1, "Trying to connect to LDAP with information:\n",
                    Dumper( $ldap_info ) );
    my $ldap = Net::LDAP->new( $ldap_info->{host},
                               timeout => $ldap_info->{timeout},
                               port    => $ldap_info->{port},
                               debug   => $ldap_info->{debug},
                               version => $ldap_info->{version} );
    unless ( $ldap ) {
        die "Connect failed: cannot create connection to LDAP directory.\n";
    }
    DEBUG && _w( 1, "New LDAP handle created ok." );

    # Allow callback to do something with the database handle along with
    # the parameters used to connect to it.

    if ( ref $p->{post_connect} eq 'CODE' ) {
        DEBUG && _w( 1, "Calling post_connect code with handle and info" );
        $p->{post_connect}->( \%{ $ldap_info }, $ldap );
    }
    return $ldap;
}

sub bind {
    my ( $class, $ldap, $ldap_info ) = @_;

    my %bind_params = ();
    if ( $ldap_info->{sasl} and $ldap_info->{bind_dn} ) {
        require Authen::SASL;
        $bind_params{sasl} = Authen::SASL->new( 'CRAM-MD5',
                                                password => $ldap_info->{bind_password} );
    }
    elsif ( $ldap_info->{bind_dn} ) {
        $bind_params{password} = $ldap_info->{bind_password};
    }

    DEBUG && _w( 1, "Calling bind() with DN ($ldap_info->{bind_dn}) and params:\n",
                    Dumper( \%bind_params ) );
    my $bind_msg = $ldap->bind( $ldap_info->{bind_dn}, %bind_params );
    if ( my $bind_code = $bind_msg->code ) {
        die "Bind failed: ", $bind_msg->error, " (Code: $bind_code)\n";
    }
    DEBUG && _w( 1, "Bind executed ok." );
    return $ldap;
}


sub connect_and_bind {
    my ( $class, $ldap_info, @params ) = @_;
    my $ldap = $class->connect( $ldap_info, @params );
    return $class->bind( $ldap, $ldap_info );
}


sub _w {
    return unless ( DEBUG >= shift );
    my ( $pkg, $file, $line ) = caller;
    my @ci = caller(1);
    warn "$ci[3] ($line) >> ", join( ' ', @_ ), "\n";
}


1;

__END__

=pod

=head1 NAME

OpenInteract::LDAP - Centralized connection location to LDAP directories

=head1 SYNOPSIS

 # Get a connection to the LDAP directory using the 'main' parameters
 # from your server configuration

 my $ldap = eval { OpenInteract::LDAP->connect( $CONFIG->{ldap_info}{main} ) };
 if ( $@ ) {
    die "Cannot connect to directory: $@";
 }

 # Bind the connection using the same parameters

 eval { OpenInteract::LDAP->bind( $ldap, $CONFIG->{ldap_info}{main} ) };
 if ( $@ ) {
    die "Cannot bind to directory: $@";
 }

 # Do both at once with the same information
 my $ldap = eval { OpenInteract::LDAP->connect_and_bind(
                                             $CONFIG->{ldap_info}{main} ) };
 if ( $@ ) {
    die "LDAP connect/bind error: $@";
 }

=head1 DESCRIPTION

Connect and/or bind to an LDAP directory.

=head1 METHODS

B<connect( \%connect_params, \%other_params )>

Parameters used:

=over 4

=item *

B<host>: host LDAP server is running on

=item *

B<port>: defaults to 389

=item *

B<debug>: see L<Net::LDAP> for what this will do

=item *

B<timeout>: defaults to 120

=item *

B<version>: defaults to 2; version of the LDAP protocol to use.

=back

Returns: valid L<Net::LDAP> connection handle, or issues a C<die>
explaining why it failed.

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

L<Net::LDAP>

=head1 COPYRIGHT

Copyright (c) 2001-2002 MSN Marketing Service Nordwest, GmbH. All rights
reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
