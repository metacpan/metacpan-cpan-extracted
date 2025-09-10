package OIDC::Client::ApiUserAgentBuilder;

use utf8;
use Moose;
use Moose::Exporter;
use MooseX::Params::Validate;
use Mojo::UserAgent;
use Readonly;

=encoding utf8

=head1 NAME

OIDC::Client::ApiUserAgentBuilder - API user agent builder

=head1 DESCRIPTION

Exports functions that help create an API user agent (L<Mojo::UserAgent> object).
For each request, the user agent includes the access token in the C<Authorization> header.

=cut

Readonly my $DEFAULT_TOKEN_TYPE => 'Bearer';

Moose::Exporter->setup_import_methods(as_is => [qw/build_api_useragent_from_token_response
                                                   build_api_useragent_from_access_token
                                                   build_api_useragent_from_token_value
                                                  /]);


=head1 FUNCTIONS

=head2 build_api_useragent_from_token_response( $token_response )

Builds a L<Mojo::UserAgent> object from an L<OIDC::Client::TokenResponse> object.

=cut

sub build_api_useragent_from_token_response {
  my ($token_response) = pos_validated_list(\@_, { isa => 'OIDC::Client::TokenResponse', optional => 0 });

  return build_api_useragent_from_token_value($token_response->access_token,
                                              $token_response->token_type);
}


=head2 build_api_useragent_from_access_token( $access_token )

Builds a L<Mojo::UserAgent> object from an L<OIDC::Client::AccessToken> object.

=cut

sub build_api_useragent_from_access_token {
  my ($access_token) = pos_validated_list(\@_, { isa => 'OIDC::Client::AccessToken', optional => 0 });

  return build_api_useragent_from_token_value($access_token->token,
                                              $access_token->token_type);
}


=head2 build_api_useragent_from_token_value( $token_value, $token_type )

Builds a L<Mojo::UserAgent> object from a token value (string).

=cut

sub build_api_useragent_from_token_value {
  my ($token_value, $token_type) = pos_validated_list(\@_, { isa => 'Str', optional => 0 },
                                                           { isa => 'Maybe[Str]', optional => 1 });
  $token_type ||= $DEFAULT_TOKEN_TYPE;

  my $ua = Mojo::UserAgent->new();

  $ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->authorization("$token_type $token_value");
  });

  return $ua;
}

1;
