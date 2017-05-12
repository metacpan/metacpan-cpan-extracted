package Net::Icecast2::Admin;
{
  $Net::Icecast2::Admin::VERSION = '0.005';
}
# ABSTRACT: Icecast2 Server Admin API
use Moo;
extends 'Net::Icecast2';

=head1 NAME

Net::Icecast2::Admin - Icecast2 Server Admin API

=head1 SYNOPSIS

  use Net::Icecast2::Admin;

  my $icecast_admin = Net::Icecast2::Admin->new(
      host => 192.168.1.10,
      port => 8008,
      protocol => 'https',
      login    => 'source',
      password => 'hackme',
  );

  $icecast_admin->stats;
  $icecast_admin->list_mount;

=head2 DESCRIPTION

Make request for Icecast2 Server Admin API

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

  Description : Icecast2 Server Admin login
  Required    : 1

=cut

=head2 password

  Description : Icecast2 Server Admin password
  Required    : 1

=cut

=head1 METHODS

=head2 stats

  Usage        : $icecast_admin->stats
  Description  : This admin function provides the ability to query the internal
                 statistics kept by the icecast server. Almost all information
                 about the internal workings of the server such as the
                 mountpoints connected, how many client requests have been
                 served, how many listeners for each mountpoint, etc, are
                 available via this admin function.

=cut
sub stats {
    my $self = shift;

    $self->request( '/stats' );
}

=head2 list_mounts

  Usage       : $icecast_admin->list_mounts
  Description : This admin function provides the ability to view all the
                currently connected mountpoints.

=cut
sub list_mounts {
    my $self = shift;

    $self->request( '/listmounts' )->{source};
}

no Moo;
__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Icecast2 server: http://www.icecast.org
Icecast2 API Docs: http://www.icecast.org/docs/icecast-trunk/icecast2_admin.html

Related modules L<Net::Icecast2> L<Net::Icecast2::Mount>

=head1 AUTHOR

Pavel R3VoLuT1OneR Zhytomirsky <r3volut1oner@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Pavel R3VoLuT1OneR Zhytomirsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

