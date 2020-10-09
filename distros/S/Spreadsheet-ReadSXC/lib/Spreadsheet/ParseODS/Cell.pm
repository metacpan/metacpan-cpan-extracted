package Spreadsheet::ParseODS::Cell;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.32';

=head1 NAME

Spreadsheet::ParseODS::Cell - a cell in a spreadsheet

=cut

has 'value' => (
    is => 'rw',
);

has 'unformatted' => (
    is => 'rw',
);

has 'formula' => (
    is => 'rw',
);

has 'type' => (
    is => 'rw',
);

has 'hyperlink' => (
    is => 'rw',
);

has 'format' => (
    is => 'rw',
);

has 'style' => (
    is => 'rw',
);

has 'is_merged' => (
    is => 'rw',
);

has 'is_hidden' => (
    is => 'rw',
);

sub get_hyperlink( $self ) {
    $self->hyperlink
}

sub get_format( $self ) {
    $self->format
}


1;
