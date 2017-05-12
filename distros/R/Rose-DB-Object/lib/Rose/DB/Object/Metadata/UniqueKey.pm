package Rose::DB::Object::Metadata::UniqueKey;

use strict;

use Rose::DB::Object::Metadata::Util qw(perl_quote_value);

use Rose::DB::Object::Metadata::ColumnList;
our @ISA = qw(Rose::DB::Object::Metadata::ColumnList);

our $VERSION = '0.782';

use Rose::Object::MakeMethods::Generic
(
  'scalar --get_set_init' =>
  [
    'name'
  ],

  boolean => 'has_predicate',
);

sub init_name { join('_', shift->column_names) || undef }

sub perl_array_definition
{
  '[ ' . join(', ', map { perl_quote_value($_) } shift->column_names) . ' ]'
}

sub perl_object_definition
{
  my($self) = shift;

  return ref($self) . '->new(name => ' . perl_quote_value($self->name) . 
         ', columns => [ ' . 
         join(', ', map { perl_quote_value($_) } $self->column_names) . ' ])';
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::UniqueKey - Unique key metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::UniqueKey;

  $uk = Rose::DB::Object::Metadata::UniqueKey->new(
          columns => [ 'name', 'color' ]);

  MyClass->meta->add_unique_key($uk);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for unique keys in a database table.  Each unique key is made up of one or more columns.

=head1 OBJECT METHODS

=over 4

=item B<add_column [COLUMNS]>

This method is an alias for the L<add_columns|/add_columns> method.

=item B<add_columns [COLUMNS]>

Add COLUMNS to the list of columns that make up the unique key.  COLUMNS must be a list or reference to an array of  column names or L<Rose::DB::Object::Metadata::Column>-derived objects.

=item B<columns [COLUMNS]>

Get or set the list of columns that make up the unique key.  COLUMNS must a list or reference to an array of column names or L<Rose::DB::Object::Metadata::Column>-derived objects.

This method returns all of the columns that make up the unique key.  Each column is a L<Rose::DB::Object::Metadata::Column>-derived column object if the unique key's L<parent|/parent> has a column object with the same name, or just the column name otherwise.  In scalar context, a reference to an array of columns is returned.  In list context, a list is returned.

=item B<column_names>

Returns a list (in list context) or reference to an array (in scalar context) of the names of the columns that make up the unique key.

=item B<delete_columns>

Delete the entire list of columns that make up the unique key.

=item B<name [NAME]>

Get or set the name of the unique key.  This name should be unique among all unique keys for a given table.  Traditionally, it is the name of the index that the database uses to maintain the unique key, but practices vary.  If left undefined, the default value is a string created by joining the L<column_names|/column_names> with underscores.

=item B<parent [META]>

Get or set the L<Rose::DB::Object::Metadata>-derived object that this unique key belongs to.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
