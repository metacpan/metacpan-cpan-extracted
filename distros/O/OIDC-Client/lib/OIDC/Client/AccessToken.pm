package OIDC::Client::AccessToken;
use utf8;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use List::Util qw(any);

has 'token' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has 'token_type' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'expires_at' => (
  is       => 'ro',
  isa      => 'Maybe[Int]',
  required => 0,
);

has 'scopes' => (
  is        => 'ro',
  isa       => 'Maybe[ArrayRef[Str]]',
  required  => 0,
  predicate => 'has_scopes',
);

has 'claims' => (
  is       => 'ro',
  isa      => 'Maybe[HashRef]',
  required => 0,
);

=encoding utf8

=head1 NAME

OIDC::Client::AccessToken - Access Token class

=head1 DESCRIPTION

Class representing an access token

=head1 ATTRIBUTES

=head2 token

The string of the access token. Required

=head2 token_type

The type of the access token

=head2 expires_at

The expiration time of the access token (number of seconds since 1970-01-01T00:00:00Z)

=head2 scopes

The scopes (arrayref) of the access token

=head2 claims

Hashref of claims coming from the access token. Optional, as an access token
is not always decoded, depending on the nature of the application.

=head1 METHODS

=head2 has_scope( $expected_scope )

  my $has_scope = $access_token->has_scope($expected_scope);

Returns whether a scope is present in the scopes of the access token.

=cut

sub has_scope {
  my $self = shift;
  my ($expected_scope) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  return any { $_ eq $expected_scope } @{$self->scopes // []};
}

=head2 has_expired( $leeway )

  my $has_expired = $access_token->has_expired();

Returns whether the access token has expired.

Returns undef if the C<expires_at> attribute is not defined.

The list parameters are:

=over 2

=item leeway

Number of seconds of leeway for the token to be considered expired before it actually is.

=back

=cut

sub has_expired {
  my $self = shift;
  my ($leeway) = pos_validated_list(\@_, { isa => 'Maybe[Int]', optional => 1 });
  $leeway //= 0;

  return unless defined $self->expires_at;

  return ( $self->expires_at - $leeway ) < time;
}

=head2 to_hashref()

  my $access_token_href = $access_token->to_hashref();

Returns a hashref of the access token data.

=cut

sub to_hashref {
  my $self = shift;

  return {
    map { $_ => $self->$_ }
    grep { defined $self->$_ }
    map { $_->name } $self->meta->get_all_attributes
  };
}

__PACKAGE__->meta->make_immutable;

1;
