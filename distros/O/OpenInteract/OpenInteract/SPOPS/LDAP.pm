package OpenInteract::SPOPS::LDAP;

# $Id: LDAP.pm,v 1.11 2002/01/02 02:43:53 lachoy Exp $

use strict;
use OpenInteract::SPOPS;

@OpenInteract::SPOPS::LDAP::ISA     = qw( OpenInteract::SPOPS );
$OpenInteract::SPOPS::LDAP::VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);


# TODO: Ensure stub is in SPOPS::LDAP for this

sub global_datasource_handle {
    my ( $self, $connect_key ) = @_;
    $connect_key ||= $self->get_connect_key();
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 1, "Trying to retrieve handle for key ($connect_key) for: ",
                               ( ref $self ) ? ref $self : $self );
    return $R->ldap( $connect_key );
}


# TODO: Ensure stub is in SPOPS::LDAP for this

sub connection_info {
    my ( $self, $connect_key ) = @_;
    $connect_key ||= $self->get_connect_key();
    return \%{ $self->global_config->{ldap_info}{ $connect_key } };
}


# TODO: Move this to SPOPS::LDAP and document

sub base_dn  {
    my ( $class, $connect_key ) = @_;
    my $partial_dn = $class->get_partial_dn( $connect_key );
    unless ( $partial_dn ) {
        die "No Base DN defined in SPOPS configuration key 'ldap_base_dn', cannot continue!\n";
    }
    my $connect_info = $class->connection_info( $connect_key );
    return join( ',', $partial_dn, $connect_info->{base_dn} );
}


# Retrieves the connect key when none is passed in

# TODO: Move this (minus the 'global_config' option) to SPOPS::LDAP
# and document

sub get_connect_key {
    my ( $class ) = @_;
    my $connect_key = $class->CONFIG->{datasource} ||
                      $class->global_config->{datasource}{default_connection_ldap} ||
                      $class->global_config->{default_connection_ldap};
    $connect_key = $connect_key->[0] if ( ref $connect_key eq 'ARRAY' );
    return $connect_key;
}

# Retrieves the 'partial dn', or the section that's prepended to the
# server's 'base DN' to identify the branch on which these objects
# live

# TODO: Move this to SPOPS::LDAP (?) and document

sub get_partial_dn {
    my ( $class, $connect_key ) = @_;
    my $base_dn_info = $class->CONFIG->{ldap_base_dn};
    return $base_dn_info unless ( ref $base_dn_info eq 'HASH' );
    $connect_key ||= $class->get_connect_key;
    return $base_dn_info->{ $connect_key };
}

1;

__END__

=pod

=head1 NAME

OpenInteract::SPOPS::LDAP - Common SPOPS::LDAP-specific methods for objects

=head1 SYNOPSIS

 # In configuration file
 'myobj' => {
    'isa'   => [ qw/ ... OpenInteract::SPOPS::LDAP ... / ],
 }

=head1 DESCRIPTION

This class provides common datasource access methods required by
L<SPOPS::LDAP>.

=head1 METHODS

B<global_datasource_handle( [ $connect_key ] )>

Returns an LDAP handle corresponding to the connection key
C<$connect_key>. If C<$connect_key> is not given, then the default
connection key is used. This is specified in the server configuration
file under the key 'default_connection_ldap'.

B<connection_info( [ $connect_key ] )>

Returns a hashref of LDAP connection information. If no
C<$connect_key> is given then we get the value of 'datasource' from
the object configuration, and if that is not defined we get the
default datasource from the server configuration.

See the server configuration file for documentation on what is in the
hashref.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::LDAP>

=head1 COPYRIGHT

Copyright (c) 2001-2002 MSN Marketing Service Nordwest, GmbH. All rights
reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
