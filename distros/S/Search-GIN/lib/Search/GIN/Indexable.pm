use strict;
use warnings;
package Search::GIN::Indexable;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

requires 'gin_extract_values';

sub gin_id {
    my $self = shift;
    return $self;
}

sub gin_compare_values {
    my ( $self, $one, $two ) = @_;
    $one cmp $two;
}

sub gin_consistent {
    my ( $self, $index, $query, @args ) = @_;
    $query->gin_consistent($index, $self, @args);
}

1;
