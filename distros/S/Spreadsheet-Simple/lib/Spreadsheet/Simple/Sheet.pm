package Spreadsheet::Simple::Sheet;
{
  $Spreadsheet::Simple::Sheet::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::Sheet::AUTHORITY = 'cpan:DHARDISON';
}
# ABSTRACT: An object that represents a single spreadsheet (or worksheet)
use Moose;

use MooseX::Types::Moose 'Str';
use namespace::autoclean;

use Spreadsheet::Simple::Types 'Rows', 'is_Rows';
use Spreadsheet::Simple::Row;

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'rows' => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => Rows,
    coerce     => 1,
    auto_deref => 1,
    required   => 1,
    handles   => {
        add_row   => 'push',
        get_row   => 'get',
        set_row   => 'set',
        row_count => 'count',
    },
);



around 'get_row' => sub {
	my ($method, $self, $idx) = @_;
	my $row = $self->$method($idx);

	return $row if defined $row;

	$row = Spreadsheet::Simple::Row->new(cells => []);
    warn "$row" unless is_Rows([$row]);
	$self->set_row($idx, $row);

	return $row;
};




sub new_row {
	my ($self, @args) = @_;
	my $row = Spreadsheet::Simple::Row->new(@args);

	return $row;
}


sub get_cell {
	my ($self, $row, $col) = @_;
	return $self->get_row($row)->get_cell($col);
}


sub set_cell {
	my ($self, $row, $col, $cell) = @_;
	$self->get_row($row)->set_cell($col, $cell);
}



sub get_cell_value {
	my ($self, $row, $col) = @_;

	return $self->get_cell($row, $col)->value;
}


sub set_cell_value {
	my ($self, $row, $col, $val) = @_;

	return $self->set_cell(
		$row,
		$col,
		Spreadsheet::Simple::Cell->new(
			value => $val,
		)
	);
}

sub _format_column_ref {
	my ($self, $col) = @_;
	my @buffer;

	while ($col > 25) {
		push @buffer, chr(($col % 26) + ord('A'));
		$col = ($col / 26) - 1;
	}
	push @buffer, chr($col + ord('A'));

	return reverse join('', @buffer);
}

sub _parse_column_ref {
	my ($self, $col) = @_;
	my $sum = 0;

	foreach my $char (split(//, uc $col)) {
		$sum = 26 * $sum + 1 + ord ($char) - ord ('A');
	}

	return $sum - 1;
}



1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Sheet - An object that represents a single spreadsheet (or worksheet)

=head1 METHODS

=head2 get_row(Int $row)

Return a L<Spreadsheet::Simple::Row> object.

This will never return undef, it will autovivify a non-exisitng row upon request.

=head2 new_row(@args)

Convenience method for creating a new row object.

=head2 get_cell(Int $row, Int $col)

Convenience method for getting a cell object. Returns a new cell object
and cannot return undef.

=head2 set_cell(Int $row, Int $col, $cell)

Convenience method

    $self->get_row($row)->set_cell($col, $cell)

=head2 get_cell_value($row, $col)

Convenience method

    $self->get_cell($row, $col)->value

=head2 set_cell_value(Int $row, Int $col, Str $value)

Convenience method

    $self->get_row($row)->set_cell($col, Spreadsheet::Simple::Cell->new(value => $value))

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
