use strict;
use warnings;
package Search::GIN::Keys::Deep;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

with qw(
    Search::GIN::Keys
    Search::GIN::Keys::Join
    Search::GIN::Keys::Expand
);

sub process_keys {
    my ( $self, @keys ) = @_;

    $self->join_keys( $self->expand_keys(@keys) );
}

1;
