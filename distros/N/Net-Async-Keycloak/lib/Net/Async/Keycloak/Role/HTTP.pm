package Net::Async::Keycloak::Role::HTTP;

# ABSTRACT: Sending requests to Keycloak through Net::Async::HTTP

use Future;
use Net::Async::Keycloak::Error::API;
use Net::Async::Keycloak::Error::Network;
use Net::Async::Keycloak::Error::Validation;
use Scalar::Util qw( blessed );
use Moo::Role;

our $VERSION = '0.001';


sub api_error_class        { 'Net::Async::Keycloak::Error::API' }
sub network_error_class    { 'Net::Async::Keycloak::Error::Network' }
sub validation_error_class { 'Net::Async::Keycloak::Error::Validation' }

sub fail_validation {
  my ( $self, $message ) = @_;
  return Future->fail( $self->validation_error_class->new( message => $message ) );
}


sub send_request_f {
  my ( $self, $method, $url, %arg ) = @_;
  my $request = $self->build_request( $method, $url, %arg );
  # Net::Async::HTTP dies instead of failing when it is in no loop
  my $sent = eval { $self->http->do_request( request => $request ) };
  return Future->fail( $self->network_error_class->new( message => $method.' '.$url.': could not send ('
    .( $@ =~ s/ at \S+ line \d+.*//sr ).'); was the Net::Async::Keycloak added to a loop?' ) ) unless $sent;
  return $sent->else( sub {
    my ( $message ) = @_;
    return Future->fail($message) if blessed $message;
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

Net::Async::Keycloak::Role::HTTP - Sending requests to Keycloak through Net::Async::HTTP

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The asynchronous counterpart of L<WWW::Keycloak::Role::HTTP>. Requests are
built and responses read by that role's C<build_request> and
C<read_response>, so both clients map Keycloak's answers the same way; this
role only sends through L<Net::Async::HTTP> and returns futures.

Consume it before L<WWW::Keycloak::Role::HTTP>: its error class methods then
win and the errors are this distribution's subclasses.

    with 'Net::Async::Keycloak::Role::HTTP';
    with 'WWW::Keycloak::Role::HTTP';

The consuming class has an C<http> attribute holding a L<Net::Async::HTTP>.

=head2 fail_validation

    return $self->fail_validation('a client_id is needed');

A failed future with a validation error.

=head2 send_request_f

    $self->send_request_f( POST => $url, json => \%body, bearer => $token )->then( sub {
      my ( $result ) = @_;   # status, data, location
      ...
    } );

Fails with a network error when no answer came back and an API error for any
status of 400 and above.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-keycloak/issues>.

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
