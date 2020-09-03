package POE::Component::TLSify::ServerHandle;
$POE::Component::TLSify::ServerHandle::VERSION = '0.08';
#ABSTRACT: Server-side handle for TLSify

use strict;
use warnings;
use POSIX qw[EAGAIN EWOULDBLOCK];
use IO::Socket::SSL qw[$SSL_ERROR SSL_WANT_READ SSL_WANT_WRITE];

sub TIEHANDLE {
  my ($class,$socket,$args,$connref) = @_;
  my $fileno = fileno($socket);
  $socket = IO::Socket::SSL->start_SSL(
    $socket,
    SSL_Server => 1,
    SSL_startHandshake => 0,
    %$args,
  ) or die IO::Socket::SSL->errstr;
  $socket->accept_SSL;
  if( $! != EAGAIN and $! != EWOULDBLOCK ) {
    die IO::Socket::SSL::errstr();
  }
  my $self = bless {
    socket  => $socket,
    started => 0,
    fileno  => $fileno,
    method  => 'accept_SSL',
    on_connect => $connref,
  }, $class;
  return $self;
}

sub _check_status {
  my $self = shift;
  my $method = $self->{method};
  unless ( eval { $self->{socket}->$method } ) {
    if ( $! != EAGAIN and $! != EWOULDBLOCK ) {
      if ( defined $self->{on_connect} ) {
        my $errval = IO::Socket::SSL->errstr;
        $self->{'on_connect'}->( $self->{'orig_socket'}, 0, $errval );
      }
      return 0;
    }
  }
  $self->{started} = 1;
  if ( defined $self->{on_connect} ) {
    $self->{'on_connect'}->( $self->{'orig_socket'}, 1 );
  }
  return 1;
}

sub READ {
  my $self = shift;
  if ( ! $self->{started} ) {
    return if $self->_check_status == 0;
  }
  return $self->{socket}->sysread( @_ );
}

sub WRITE {
  my $self = shift;
  if ( ! $self->{started} ) {
    return 0 if $self->_check_status == 0;
  }
  return $self->{socket}->syswrite( @_ );
}

sub CLOSE {
  my $self = shift;
  return 1 if ! defined $self->{socket};
  $self->{socket}->close() if defined $self->{socket}->can('close');
  undef $self->{socket};
  return 1;
}

sub DESTROY {
  my $self = shift;
  if ( defined $self->{socket} ) {
    $self->CLOSE();
  }
  return;
}

sub FILENO {
  return $_[0]->{fileno};
}

sub READLINE {
  die 'Not Implemented';
}

sub PRINT {
  die 'Not Implemented';
}

qq[I TLSify!];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::TLSify::ServerHandle - Server-side handle for TLSify

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This is a C<tied> wrapper around L<IO::Socket::SSL> C<startSSL>. It operates in a similar manner to
L<POE::Component::SSLify::ServerHandle>.

=head2 DIFFERENCES

This module doesn't know what to do with PRINT/READLINE, as they usually are not used in L<POE::Wheel> operations.

=head2 SEE ALSO

L<POE::Component::TLSify>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Apocalypse <APOCAL@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Williams, Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
