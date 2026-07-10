package OIDC::Client::Utils;

use utf8;
use Moose;
use Moose::Exporter;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Carp qw(croak);
use Crypt::PRNG qw(random_bytes_b64u);
use Digest::SHA qw(sha256);
use MIME::Base64 qw(encode_base64url);

=encoding utf8

=head1 NAME

OIDC::Client::Utils - Utility functions

=head1 DESCRIPTION

Exports utility functions.

=cut

Moose::Exporter->setup_import_methods(as_is => [qw/get_values_from_space_delimited_string
                                                   reach_data
                                                   affect_data
                                                   delete_data
                                                   generate_state
                                                   generate_nonce
                                                   generate_jti
                                                   generate_code_verifier
                                                   generate_code_challenge/]);


=head1 FUNCTIONS

=head2 get_values_from_space_delimited_string( $value )

Returns the values (arrayref) from a space-delimited string value.

=cut

sub get_values_from_space_delimited_string {
  my ($str) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });
  return [ grep { $_ ne '' } split(/\s+/, $str) ];
}


=head2 reach_data( $data_tree, \@path, $optional )

Simplified data diver. No support for arrayref nodes.

Tries to find a node under root $data_tree, walking down the tree and choosing subnodes
according to values given in $path (which should be an arrayref of scalar values).

While walking down the tree, if a key doesn't exist, undef is returned if the $optional
parameter is true (default value), otherwise an exception is thrown if the $optional parameter
is false.

No autovivification is performed by this function.

=cut

sub reach_data {
  my ($data_tree, $path, $optional) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 },
                                                              { isa => 'ArrayRef[Str]', optional => 0 },
                                                              { isa => 'Bool', default => 1 });
  foreach my $key (@$path) {
    ref $data_tree eq 'HASH' or croak("OIDC: not a hashref to reach the value of the '$key' key");
    if (exists $data_tree->{$key}) {
      $data_tree = $data_tree->{$key};
    }
    elsif ($optional) {
      return;
    }
    else {
      croak("OIDC: the '$key' key is not present");
    }
  }

  return $data_tree;
}


=head2 affect_data( $data_tree, \@path, $value )

Walks down the $data_tree and sets the $value to the subnode according to values given
in $path (which should be an arrayref of scalar values).

Arrayref nodes are not supported.

Autovivification can be performed by this function.

=cut

sub affect_data {
  my ($data_tree, $path, $value) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 },
                                                           { isa => 'ArrayRef[Str]', optional => 0 },
                                                           { optional => 0 });
  @$path >= 1 or croak(q{OIDC: to affect data, at least one value must be provided in the 'path' arrayref});

  my @path_to_iterate = @$path;
  my $key_to_assign_value = pop @path_to_iterate;

  foreach my $key (@path_to_iterate) {
    $data_tree = ($data_tree->{$key} //= {});
    ref $data_tree eq 'HASH' or croak("OIDC: the value of the '$key' key is not a hash reference");
  }
  $data_tree->{$key_to_assign_value} = $value;

  return;
}


=head2 delete_data( $data_tree, \@path )

Walks down the $data_tree, deletes the key of the last subnode and returns its value
according to values given in $path (which should be an arrayref of scalar values).

Arrayref nodes are not supported.

While walking down the tree, if a key doesn't exist, undef is returned.

No autovivification is performed by this function.

=cut

sub delete_data {
  my ($data_tree, $path) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 },
                                                   { isa => 'ArrayRef[Str]', optional => 0 });
  @$path >= 1 or croak(q{OIDC: to delete data, at least one value must be provided in the 'path' arrayref});

  my @path_to_iterate = @$path;
  my $key_to_delete = pop @path_to_iterate;

  foreach my $key (@path_to_iterate) {
    return unless defined $data_tree->{$key};
    $data_tree = $data_tree->{$key};
    ref $data_tree eq 'HASH' or croak("OIDC: the value of the '$key' key is not a hash reference");
  }

  return delete $data_tree->{$key_to_delete};
}


=head2 generate_state

Generates a cryptographically secure OAuth 2.0 C<state> value.
Returns a base64url-encoded string of 22 characters.

=cut

sub generate_state {
  return random_bytes_b64u(16);
}


=head2 generate_nonce

Generates a cryptographically secure OpenID Connect C<nonce> value.
Returns a base64url-encoded string of 22 characters.

=cut

sub generate_nonce {
  return random_bytes_b64u(16);
}


=head2 generate_jti

Generates a cryptographically secure JWT ID (C<jti>) value.
Returns a base64url-encoded string of 22 characters.

=cut

sub generate_jti {
  return random_bytes_b64u(16);
}


=head2 generate_code_verifier

Generates a cryptographically secure random code verifier for PKCE.
Returns a base64url-encoded string of 43 characters.

=cut

sub generate_code_verifier {
  return random_bytes_b64u(32);
}


=head2 generate_code_challenge($code_verifier, $code_challenge_method)

Generates the code challenge from a code verifier and a code challenge method.

=cut

sub generate_code_challenge {
  my ($code_verifier, $code_challenge_method) = pos_validated_list(\@_, { isa => 'Str', optional => 0 },
                                                                        { isa => enum([qw(plain S256)]), optional => 0 });
  if ($code_challenge_method eq 'plain') {
    return $code_verifier;
  }

  return encode_base64url(sha256($code_verifier));
}


1;
