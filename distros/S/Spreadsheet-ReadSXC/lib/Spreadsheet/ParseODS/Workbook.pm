package Spreadsheet::ParseODS::Workbook;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.32';

=head1 NAME

Spreadsheet::ParseODS::Workbook - a workbook

=cut

=head2 C<< ->filename >>

  print $workbook->filename;

The name of the file if applicable.

=cut

has 'filename' => (
    is => 'rw',
);

has '_settings' => (
    is => 'rw',
    handles => [ 'active_sheet_name' ],
);

# The worksheets themselves
has '_sheets' => (
    is => 'lazy',
    default => sub { [] },
);

# Mapping of names to sheet objects
has '_worksheets' => (
    is => 'lazy',
    default => sub { {} },
);

has '_styles' => (
    is => 'lazy',
    default => sub { {} },
);

=head2 C<< ->table_styles >>

The styles that identify whether a table is hidden, and other styles

=cut

has 'table_styles' => (
    is      => 'lazy',
    default => sub { {} },
);

=head2 C<< ->get_print_areas() >>

    my $print_areas = $workbook->get_print_areas();
    # [[ [$start_row, $start_col, $end_row, $end_col], ... ]]

The C<< ->get_print_areas() >> method returns the print areas
of each sheet as an arrayref of arrayrefs. If a sheet has no
print area, C<undef> is returned for its print area.

=cut

sub get_print_areas( $self ) {
    [ map { $_->get_print_areas } $self->worksheets ]
}

=head2 C<< ->get_active_sheet() >>

    my $sheet = $workbook->get_active_sheet();
    if( !$sheet ) {
        # If there is no defined active worksheet, take the first:
        ($sheet) = $workbook->worksheets();
    };

Returns the active worksheet, or if there is no such sheet, returns C<undef>.

=cut

sub get_active_sheet($self) {
    if( defined( my $name = $self->active_sheet_name )) {
        return $self->worksheet( $name );
    } else {
        return undef
    };
}

sub get_filename( $self ) {
    $self->filename
}

=head2 C<< ->worksheets() >>

    my @sheets = $workbook->worksheets;

Returns the list of worksheets as L<Spreadsheet::ParseODS::Worksheet>
objects.

=cut

sub worksheets( $self ) {
    @{ $self->_sheets }
};

=head2 C<< ->worksheet($name) >>

    my $sheet1 = $workbook->worksheet('Sheet 1');

Returns the worksheet with the given name, or if no such worksheet exists,
returns C<undef>.

=cut

sub worksheet( $self, $name ) {
    $self->_worksheets->{ $name }
}

1;
