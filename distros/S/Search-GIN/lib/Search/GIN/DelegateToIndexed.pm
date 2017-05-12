use strict;
use warnings;
package Search::GIN::DelegateToIndexed;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

with qw(Search::GIN::Core);

requires "ids_to_objects";

sub extract_values {
    my ( $self, $obj, @args ) = @_;
    $obj->gin_extract_values($self, @args);
}

sub compare_values {
    my ( $self, $obj, @args ) = @_;
    $obj->gin_compare_values($self, @args);
}

sub objects_to_ids {
    my ( $self, @objs ) = @_;
    map { $_->gin_id } @objs;
}

1;
