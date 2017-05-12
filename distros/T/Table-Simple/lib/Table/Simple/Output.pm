package Table::Simple::Output;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp qw(carp);

=head1 NAME

Table::Simple::Output - generates ASCII output for an Table::Simple object

=head1 DESCRIPTION

This class generates the ASCII table output for a L<Table::Simple> object.
The output functionality was split to make subclassing easier.

=head2 ATTRIBUTES

=over 4

=item column_marker

This attribute is the character to mark the beginning or end of a column. The
default is ":"

=back

=cut

has 'column_marker' => (
	is => 'ro',
	isa => 'Str',
	default => ":",
);

=over 4

=item horizontal_rule

This attribute is the character to mark horizontal lines in the table. The
default is "="

=back

=cut

has 'horizontal_rule' => (
	is => 'ro',
	isa => 'Str',
	default => '=',
);

=over 4

=item intersection_marker

This attribute is the character marking the intersection between the column
marker and a horizontal rule. The default is "+"

=back

=cut

has 'intersection_marker' => (
	is => 'ro',
	isa => 'Str',
	default => "+",
);

=over 4

=item padding

This attribute defines the amount of spaces to put around data rows. The
default is 1 space.

=back

=cut

has 'padding' => (
	is => 'ro',
	isa => 'Int',
	default => 1,
);

=over 4

=item table

This attribute is required at construction time. It is the table to be 
output. It must be an object of type L<Table::Simple>.

=back

=cut

has 'table' => (
	is => 'ro',
	isa => 'Table::Simple',
	required => 1,
);

has '_widths' => (
	is => 'ro',
	isa => 'HashRef[Int]',
	traits => [ 'Hash' ],
	default => sub { {} },
	handles => {
		'_set_width' => 'set',
		'_get_width' => 'get',
	},
	lazy => 1,
);

has '_hrule' => (
	is => 'rw',
	isa => 'Str',
	lazy_build => 1,
);

has '_blank_row' => (
	is => 'rw',
	isa => 'Str',
	lazy_build => 1,
);

sub BUILD {
	my $self = shift;

	$self->_compute_widths if defined $self->table;
}


sub _compute_widths {
	my $self = shift;
	my $table = $self->table;
	
	my $total = $table->columns->Length - 1;

	foreach my $column ( $table->get_columns ) {
		$self->_set_width( $column->name => 
			( $column->width + ( 2 * $self->padding ) ) );
		$total += $column->width + ( 2 * $self->padding );
	}

	$self->_set_width( '_total' => $total );

}

sub _build__hrule {
	my $self = shift;
	my $table = $self->table;

	my $hrule = $self->intersection_marker;
	foreach my $column ( $table->get_columns ) {
		$hrule .= $self->horizontal_rule x $self->_get_width($column->name());
		$hrule .= $self->intersection_marker;
	}
	$hrule .= "\n";

	return $hrule;
}

sub _build__blank_row {
	my $self = shift;
	my $table = $self->table;

	my $blank_row = $self->column_marker;
	foreach my $column ( $table->get_columns ) {
		$blank_row .= " " x $self->_get_width($column->name());
		$blank_row .= $self->column_marker;
	}
	$blank_row .= "\n";

	return $blank_row;
}

=head2 METHODS

=over 4

=item center($text, $width)

This method takes a text string and a width and centers the text in the
width given. It returns the text string padded with spaces to put the
text in the middle of the width.

=back

=cut

sub center {
	my $self = shift;
	my $text = shift;
	my $width = shift;

	my $padding = int ( ( $width - length($text) ) / 2 );
	my $left = " " x $padding . $text;
	my $right = " " x ($width - length($left));
	return $left . $right;

}

=over 4

=item left_justify($text, $width)

This puts text against the left margin of a table cell, padded with
spaces until it is the specified width.

=back

=cut

sub left_justify {
	my $self = shift;
	my $text = shift;
	my $width = shift;

	return " " . $text . " " x ($width - ( length($text) + 1 ));
}

=over 4

=item right_justify($text, $width)

This method puts text against the right margin of a table cell, padded
with spaces until it is the specified width.

=back

=cut

sub right_justify {
	my $self = shift;
	my $text = shift;
	my $width = shift;

	return " " x ( $width - ( length($text) + 1 )) . $text . " ";
}

=over 4

=item build_row_output( @array )

This method returns a scalar string composed of the rows specified in
the input @array.

=back

=cut

sub build_row_output {
	my $self = shift;
	my $table = $self->table;

	my $rv;
	foreach my $row ( @_ ) {
		if ( $row > $table->row_count ) {
			carp "$row does not exist in the given table.";
			next;
		}
		$rv .= $self->column_marker;
		foreach my $column ( $table->get_columns ) {
			my $format = $column->output_format;
			$rv .= $self->$format(
				$column->get_row($row), 
				$self->_get_width( $column->name ) );
			$rv .= $self->column_marker;
		}
		$rv .= "\n";
		$rv .= $self->_hrule;
	}

	return $rv;
}

=over 4

=item build_column_name_output

This method returns a string scalar composed of column names centered in
the width for each column.

=back

=cut

sub build_column_name_output {
	my $self = shift;

	my $table = $self->table;
	
	my $rv .= $self->_hrule;
	$rv .= $self->column_marker;
	foreach my $column ( $table->get_columns ) {
		$rv .= $self->center( $column->name, 
			$self->_get_width( $column->name ) );
		$rv .= $self->column_marker;
	}
	$rv .= "\n";
	$rv .= $self->_hrule;

	return $rv;
}

=over 4

=item build_table_name_output

This outputs the L<Table::Simple> name attribute centered in its own row. It
returns a string scalar.

=back

=cut

sub build_table_name_output {
	my $self = shift;

	my $table_width = $self->_get_width('_total');

	my $rv;

	$rv .= $self->_hrule;
	$rv .= $self->column_marker;
	$rv .= $self->center($self->table->name, $table_width);
	$rv .= $self->column_marker;
	$rv .= "\n";

	return $rv;

}

=over 4

=item build_table_output

This method returns a string scalar composed of the table name row (if
defined), column names, and all row values.

=back

=cut

sub build_table_output {
	my $self = shift;

	my $rv;

	$rv .= $self->build_table_name_output if defined $self->table->name;
	$rv .= $self->build_column_name_output;
	$rv .= $self->build_row_output( 0..( $self->table->row_count - 1 ) );

	return $rv;
}

=over 4

=item print_table

This method outputs the string scalar from the build_table_output() method
to standard out.

=back

=cut

sub print_table {
	my $self = shift;

	print $self->build_table_output;
}

=head1 LICENSE

Copyright (C) 2010 Mark Allen

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 SEE ALSO

L<Moose>, L<Table::Simple>, L<Table::Simple::Output::Theory>

=cut

__PACKAGE__->meta->make_immutable();
1;
