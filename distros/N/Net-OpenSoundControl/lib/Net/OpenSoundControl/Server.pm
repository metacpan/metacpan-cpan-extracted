package Net::OpenSoundControl::Server;

use 5.006;
use strict;
use warnings;
use IO::Socket;
use Net::OpenSoundControl;

our @ISA = qw();

our $VERSION = '0.02';

=head1 NAME

Net::OpenSoundControl::Server - OpenSound Control server implementation

=head1 SYNOPSIS

  use Net::OpenSoundControl::Server;
  use Data::Dumper qw(Dumper);

  sub dumpmsg {
      my ($sender, $message) = @_;
      
      print "[$sender] ", Dumper $message;
  }

  my $server = Net::OpenSoundControl::Server->new(
      Port => 7777, Handler => \&dumpmsg) or
      die "Could not start server: $@\n";

  $server->readloop();

=head1 DESCRIPTION

This module implements an OSC server (right now, blocking and not-yet multithreaded...) receiving messages via UDP.
Once a message is received, the server calls a handler
routine. The handler receives the host name of the sender as well as the (decoded) OSC message or bundle.

=head1 METHODS

=over

=item new(Port => $port, Name => $name, Handler => \&handler)

Creates a new server object. Default port is 7123, default name is
C<Net-OpenSoundControl-Server:7123>, default handler is undef.

Returns undef on failure (in this case, $@ is set).

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    my $self  = {};

    $self->{PORT} = $opts{Port} || 7123;
    $self->{NAME} = $opts{Name}
      || 'Net-OpenSoundControl-Server:' . $self->{PORT};
    $self->{HANDLER} = $opts{Handler} || undef;

    $self->{SOCKET} = IO::Socket::INET->new(
        LocalPort => $self->{PORT},
        Proto     => 'udp')
      or return undef;    # error is in $@

    bless $self, $class;
}

=item name()

Returns the name of the server

=cut

sub name {
    my $self = shift;

    return $self->{NAME};
}

=item port()

Returns the port the server is listening at

=cut

sub port {
    my $self = shift;

    return $self->{PORT};
}

=item readloop()

Enters a loop waiting for messages. Once a message is received, the server will
call the handler subroutine, if defined.

=cut

sub readloop {
    my $self = shift;

    my $MAXLEN = 1024;
    my ($msg, $host);

    while ($self->{SOCKET}->recv($msg, $MAXLEN)) {
        my ($port, $ipaddr) = sockaddr_in($self->{SOCKET}->peername);
        $host = gethostbyaddr($ipaddr, AF_INET) || '';

        $self->{HANDLER}->($host, Net::OpenSoundControl::decode($msg))
          if defined $self->{HANDLER};

        return if ($msg =~ /exit/);
    }
}

1;

=back

=head1 SEE ALSO

The OpenSound Control website: http://www.cnmat.berkeley.edu/OpenSoundControl/

L<Net::OpenSoundControl>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Christian Renz E<lt>crenz @ web42.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

