use strict;
use warnings;
package Search::GIN::Extract::Multiplex;

our $VERSION = '0.11';

use Moose;
use namespace::autoclean;

with qw(Search::GIN::Extract);

has extractors => (
    isa => "ArrayRef[Search::GIN::Extract]",
    is  => "ro",
    required => 1,
);

sub extract_values {
    my ( $self, $obj, @args ) = @_;

    return map { $_->extract_values($obj, @args) } @{ $self->extractors };
}

__PACKAGE__->meta->make_immutable;

1;
