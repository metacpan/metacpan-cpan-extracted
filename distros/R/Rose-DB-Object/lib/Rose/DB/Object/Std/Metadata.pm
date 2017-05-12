package Rose::DB::Object::Std::Metadata;

use strict;

use Carp();

use Rose::DB::Object::Metadata::PrimaryKey;

use Rose::DB::Object::Metadata;
our @ISA = qw(Rose::DB::Object::Metadata);

our $VERSION = '0.02';

sub init_primary_key
{
  Rose::DB::Object::Metadata::PrimaryKey->new(parent => shift, columns => 'id');
}

sub primary_key_column_names { wantarray ? 'id' : [ 'id' ] }

sub add_primary_key_column
{
  Carp::croak __PACKAGE__, " objects are required to have a single primary key named 'id'"
    unless((ref $_[1] && $_[1][0] eq 'id') || $_[1] eq 'id');

  # No point in doing this...
  #shift->SUPER::add_primary_key(@_);
}

*add_primary_key_columns = \&add_primary_key_columns;

sub generate_primary_key_placeholders { shift; shift->generate_primary_key_placeholders(@_) }

sub initialize
{
  my($self) = shift;

  my $id_column = $self->column('id');

  unless($id_column)
  {
    $self->add_column(id => { primary_key => 1 });
    $id_column = $self->column('id');
  }

  $self->SUPER::initialize(@_);
}

1;

__END__

=head1 NAME

Rose::DB::Object::Std::Metadata - Standardized database object metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Std::Metadata;

  $meta = Rose::DB::Object::Std::Metadata->new(class => 'Product');
  # ...or...
  # $meta = Rose::DB::Object::Std::Metadata->for_class('Product');

  $meta->table('products');

  $meta->columns
  (
    id          => { type => 'int', primary_key => 1 },
    name        => { type => 'varchar', length => 255 },
    description => { type => 'text' },
    category_id => { type => 'int' },

    status => 
    {
      type      => 'varchar', 
      check_in  => [ 'active', 'inactive' ],
      default   => 'inactive',
    },

    start_date  => { type => 'datetime' },
    end_date    => { type => 'datetime' },

    date_created     => { type => 'timestamp', default => 'now' },  
    last_modified    => { type => 'timestamp', default => 'now' },
  );

  $meta->add_unique_key('name');

  $meta->foreign_keys
  (
    category =>
    {
      class       => 'Category',
      key_columns =>
      {
        category_id => 'id',
      }
    },
  );

  ...

=head1 DESCRIPTION

C<Rose::DB::Object::Std::Metadata> is a subclass of L<Rose::DB::Object::Metadata> that is designed to serve the needs of L<Rose::DB::Object::Std> objects.  See the L<Rose::DB::Object::Std> documentations for information on what differentiates it from L<Rose::DB::Object>.

Only the methods that are overridden are documented here.  See the L<Rose::DB::Object::Metadata> documentation for the rest.

=head1 OBJECT METHODS

=over 4

=item B<add_primary_key_column COLUMN>

This method is an alias for the C<add_primary_key_columns()> method.

=item B<add_primary_key_columns COLUMNS>

Since L<Rose::DB::Object::Std> objects must have a single primary key column named "id", calling this method with a COLUMNS argument of anything other than the column name "id" or a reference to an array containing the column name "id" will cause a fatal error.

In general, you do not need to use this method at all since the C<primary_key_columns()> method is hard-coded to always return "id".

=item B<initialize [ARGS]>

This method does the same thing as the L<Rose::DB::Object::Metadata> method of the same name, with one exception.  If there is no column named "id" in the list of columns, a scalar primary key column named "id" is added to the column list.  Then initialization proceeds as usual.

=item B<primary_key_columns>

Always returns the column name "id" (in list context) or a reference to an array containing the column name "id" (in scalar context).

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
