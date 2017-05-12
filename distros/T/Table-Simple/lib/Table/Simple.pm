package Table::Simple;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Tie::IxHash;
use Carp qw(carp);
use overload;

use Table::Simple::Column;

our $VERSION = 0.02;

=head1 NAME

Table::Simple - Easily output perl object attributes to an ASCII table

=head1 SYNOPSIS

    use Table::Simple;
    use Table::Simple::Output;
    use My::Data;
    use My::Data::Collection;

    my $collection = new My::Data::Collection;
    my $data = My::Data->new( a => 1, b => "foo", baz => 0.1 );
    $collection->add($data1);

    # Lather, rinse, repeat last two lines.

    my $table = new Table::Simple;

    foreach my $data ( $collection->get_data ) {
         $table->extract_row( $data );
    }

    my $table_output = Table::Simple::Output->new( table => $table );
    $table_output->print_table;

=head1 DESCRIPTION

Oh good grief, another table formatter? Really? 

Yes, and I had a good reason - I didn't find anything that did what I wanted, 
which was to lazily extract attribute names and values from objects without 
me having to tell the formatter what they were.

So, given one or more perl objects (either a plain old blessed hashref or 
a Moose object) this module will pull the attribute names and values and 
then output them into a formmatted ASCII table. This might be useful to you
if you want to take a bunch of perl objects and say, dump them into Markdown
for ultra lazy wiki pages which document the states of various things. (That's
what I will be using this module for myself.)

I also wanted to use Moose in a project which wouldn't take a LOT of time to
complete, but wasn't just a trivial contrived exercise either.

This module is well behaved by skipping attributes which begin with an 
underscore and prevent you from adding columns after you've processed
any rows.

=head2 ATTRIBUTES

=over 4

=item type

This attribute stores the type of a passed object, so you can't combine
objects of type "Foo" with type "Bar."

This is set automatically, so you normally shouldn't need to manipulate it.

=back

=cut

has 'type' => (
	is => 'rw',
	isa => 'Str',
);


=over 4

=item row_count

This attribute stores the number of rows that have been processed by the 
table so far.  It's a read-only attribute.

=back

=cut

has 'row_count' => (
	traits => ['Counter'],
	is => 'ro',
	isa => 'Int',
	default => 0,
	handles => {
		'_inc_row_count' => 'inc',
	},
);

=over 4

=item columns

This attribute is a collection of L<Table::Simple::Column> objects which 
represent the attribute names of the perl objects being processed.

This attribute has a number of methods which permit you to manipulate
how columns are interpreted and formatted for output.

=back

=cut


has 'columns' => (
	is => 'ro',
	isa => 'Tie::IxHash',
	builder => '_columns_builder',
	handles => {
		'get_columns'       => 'Values',
		'reorder_columns'   => 'Reorder',
		'delete_column'     => 'Delete',
		'has_columns'       => 'Length',
		'get_column_names'  => 'Keys',
	},
);

=over 4

=item name

You can optionally supply a name to the table which will be the title of a
table in the output phase.

=back

=cut

has 'name' => (
	is => 'rw',
	isa => 'Str',
);

=head2 METHODS

=over 4

=item get_columns

This method gets all columns, preserving the order in which they were
added to the collection.

=item reorder_columns

This method changes the order of columns. B<NOTE:> Any columns which are omitted will be deleted!

=item delete_column

Delete the given column from the collection.

=item has_columns

This method returns true if the collection has any columns. (See has_column to test whether a specific column exists.)

=item get_column_names

This method returns the names of all columns, preserving the order in which
they were added to the collection.


=item has_column

This method returns true if the columns attribute contains the column name
given.

=back

=cut

sub has_column {
	my $self = shift;
	my $column_name = shift;

	return 1 if defined $self->columns->Indices($column_name);
	return 0;
}

=over 4

=item get_column

This method gets the L<Table::Simple::Column> object with the given name.

=back

=cut

sub get_column {
	my $self = shift;
	my $column_name = shift;

	if ( $self->has_column($column_name) ) {
		return $self->columns->Values($self->columns->Indices($column_name));
	}
	else {
		carp "$column_name does not exist.";
		return;
	}
}

=over 4

=item add_column

This method adds a L<Table::Simple::Column> object to the columns collection.
You normally shouldn't need to do this.

=back

=cut

sub add_column {
	my $self = shift;
	my $arg = shift;

	if ( not ( blessed($arg) && $arg->isa("Table::Simple::Column") ) ) {
		carp "The add_column method only accepts Table::Simple::Column objects.\n";
		return;
	}

	$self->columns->Push($arg->name() => $arg);
}

sub _columns_builder {
	my $self = shift;

	return Tie::IxHash->new(@_);
}

=over 4

=item extract_columns

Given a perl object, this method extracts the non-private attribute names
(that is, those which do not start with an underscore) and creates 
L<Table::Simple::Column> objects for them.  It preserves the order in 
which columns were added to the collection.

It will complain if you pass an argument that isn't blessed, or if you
try to extract columns after you've added rows.

=back

=cut

sub extract_columns {
	my $self = shift;
	my $arg = shift;

	if ( not defined $self->type() ) {
		$self->set_type($arg);
	}

	if ( ! blessed($arg) ) {
		carp "Your argument is not blessed.";
		return;
	}

	if ( blessed($arg) ne $self->type() ) {
		carp "Your argument is not of type " . $self->type() . "\n";
		return;
	}

	if ( $self->row_count > 0 ) {
		carp "You already added rows to this table.\n";
		return;
	}

	my $rv;

	if ( $self->_is_moose_object($arg) ) {
		$rv = $self->_extract_columns_moose($arg);
	}
	elsif ( overload::StrVal($arg) =~ /HASH/ ) {
		$rv = $self->_extract_columns_hashref($arg);
	}
	else {
		carp "I don't know how to process your argument.\n";
		return;
	}

	return $rv;
}

=over 4

=item set_type

This method sets the type attribute based on the perl object's package name.

=back

=cut

sub set_type {
	my $self = shift;
	my $arg = shift;

	if ( not blessed $arg ) {
		carp "$arg does not appear to be a blessed object.\n";
		return;
	}

	$self->type(blessed $arg);
}

sub _extract_columns_moose {
	my $self = shift;
	my $object = shift;

	foreach my $attribute_name ( $object->meta->get_attribute_list ) {
		next if $self->_is_private_attribute( $attribute_name );

		my $column;

		if ( not $self->has_column( $attribute_name ) ) {
			$column = new Table::Simple::Column(name => $attribute_name);
		}
		$self->add_column($column) if defined $column;
	}

	return $self->has_columns;

}

sub _extract_columns_hashref {
	my $self = shift;
	my $hashref = shift;

	foreach my $key ( keys %{ $hashref } ) {
		next if $self->_is_private_attribute( $key );

		my $column;

		if ( not $self->has_column( $key ) ) {
			$column = new Table::Simple::Column(name => $key);
		}
		$self->add_column($column) if defined $column;
	}

	return $self->has_columns;
}

=over 4

=item extract_row

This method extract row values from attribute names in a given perl object.

If you haven't already set the table type, or extract columns, this method
will automagically do that.

It returns the current row count.

=back

=cut

sub extract_row {
	my $self = shift;
	my $object = shift;

	if ( ! $self->has_columns ) {
		$self->extract_columns($object);
	}

	if ( blessed $object ne $self->type() ) {
		carp "Your object is not of type " . $self->type() . "\n";
		return;
	}

	$self->_inc_row_count;	

	foreach my $column ( $self->get_columns ) {
		my $value;
		if ( $self->_is_moose_object($object) ) {
			$value = $self->_get_value_using_introspection
				( $object, $column->name() );
		}
		else {
			$value = ref $object->{$column->name} 
				? dump($object->{$column->name}) 
				: $object->{$column->name}
				;
		}
		$column->add_row($value) if defined $value;
	}

	return $self->row_count;
}

sub _is_private_attribute {
	my $self = shift;
	my $attr_name = shift;

	if ( $attr_name =~ /^_+/ ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub _is_moose_object {
	my $self = shift;
	my $object = shift;

	return 1 if ( blessed($object) && $object->can("meta") );
	return 0;
}

sub _get_value_using_introspection {
	my $self = shift;
	my $object = shift;
	my $attribute_name = shift;

	if ( not $object->meta->has_attribute($attribute_name) ) {
		carp "Your object doesn't seem to have an attribute named $attribute_name.\n";
		return;
	}

	my $mop_attribute = $object->meta->get_attribute($attribute_name);

	if ( not $mop_attribute->has_read_method ) {
		carp "$attribute_name doesn't seem to have a read method!\n";
		return;
	}

	my $read_method = $mop_attribute->get_read_method;

	return $object->$read_method();

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

L<Moose>, L<Table::Simple::Column>, L<Table::Simple::Output>

=cut

__PACKAGE__->meta->make_immutable();
1;
