package POE::Component::TLSify::ClientHandle;
$POE::Component::TLSify::ClientHandle::VERSION = '0.02';
#ABSTRACT: Client-side handle for TLSify

use strict;
use warnings;
use POSIX qw[EAGAIN EWOULDBLOCK];
use IO::Socket::SSL qw[$SSL_ERROR SSL_WANT_READ SSL_WANT_WRITE];

use parent 'POE::Component::TLSify::ServerHandle';

sub TIEHANDLE {
  my ($class,$socket,$args,$connref) = @_;
  my $fileno = fileno($socket);

  my %SSL_ca_args = IO::Socket::SSL::default_ca();

  if ( !defined $args->{SSL_verify_mode}
       and !defined $args->{SSL_ca_file}
       and !defined $args->{SSL_ca_path} ) {

    unless ( %SSL_ca_args ) {
      $SSL_ca_args{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_NONE();
    }

    %$args = ( %SSL_ca_args, %$args );
  }

  $socket = IO::Socket::SSL->start_SSL(
    $socket,
    SSL_startHandshake => 0,
    %$args,
  ) or die IO::Socket::SSL->errstr;
  $socket->connect_SSL;
  if( $! != EAGAIN and $! != EWOULDBLOCK ) {
    die IO::Socket::SSL::errstr();
  }
  my $self = bless {
    socket  => $socket,
    started => 0,
    fileno  => $fileno,
    method  => 'connect_SSL',
    on_connect => $connref,
  }, $class;
  return $self;
}

qq[I TLSify!];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::TLSify::ClientHandle - Client-side handle for TLSify

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This is a C<tied> wrapper around L<IO::Socket::SSL> C<startSSL>. It operates in a similar manner to
L<POE::Component::SSLify::ClientHandle>.

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
