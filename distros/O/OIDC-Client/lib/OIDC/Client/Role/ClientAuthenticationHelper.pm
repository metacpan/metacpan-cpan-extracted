package OIDC::Client::Role::ClientAuthenticationHelper;
use utf8;
use Moose::Role;
use namespace::autoclean;
use feature 'signatures';
no warnings 'experimental::signatures';
use Readonly;
use Carp qw(croak);
use Mojo::Util qw(b64_encode);
use Crypt::JWT ();

=encoding utf8

=head1 NAME

OIDC::Client::Role::ClientAuthenticationBuilder - Client Authentication Builder

=head1 DESCRIPTION

This Moose role covers private methods for building client authentication data.

=cut


requires qw(log_msg
            id
            secret
            private_key
            client_assertion_lifetime
            client_assertion_audience
            generate_uuid_string
            private_key_jwt_encoding_options
            client_secret_jwt_encoding_options);


Readonly my $CLIENT_ASSERTION_TYPE => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer';


sub _build_client_auth_arguments ($self, $method, $url) {

  my (%headers, %form);

  if ($method eq 'client_secret_basic') {
    $headers{Authorization} = 'Basic ' . b64_encode(join(':', $self->id, $self->secret), '');
  }
  elsif ($method eq 'client_secret_post') {
    $form{client_id}     = $self->id;
    $form{client_secret} = $self->secret;
  }
  elsif ($method eq 'client_secret_jwt') {
    $form{client_id}              = $self->id;
    $form{client_assertion_type}  = $CLIENT_ASSERTION_TYPE;
    $form{client_assertion}       = $self->_build_client_assertion(0, $url);
  }
  elsif ($method eq 'private_key_jwt') {
    $form{client_id}              = $self->id;
    $form{client_assertion_type}  = $CLIENT_ASSERTION_TYPE;
    $form{client_assertion}       = $self->_build_client_assertion(1, $url);
  }
  elsif ($method eq 'none') {
    $form{client_id} = $self->id;
  }
  else {
    croak("Unsupported client auth method: $method");
  }

  return (\%headers, \%form);
}


sub _build_client_assertion ($self, $use_private_key, $url) {

  $self->log_msg(debug => 'OIDC: building client assertion');

  my $now = time;
  my $exp = $now + $self->client_assertion_lifetime;
  my $aud = $self->client_assertion_audience // $url;
  my $jti = $self->generate_uuid_string();

  my %claims = (
    iss => $self->id,
    sub => $self->id,
    aud => $aud,
    jti => $jti,
    iat => $now,
    exp => $exp,
  );

  my $jwt_encoding_options = $use_private_key ? $self->private_key_jwt_encoding_options
                                              : $self->client_secret_jwt_encoding_options;

  return Crypt::JWT::encode_jwt(
    %$jwt_encoding_options,
    payload => \%claims,
    key     => $use_private_key ? $self->private_key : $self->secret,
  );
}


1;
