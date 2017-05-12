package Net::Icecast2::Mount;
{
  $Net::Icecast2::Mount::VERSION = '0.005';
}
# ABSTRACT: Icecast2 Server Mount API
use Moo;
use MooX::Types::MooseLike::Base qw(Str);
extends 'Net::Icecast2';

use Carp;
use Sub::Quote qw(quote_sub);
use PHP::HTTPBuildQuery qw(http_build_query);

=head1 NAME

Net::Icecast2::Mount - Icecast2 Server Mount API

=head1 SYNOPSIS

  use Net::Icecast2::Mount;

  my $icecast_mount = Net::Icecast2::Mount->new(
      host => 192.168.1.10,
      port => 8008,
      protocol => 'https',
      login    => 'source',
      password => 'hackme',
      mount    => '/my_mount.ogg',
  );

  $icecast_mount->metadata_update( song => 'New song' );
  $icecast_mount->fallback_update( '/new_fallback.ogg' );
  $icecast_mount->list_clients;
  $icecast_mount->move_client( '/new_mount_point.ogg' );
  $icecast_mount->kill_client( 23444 );
  $icecast_mount->kill_source;

=head2 DESCRIPTION

Make request for Icecast2 Server Mount API

=head1 ATTRIBUTES

=head2 host

  Description : Icecast2 Server hostname
  Default     : localhost
  Required    : 0

=cut

=head2 port

  Description : Icecast2 Server port
  Default     : 8000
  Required    : 0

=cut

=head2 protocol

  Description : Icecast2 Server protocol ( scheme )
  Default     : http
  Required    : 0

=cut

=head2 login

  Description : Icecast2 Server Mount username
  Default     : source
  Required    : 0

=cut
has '+login' => (
    required => 0,
    default  => quote_sub(q{ 'source' }),
);

=head2 password

  Description : Icecast2 Server Mount password
  Required    : 1

=cut

=head2 mount

  Description : Icecast2 Server Mountpoint
  Required    : 1

=cut
has mount    => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head1 METHODS

=head2 metadata_update

  Usage       : $icecast_mount->metadata_update( song => 'New song' );
  Arguments   : List or HashRef of data parameters must update

  Description : This function provides the ability for either a source client
                or any external program to update the metadata information for
                a particular mountpoint.

=cut
sub metadata_update {
    my $self = shift;
    my %data = ( ref $_[0] eq 'HashRef' ? %{$_[0]} : @_ );

    scalar %data or print STDERR 'Updating with empty metadata';

    $self->_make_request( '/metadata', mode  => 'updinfo', %data );
}

=head2 fallback_update

  Usage       : $icecast_mount->fallback_update( '/new_fallback.ogg' );
  Arguments   : New fallback mount point

  Description : This function provides the ability for either a source client
                or any external program to update the "fallback mountpoint"
                for a particular mountpoint. Fallback mounts are those that are
                used in the even of a source client disconnection. If a source
                client disconnects for some reason that all currently connected
                clients are sent immediately to the fallback mountpoint.

=cut
sub fallback_update {
    my $self     = shift;
    my $fallback = shift;

    defined $fallback or croak 'Fallback must be defined';

    $self->_make_request( '/fallbacks', fallback => $fallback );
}

=head2 list_clients

  Usage       : $icecast_mount->list_clients;
  Arguments   : No Arguments

  Description : This function lists all the clients currently connected to a
                specific mountpoint. The results are sent back in XML form.

  Return      : HashRef like
                  mount => mount point
                  listeners => listeners number
                  listener => Array with info per each listener

=cut
sub list_clients {
    my $self = shift;

    $self->_make_request( '/listclients' );
}

=head2 move_clients

  Usage       : $icecast_mount->move_client( '/new_mount_point.ogg' );
  Arguments   : New mount point

  Description : This function provides the ability to migrate currently
                connected listeners from one mountpoint to another. This
                function requires 2 mountpoints to be passed in: mount
                (the *from* mountpoint) and destination (the *to* mountpoint).
                After processing this function all currently connected
                listeners on mount will be connected to destination. Note that
                the destination mountpoint must exist and have a sounce client
                already feeding it a stream.

  Return      : 1 on success and 0 on failure

=cut
sub move_clients {
    my $self      = shift;
    my $new_mount = shift;

    defined $new_mount or croak 'Destination mount should be defined';

    $self->_make_request( '/moveclients', ( destination => $new_mount ) );
}

=head2 kill_client

  Usage       : $icecast_mount->kill_client( 23444 );
  Arguments   : User ID can get from 'list_client' method

  Description : This function provides the ability to disconnect a specific
                listener of a currently connected mountpoint. Listeners are
                identified by a unique id that can be retrieved by via the
                "List Clients" admin function. This id must be passed in to
                the request. After processing this request, the listener will
                no longer be connected to the mountpoint.

  Return      : 1 on success and 0 on failure

=cut

sub kill_client {
    my $self      = shift;
    my $client_id = shift;

    defined $client_id or croak "Clinet ID should be defined";

    $self->_make_request( '/killclient', id => $client_id );
}

=head2 kill_source

  Usage       : $icecast_mount->kill_source;
  Arguments   : No Argements

  Description : This function will provide the ability to disconnect a specific
                mountpoint from the server. The mountpoint to be disconnected is
                specified via the variable "mount".

=cut
sub kill_source {
    my $self = shift;

    $self->_make_request( '/killsource' );
}

# Arguments   : Request path and GET method data
# Description : Private method for build correct GET request to mount point API
# Return      : XML Parsed data from server
sub _make_request {
    my $self      = shift;
    my $path      = shift;

    defined $path or croak "Request path should be defined";

    my %data      = ( @_, mount => $self->mount );
    my $full_path = $path .'?'. http_build_query( \%data );

    $self->request( $full_path );
}

no Moo;
__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Icecast2 server: http://www.icecast.org
Icecast2 API Docs: http://www.icecast.org/docs/icecast-trunk/icecast2_admin.html

Related modules L<Net::Icecast2> L<Net::Icecast2::Admin>

=head1 AUTHOR

Pavel R3VoLuT1OneR Zhytomirsky <r3volut1oner@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Pavel R3VoLuT1OneR Zhytomirsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

