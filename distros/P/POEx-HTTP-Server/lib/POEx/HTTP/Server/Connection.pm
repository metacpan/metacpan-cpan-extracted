# $Id: Connection.pm 716 2010-12-17 16:29:05Z fil $
# Copyright 2010 Philip Gwyn
package POEx::HTTP::Server::Connection;

use strict;
use warnings;
use Socket;

use Scalar::Util qw( blessed );

sub new
{
    my( $package, $ID, $socket ) = @_;
    my $self = bless {ID=>$ID}, shift;
    $self->__socket( $socket );
    return $self;
}

sub __socket
{
    my( $self, $socket ) = @_;

    my $peername = getpeername( $socket );
    my $sockname = getsockname( $socket );

    my @in = sockaddr_in($peername);
    $self->{remote_addr} = $in[1];
    $self->{remote_ip} = inet_ntoa( $self->{remote_addr} );
    $self->{remote_port} = $in[0];

    @in = sockaddr_in($sockname);
    $self->{local_addr} = $in[1];
    $self->{local_ip} = inet_ntoa($self->{local_addr});
    $self->{local_port} = $in[0];
}

######################################
sub ID        { $_[0]->{ID} }

sub remote_addr { $_[0]->{remote_addr} }
sub peeraddr    { $_[0]->{remote_addr} }
sub remote_host { $_[0]->{remote_ip} }
sub peerhost    { $_[0]->{remote_ip} }
sub remote_ip   { $_[0]->{remote_ip} }
sub remote_port { $_[0]->{remote_port} }
sub peerport    { $_[0]->{remote_port} }

sub local_addr  { $_[0]->{local_addr} }
sub hostaddr    { $_[0]->{local_addr} }
sub local_host  { $_[0]->{local_ip} }
sub hosthost    { $_[0]->{local_ip} }
sub local_ip    { $_[0]->{local_ip} }
sub local_port  { $_[0]->{local_port} }
sub hostport    { $_[0]->{local_port} }


######################################
sub user {
    my $self = @_;
    my $rv = $self->{user};
    if (@_ == 2) { $self->{user} = $_[1] }
    return $rv;
}

sub authtype {
    my $self = @_;
    my $rv = $self->{authtype};
    if (@_ == 2) { $self->{authtype} = $_[1] }
    return $rv;
}
 
sub aborted {
    return $_[0]->{aborted};
}
 
sub fileno {
    return 0;
}
 
sub clone {
    my $self = @_;
    my $new = bless { %$self };
    return $new;
}
 
 
1;

__END__

=head1 NAME

POEx::HTTP::Server::Connection - Object encapsulating an HTTP connection

=head1 SYNOPSIS

    use POEx::HTTP::Server;

    POEx::HTTP::Server->spawn( handler => 'poe:my-alias/handler' );

    # events of session my-alias:
    sub handler {
        my( $heap, $req, $resp ) = @_[HEAP,ARG0,ARG1];

        my $c = $req->connection;
        warn "Request to ", $c->local_addr, ":", $c->local_port;
        warn "Request from ", $c->remote_addr, ":", $c->remote_port;
    }


=head1 DESCRIPTION

=head1 METHODS


=head2 ID

A unique ID for this browser connection.

=head2 remote_addr

=head2 peeraddr

Return the address part of the sockaddr structure for the socket on
the peer host.

=head2 remote_host

=head2 remote_ip

=head2 peerhost

Return the address part of the sockaddr structure for the socket on
the peer host in a text form xx.xx.xx.xx.


=head2 remote_port

=head2 peerport

Return the port number for the socket on the peer host.


=head2 local_addr

=head2 hostaddr

Return the port number that the socket is using on the local host.

=head2 local_host

=head2 hosthost

=head2 local_ip

Return the local address part of the sockaddr structure for the socket in
a text form xx.xx.xx.xx.

=head2 local_port

=head2 hostport

Return the port number that the socket is using on the local host.

=head1 SEE ALSO

L<POEx::HTTP::Server>, L<POEx::HTTP::Server::Response>.


=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
