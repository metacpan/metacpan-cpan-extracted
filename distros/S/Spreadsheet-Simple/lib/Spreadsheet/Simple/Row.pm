package Spreadsheet::Simple::Row;
{
  $Spreadsheet::Simple::Row::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::Row::AUTHORITY = 'cpan:DHARDISON';
}
# ABSTRACT: an object that represents a single row in a spreadsheet.
use Moose;
use namespace::autoclean;

use Spreadsheet::Simple::Types 'Cells';

has 'cells' => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => Cells,
    auto_deref => 1,
    required   => 1,
    coerce     => 1,
    handles    => {
        get_cell   => 'get',
        set_cell   => 'set',
        cell_count => 'count',
    },
);





around 'get_cell' => sub {
	my ($method, $self, $col) = @_;
	my $cell = $self->$method($col);

	return $cell if defined $cell;

	$cell = Spreadsheet::Simple::Cell->new( value => undef );

	$self->set_cell($col, $cell);

	return $cell;
};


sub get_cell_value {
	my ($self, $col) = @_;

	return $self->get_cell($col)->value;
}



sub get_cell_values {
	my ($self, @cols) = @_;
	return map { $self->get_cell_value($_) } @cols;
}


sub cell_values {
	my ($self) = @_;

	return map { $_->value } $self->cells
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Row - an object that represents a single row in a spreadsheet.

=head1 METHODS

=head2 set_cell(Int $col, Cell $cell)

Set the value of a particular column to $cell.

=head2 cell_count()

Return the number of cells in a row. This is often meaningless
as it will count empty cells.

=head2 get_cell(Int $col)

Returns a L<Spreadsheet::Simple::Cell> at column $col.

This will never return undef. To detect undefined cells, use C<$cell-E<gt>defined>.

=head2 get_cell_value(Int $col)

Convenience method, returns the value of a given cell (which may be undef).

=head2 get_cell_values(@cols)

Convenience method, returns list of 

=head2 cell_values()

Return all cell values in row.

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
