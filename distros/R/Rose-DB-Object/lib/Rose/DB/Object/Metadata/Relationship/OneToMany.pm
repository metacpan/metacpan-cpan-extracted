package Rose::DB::Object::Metadata::Relationship::OneToMany;

use strict;

use Carp();

use Rose::DB::Object::Metadata::Relationship;
our @ISA = qw(Rose::DB::Object::Metadata::Relationship);

use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Generic;

our $Debug = 0;

our $VERSION = '0.781';

__PACKAGE__->default_auto_method_types(qw(find get_set_on_save add_on_save));

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(class share_db key_columns manager_class manager_method 
     manager_count_method manager_iterator_method manager_find_method
     manager_args query_args join_args)
);

use Rose::Object::MakeMethods::Generic
(
  boolean =>
  [
    'share_db' => { default => 1 },
  ],

  hash =>
  [
    key_column  => { hash_key  => 'key_columns' },
    key_columns => { interface => 'get_set_all' },
  ],
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => 
  [
    __PACKAGE__->common_method_maker_argument_names
  ],
);

__PACKAGE__->method_maker_info
(
  count =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'count',
  },

  find =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'find',
  },

  iterator =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'iterator',
  },

  get_set =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'get_set',
  },

  get_set_now =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'get_set_now',
  },

  get_set_on_save =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'get_set_on_save',
  },

  add_now => 
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'add_now',
  },

  add_on_save => 
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_key',
    interface => 'add_on_save',
  },
);

sub type { 'one to many' }

sub is_singular { 0 }

sub foreign_class { shift->class(@_) }

*map_column = \&key_column;
*column_map = \&key_columns;

sub id
{
  my($self) = shift;

  my $column_map = $self->column_map;

  return $self->parent->class . ' ' .   $self->class . ' ' . 
    join("\0", map { join("\1", lc $_, lc $column_map->{$_}) } sort keys %$column_map);
    #join("\0", map { $_ . '=' . ($self->$_() || 0) } qw(required));
}

sub build_method_name_for_type
{
  my($self, $type) = @_;

  if($type eq 'get_set' || $type eq 'get_set_now' || $type eq 'get_set_on_save')
  {
    return $self->name;
  }
  elsif($type eq 'add_now' || $type eq 'add_on_save')
  {
    return 'add_' . $self->name;
  }
  elsif($type eq 'find')
  {
    return 'find_' . $self->name;
  }
  elsif($type eq 'iterator')
  {
    return $self->name . '_iterator';
  }
  elsif($type eq 'count')
  {
    return $self->name . '_count';
  }

  return undef;
}

sub is_ready_to_make_methods 
{
  my($self) = shift;

  if($Debug || $Rose::DB::Object::Metadata::Debug)
  {
    my $error;

    if(!$self->class)
    {
      $error = "does not belong to a class";
    }
    elsif(!$self->key_columns && !$self->query_args)
    {
      $error = "has no key columns or query args";
    }

    warn $self->parent->class, ': one-to-many relationship ', $self->name, " NOT READY - $error"
      if($error);
  }

  return $self->class && ($self->key_columns || $self->query_args) ? 1 : 0;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Relationship::OneToMany - One to many table relationship metadata object.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Relationship::OneToMany;

  $rel = Rose::DB::Object::Metadata::Relationship::OneToMany->new(...);
  $rel->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for relationships in which a single row from one table refers to multiple rows in another table.

This class inherits from L<Rose::DB::Object::Metadata::Relationship>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Relationship> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<count>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, C<interface =E<gt> 'count'> ...

=item C<find>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, C<interface =E<gt> 'find'> ...

=item C<iterator>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, C<interface =E<gt> 'iterator'> ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, 
C<interface =E<gt> 'get_set'> ...

=item C<get_set_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, C<interface =E<gt> 'get_set_now'> ...

=item C<get_set_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, C<interface =E<gt> 'get_set_on_save'> ...

=item C<add_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, C<interface =E<gt> 'add_now'> ...

=item C<add_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_key|Rose::DB::Object::MakeMethods::Generic/objects_by_key>, C<interface =E<gt> 'add_on_save'> ...

=back

See the L<Rose::DB::Object::Metadata::Relationship|Rose::DB::Object::Metadata::Relationship/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 CLASS METHODS

=over 4

=item B<default_auto_method_types [TYPES]>

Get or set the default list of L<auto_method_types|Rose::DB::Object::Metadata::Relationship/auto_method_types>.  TYPES should be a list of relationship method types.  Returns the list of default relationship method types (in list context) or a reference to an array of the default relationship method types (in scalar context).  The default list contains "find", "get_set_on_save", and "add_on_save".

=back

=head1 OBJECT METHODS

=over 4

=item B<build_method_name_for_type TYPE>

Return a method name for the relationship method type TYPE.  

For the method types "get_set", "get_set_now", and "get_set_on_save", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> is returned.

For the method types "add_now" and "add_on_save", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> prefixed with "add_" is returned.

For the method type "find", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> prefixed with "find_" is returned.

For the method type "count", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> suffixed with "_count" is returned.

For the method type "iterator", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> suffixed with "_iterator" is returned.

Otherwise, undef is returned.

=item B<is_singular>

Returns false.

=item B<manager_class [CLASS]>

Get or set the name of the L<Rose::DB::Object::Manager>-derived class used to fetch objects.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<Rose::DB::Object::Manager> if this value is left undefined.

B<Note:> when the name of a relationship that has C<manager_args> is used in a L<Rose::DB::Object::Manager> L<with_objects|Rose::DB::Object::Manager/with_objects> or L<require_objects|Rose::DB::Object::Manager/require_objects> parameter value, I<only> the L<sort_by|Rose::DB::Object::Manager/sort_by> argument will be copied from C<manager_args> and incorporated into the query.

=item B<manager_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when fetching objects.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects|Rose::DB::Object::Manager/get_objects> if this value is left undefined.

=item B<manager_count_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when counting objects.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects_count|Rose::DB::Object::Manager/get_objects_count> if this value is left undefined.

=item B<manager_iterator_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when creating an iterator.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects_iterator|Rose::DB::Object::Manager/get_objects_iterator> if this value is left undefined.

=item B<manager_args [HASHREF]>

Get or set a reference to a hash of name/value arguments to pass to the L<manager_method|/manager_method> when fetching objects.  For example, this can be used to enforce a particular sort order for objects fetched via this relationship.  For example:

  Product->meta->add_relationship
  (
    code_names =>
    {
      type         => 'one to many',
      class        => 'CodeName',
      column_map   => { id => 'product_id' },
      manager_args => 
      {
        sort_by => CodeName->meta->table . '.name',
      },
    },
  );

This would ensure that a C<Product>'s C<code_names()> are listed in alphabetical order.  Note that the "name" column is prefixed by the name of the table fronted by the C<CodeName> class.  This is important because several tables may have a column named "name."  If this relationship is used to form a JOIN in a query along with one of those tables, then the "name" column will be ambiguous.  Adding a table name prefix disambiguates the column name.

Also note that the table name is not hard-coded.  Instead, it is fetched from the L<Rose::DB::Object>-derived class that fronts the table.  This is more verbose, but is a much better choice than including the literal table name when it comes to long-term maintenance of the code.

See the documentation for L<Rose::DB::Object::Manager>'s L<get_objects|Rose::DB::Object::Manager/get_objects> method for a full list of valid arguments for use with the C<manager_args> parameter, but remember that you can define your own custom L<manager_class|/manager_class> and thus can also define what kinds of arguments C<manager_args> will accept.

=item B<map_column LOCAL [, FOREIGN]>

If passed a local column name LOCAL, return the corresponding column name in the foreign table.  If passed both a local column name LOCAL and a foreign column name FOREIGN, set the local/foreign mapping and return the foreign column name.

=item B<column_map [HASH | HASHREF]>

Get or set a reference to a hash that maps local column names to foreign column names.

=item B<query_args [ARRAYREF]>

Get or set a reference to an array of query arguments to add to the L<query|Rose::DB::Object::Manager/query> passed to the L<manager_method|/manager_method> when fetching objects.

=item B<type>

Returns "one to many".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
