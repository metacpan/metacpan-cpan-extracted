package Mojo::Autobox::Hash;

use Mojo::Base -strict;

sub json {
  require Mojo::JSON;
  Mojo::JSON::encode_json(shift);
}

*j = \&json;

1;

=head1 NAME

Mojo::Autobox::Hash - Autobox hash methods for Mojo::Autobox

=head1 SYNOPSIS

 use Mojo::Autobox;

 # '{"hello": "world"}'
 {hello => 'world'}->json;

=head1 DESCRIPTION

Hash methods for L<Mojo::Autobox>. These also apply to hash references.

=head1 METHODS

=head2 json

Serializes the invocant hash using L<Mojo::JSON/encode_json> and returns the result.

=head2 j

An alias for L</json>.

