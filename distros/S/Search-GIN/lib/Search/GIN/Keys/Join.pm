use strict;
use warnings;
package Search::GIN::Keys::Join;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

sub join_keys {
    my ( $self, @keys ) = @_;
    map { $self->join_key($_) } @keys;
}

sub join_key {
    my ( $self, @key ) = @_;
    no warnings 'uninitialized';
    join ":", map { ref($_) ? @$_ : $_ } @key;
}

1;
