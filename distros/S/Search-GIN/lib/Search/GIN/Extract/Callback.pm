use strict;
use warnings;
package Search::GIN::Extract::Callback;

our $VERSION = '0.11';

use Moose;
use namespace::autoclean;

with qw(
    Search::GIN::Extract
    Search::GIN::Keys::Deep
);

has extract => (
    isa => "CodeRef|Str",
    is  => "ro",
    required => 1,
);

sub extract_values {
    my ( $self, $obj, @args ) = @_;

    my $extract = $self->extract;

    $self->process_keys( $obj->$extract($self, @args) );
}

__PACKAGE__->meta->make_immutable;

1;
