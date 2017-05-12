package Table::Simple::Column;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 NAME

Table::Simple::Column - A collection of data points organized into rows

=head1 DESCRIPTION

Typically you want to use this module in conjunction with L<Table::Simple>
table object.

=head2 ATTRIBUTES

=over 4

=item width

This attribute stores the length of the widest element in the column including
the name of the column.

=back

=cut

has 'width' => (
	is => 'rw',
	isa => 'Int',
	lazy_build => 1,
);

=over 4

=item name

This is a required attribute which stores the name of the column. It should
match the name of an attribute on a class to be scanned by the software.

=back

=cut

has 'name' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

=over 4

=item output_format

This attribute controls the output layout. This should match a method in
L<Table::Simple::Output> or a subclass of that. The following methods
are available in the standard L<Table::Simple::Output> class:

=over 4

=item left_justify

=item center

=item right_justify

=back

=back

=cut

has 'output_format' => (
	is => 'rw',
	isa => 'Str',
	default => 'left_justify',
);

=over 4

=item rows

This attribute is a collection of data elements corresponding to the
attribute values matching the column name.

This attribute has a number of methods which permit you to manipulate
the collection.

=back

=cut

has 'rows' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	traits => [ 'Array' ],
	default => sub { [] },
	handles => {
		'add_row' => 'push',
		'get_rows' => 'elements',
		'get_row' => 'get',
	},
	lazy => 1,
);

after 'add_row' => sub {
	my $self = shift;
	my $new = shift;

	if ( length($new) > $self->width ) {
		$self->width( length($new) );
	}
};

=head2 METHODS

=over 4

=item add_row( $string )

This method adds a new row value (string scalar) to the collection.

=item get_rows

This method returns all values stored in the collection. It preserves the
order in which values were added to the collection.

=item get_row

This method returns a specific value stored in collection. It takes the
desired value's index as input and returns the value as output.

=back

=cut

sub _build_width {
	my $self = shift;

	return $self->name ? length($self->name) : 0;
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

L<Moose>, L<Table::Simple>, L<Table::Simple::Output>

=cut

__PACKAGE__->meta->make_immutable();
1;
