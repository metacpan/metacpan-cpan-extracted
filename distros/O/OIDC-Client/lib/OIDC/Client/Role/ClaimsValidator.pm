package OIDC::Client::Role::ClaimsValidator;
use utf8;
use Moose::Role;
use namespace::autoclean;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp qw(croak);
use List::Util qw(any);
use OIDC::Client::Error::TokenValidation;

=encoding utf8

=head1 NAME

OIDC::Client::Role::ClaimsValidator - Claims Validator

=head1 DESCRIPTION

This Moose role covers private methods for validating token claims.

=cut


requires qw(audience
            provider_metadata
            jwt_decoding_options);


sub _validate_issuer ($self, $issuer) {

  defined $issuer
    or OIDC::Client::Error::TokenValidation->throw("OIDC: 'iss' claim is missing");

  my $expected_issuer = $self->provider_metadata->{issuer}
    or croak("OIDC: issuer not found in provider metadata");

  $issuer eq $expected_issuer
    or OIDC::Client::Error::TokenValidation->throw(
      "OIDC: unexpected issuer, expected '$expected_issuer' but got '$issuer'"
    );
}


sub _validate_audience ($self, $audience, $expected_audience) {

  defined $audience
    or OIDC::Client::Error::TokenValidation->throw("OIDC: 'aud' claim is missing");

  $expected_audience ||= $self->audience;

  my @audiences = ref $audience eq 'ARRAY' ? @$audience : ($audience);

  any { $_ eq $expected_audience } @audiences
    or OIDC::Client::Error::TokenValidation->throw(
      "OIDC: unexpected audience, expected '$expected_audience' but got " . join(', ', map { "'$_'" } @audiences)
    );
}


sub _validate_authorized_party ($self, $azp, $expected_authorized_party) {

  if (defined $expected_authorized_party) {
    defined $azp
      or OIDC::Client::Error::TokenValidation->throw("OIDC: 'azp' claim is missing");
    $azp eq $expected_authorized_party
      or OIDC::Client::Error::TokenValidation->throw(
        "OIDC: unexpected authorized party, expected '$expected_authorized_party' but got '$azp'"
      );
  }
  elsif (defined $azp) {
    OIDC::Client::Error::TokenValidation->throw("OIDC: unexpected 'azp' claim");
  }
}


sub _validate_subject ($self, $subject, $expected_subject) {

  defined $subject
    or OIDC::Client::Error::TokenValidation->throw("OIDC: 'sub' claim is missing");

  $subject eq $expected_subject
    or OIDC::Client::Error::TokenValidation->throw(
      "OIDC: unexpected subject, expected '$expected_subject' but got '$subject'"
    );
}

sub _validate_nonce ($self, $nonce, $expected_nonce) {

  defined $nonce
    or OIDC::Client::Error::TokenValidation->throw("OIDC: 'nonce' claim is missing");

  $nonce eq $expected_nonce
    or OIDC::Client::Error::TokenValidation->throw(
      "OIDC: unexpected nonce, expected '$expected_nonce' but got '$nonce'"
    );
}


sub _validate_age ($self, $issued_at, $max_token_age) {

  defined $issued_at
    or OIDC::Client::Error::TokenValidation->throw("OIDC: 'iat' claim is missing");

  $issued_at >= time - ($self->jwt_decoding_options->{leeway} // 0) - $max_token_age
    or OIDC::Client::Error::TokenValidation->throw(
      "OIDC: the token is too old"
    );
}


1;
