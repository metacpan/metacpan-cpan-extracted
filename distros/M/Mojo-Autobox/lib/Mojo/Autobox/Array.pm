package Mojo::Autobox::Array;

use Mojo::Base -strict;

sub collection {
  require Mojo::Collection;
  Mojo::Collection->new(@{shift()});
}

*c = \&collection;

sub json {
  require Mojo::JSON;
  Mojo::JSON::encode_json(shift);
}

*j = \&json;

1;

=head1 NAME

Mojo::Autobox::Array - Autobox array methods for Mojo::Autobox

=head1 SYNOPSIS

 use Mojo::Autobox;

 # "a"
 [qw/a b c/]->collection->first;

 # '["x", "y", "z"]'
 @array = (qw/x y z/);
 @array->json;

=head1 DESCRIPTION

Array methods for L<Mojo::Autobox>. These methods also apply to array references.

=head1 METHODS

=head2 collection

Returns an instance of L<Mojo::Collection>, contructed from the elements of the invocant array.

=head2 json

Serializes the invocant array using L<Mojo::JSON/encode_json> and returns the result.

=head2 j

An alias for L</json>.

