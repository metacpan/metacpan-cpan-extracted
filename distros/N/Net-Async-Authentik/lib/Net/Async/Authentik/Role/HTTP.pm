package Net::Async::Authentik::Role::HTTP;

# ABSTRACT: Sending requests to authentik through Net::Async::HTTP

use Future;
use Net::Async::Authentik::Error::API;
use Net::Async::Authentik::Error::Network;
use Net::Async::Authentik::Error::Validation;
use Scalar::Util qw( blessed );
use Moo::Role;

our $VERSION = '0.001';


sub api_error_class        { 'Net::Async::Authentik::Error::API' }
sub network_error_class    { 'Net::Async::Authentik::Error::Network' }
sub validation_error_class { 'Net::Async::Authentik::Error::Validation' }


sub fail_validation {
  my ( $self, $message ) = @_;
  return Future->fail( $self->validation_error_class->new( message => $message ) );
}


sub pairs_or_fail {
  my ( $self, $positional, @args ) = @_;
  # An odd-sized list where a key belongs is a mistake in the caller, and on
  # Future::AsyncAwait 0.71 a very expensive one: a suspended async sub whose
  # pad holds a hash built from such a list corrupts the heap when the future
  # is dropped - "double free or corruption", no exception, no stack. Nine
  # lines reproduce it without this distribution; see the plan under "Nach
  # dem Bau geklaert". So the shape is checked before the hash is built.
  return ( 1, { @args[ $positional .. $#args ] } ) if ( @args - $positional ) % 2 == 0;
  return ( 0, undef );
}


sub send_request_f {
  my ( $self, $method, $url, %arg ) = @_;
  # building it can die too: a body the JSON codec cannot encode. Nothing in
  # this distribution throws, so that becomes a failed future as well.
  my $request = eval { $self->build_request( $method, $url, %arg ) };
  return Future->fail( $self->validation_error_class->new(
    message => $method.' '.$url.': the request could not be built ('.( $@ =~ s/ at \S+ line \d+.*//sr ).')' ) )
    unless $request;
  # Net::Async::HTTP dies instead of failing when it is in no loop
  my $sent = eval { $self->http->do_request( request => $request ) };
  return Future->fail( $self->network_error_class->new( message => $method.' '.$url.': could not send ('
    .( $@ =~ s/ at \S+ line \d+.*//sr ).'); was the Net::Async::Authentik added to a loop?' ) ) unless $sent;
  return $sent->else( sub {
    my ( $message ) = @_;
    return Future->fail($message) if blessed $message;
    # a refused connection arrives as one string, a timeout as ('Timed out',
    # 'timeout'); neither is an object the way LWP's internal response was
    return Future->fail( $self->network_error_class->new( message => $method.' '.$url.': '.$message ) );
  } )->then( sub {
    my ( $response ) = @_;
    my $result = eval { $self->read_response( $response, $method, $url, %arg ) };
    return $result ? Future->done($result) : Future->fail($@);
  } );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Authentik::Role::HTTP - Sending requests to authentik through Net::Async::HTTP

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The asynchronous counterpart of L<WWW::Authentik::Role::HTTP>. Requests are
built and responses read by that role's C<build_request> and
C<read_response>, so both clients map authentik's answers the same way; this
role only sends, through L<Net::Async::HTTP>, and returns futures.

Consume it before L<WWW::Authentik::Role::HTTP>: its error class methods then
win and the errors are this distribution's subclasses.

    with 'Net::Async::Authentik::Role::HTTP';
    with 'WWW::Authentik::Role::HTTP';

The consuming class has an C<http> attribute holding a L<Net::Async::HTTP>.

=head2 api_error_class

=head2 network_error_class

=head2 validation_error_class

The classes a failed future fails with. They override the synchronous role's,
which is why this role is composed first.

=head2 fail_validation

    return $self->fail_validation('a client_id is needed');

A failed future with a validation error. Nothing in this distribution throws:
a wrong argument fails the future the caller is already holding.

=head2 pairs_or_fail

    my ( $ok, $arg ) = $self->pairs_or_fail( 1, @_ );
    return $self->fail_validation('...') unless $ok;

Takes the number of positional arguments and the whole argument list, and
gives back whether what follows them makes pairs, and those pairs as a hash
reference. Every method that would hold such a hash across an C<await> asks
first: Future::AsyncAwait 0.71 corrupts memory when a suspended frame holds a
hash built from an odd-sized list whose dangling element is a reference.

=head2 send_request_f

    $self->send_request_f( POST => $url, json => \%body, bearer => $token )->then( sub {
      my ( $result ) = @_;   # status, data, location, content
      ...
    } );

Sends one request. Fails with L<Net::Async::Authentik::Error::Network> when
no answer came back and with L<Net::Async::Authentik::Error::API> for any
status of 400 and above. Anything below 400 is an answer, including the 302
authentik gives where it wants a browser.

A body the JSON codec cannot encode fails with
L<Net::Async::Authentik::Error::Validation>, rather than throwing out of a
method the caller expected a future from.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
