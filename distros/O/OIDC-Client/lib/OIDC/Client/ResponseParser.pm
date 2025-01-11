package OIDC::Client::ResponseParser;
use utf8;
use Moose;
use namespace::autoclean;

use Try::Tiny;
use OIDC::Client::Error::InvalidResponse;
use OIDC::Client::Error::Provider;

=encoding utf8

=head1 NAME

OIDC::Client::ResponseParser

=head1 DESCRIPTION

Provider response parser.

=head1 METHODS

=head2 parse( $response )

Analyse the result of the L<Mojo::Message::Response> object.

If all is well, returns the Perl structure corresponding to the JSON response.

On the other hand, if the response is not correctly parsed into JSON format,
an L<OIDC::Client::Error::InvalidResponse> error is thrown or if the provider
returned an error, an L<OIDC::Client::Error::Provider> error is thrown.

=cut

sub parse {
  my ($self, $res) = @_;

  if ($res->is_success) {
    return try {
      $res->json;
    }
    catch {
      OIDC::Client::Error::InvalidResponse->throw(
        sprintf(q{Invalid response: %s}, $_)
      );
    };
  }
  else {
    OIDC::Client::Error::Provider->throw({
      response_parameters => try { $res->json } || {},
      alternative_error   => $res->is_error ? $res->message || $res->code
                                            : $res->{error}{message} || $res->{error}{code},
    });
  }
}

__PACKAGE__->meta->make_immutable;

1;
