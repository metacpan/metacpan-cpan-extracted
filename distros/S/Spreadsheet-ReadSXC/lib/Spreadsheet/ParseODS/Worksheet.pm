package Spreadsheet::ParseODS::Worksheet;
use Moo 2;
use Carp qw(croak);
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use PerlX::Maybe;

our $VERSION = '0.32';

=head1 NAME

Spreadsheet::ParseODS::Worksheet - a sheet in a workbook

=cut

has 'label' => (
    is => 'rw'
);

has 'data' => (
    is => 'rw'
);

has 'sheet_hidden' => (
    is => 'rw',
);

has 'row_min' => (
    is => 'rw',
);

has 'row_max' => (
    is => 'rw',
);

has 'col_min' => (
    is => 'rw',
);

has 'col_max' => (
    is => 'rw',
);

has 'print_areas' => (
    is => 'rw',
);

has 'header_rows' => (
    is => 'rw',
);

has 'header_cols' => (
    is => 'rw',
);

has 'hidden_rows' => (
    is => 'rw',
);

has 'hidden_cols' => (
    is => 'rw',
);

has 'tab_color' => (
    is => 'rw',
);

has 'merged_areas' => (
    is => 'lazy',
    default => sub { [] },
);

sub get_cell( $self, $row, $col ) {
    return undef if $row > $self->row_max;
    return undef if $col > $self->col_max;
    $self->data->[ $row ]->[ $col ]
}

sub get_name( $self ) {
    $self->name
}

sub get_tab_color( $self ) {
    $self->tab_color
}

sub is_sheet_hidden( $self ) {
    $self->sheet_hidden
}

sub row_range( $self ) {
    return ($self->row_min, $self->row_max)
}

sub col_range( $self ) {
    return ($self->col_min, $self->col_max)
}

=head2 C<< get_print_areas() >>

    my $print_areas = $worksheet->get_print_areas();
    # [ [$start_row, $start_col, $end_row, $end_col], ... ]

The C<< ->get_print_areas() >> method returns the print areas
of the sheet as an arrayref.

Returns undef if there are no print areas.

=cut

sub get_print_areas($self) {
    my $ar = $self->print_areas;
}

sub get_print_titles( $self ) {
    my $hr = $self->header_rows;
    my $hc = $self->header_cols;
    my $res = {
        maybe Row    => $hr,
        maybe Column => $hc,
    };
    return unless scalar keys %$res;
    return $res
}

sub get_merged_areas( $self ) {
    return $self->merged_areas
}

sub is_row_hidden( $self, $rownum=undef ) {
    wantarray ? @{ $self->hidden_rows }
              : $self->hidden_rows->[ $rownum ]
}

sub is_col_hidden( $self, $colnum=undef ) {
    wantarray ? @{ $self->hidden_cols }
              : $self->hidden_cols->[ $colnum ]
}

1;
