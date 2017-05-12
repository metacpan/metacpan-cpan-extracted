package Rose::DB::Object::Metadata::Relationship::ManyToOne;

use strict;

use Carp();
use Scalar::Util();

use Rose::DB::Object::Metadata::Relationship;
our @ISA = qw(Rose::DB::Object::Metadata::Relationship);

use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Generic;

our $VERSION = '0.781';

__PACKAGE__->default_auto_method_types(qw(get_set_on_save delete_on_save));

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(class share_db key_columns required manager_class manager_method 
     manager_count_method manager_iterator_method manager_find_method
     manager_delete_method manager_args query_args join_args object_args)
);

use Rose::Object::MakeMethods::Generic
(
  boolean =>
  [
    #'required' => { default => 1 },
    '_share_db' => { default => 1 },
    'with_column_triggers' => { default => 0 },
    'disable_column_triggers',
  ],

  hash =>
  [
    _key_column  => { hash_key  => 'key_columns' },
    _key_columns => { interface => 'get_set_all' },
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
  get_set =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'object_by_key',
  },

  get_set_now =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'object_by_key',  
    interface => 'get_set_now',
  },

  get_set_on_save =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'object_by_key',  
    interface => 'get_set_on_save',
  },

  delete_now =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'object_by_key',  
    interface => 'delete_now',
  },

  delete_on_save =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'object_by_key',  
    interface => 'delete_on_save',
  },
);

sub type { 'many to one' }

sub is_singular { 1 }

sub foreign_class { shift->class(@_) }

sub share_db    { shift->_fk_or_self(share_db => @_)     }
sub key_column  { shift->_fk_or_self(key_column => @_)   }
sub key_columns { shift->_fk_or_self(key_columns => @_)  }

*map_column = \&key_column;
*column_map = \&key_columns;

sub _fk_or_self
{
  my($self, $method) = (shift, shift);

  if((@_ && $method eq 'key_columns') || 
     (@_ > 1 && $method eq 'key_column'))
  {
    $self->{'default_required'} = undef;
  }

  if(my $fk = $self->foreign_key)
  {
    return $fk->$method(@_);
  }

  $method = "_$method"  if($self->can("_$method"));
  return $self->$method(@_);
}

sub method_name
{
  my($self) = shift;

  if(my $fk = $self->foreign_key)
  {
    return $fk->method_name(@_);
  }

  return $self->SUPER::method_name(@_);
}

sub is_ready_to_make_methods
{
  my($self) = shift;

  if(my $fk = $self->foreign_key)
  {
    return $fk->is_ready_to_make_methods(@_);
  }

  return $self->SUPER::is_ready_to_make_methods(@_);
}

sub make_methods
{
  my($self) = shift;

  if(my $fk = $self->foreign_key)
  {
    return $fk->make_methods(@_);
  }

  $self->SUPER::make_methods(@_);

  if($self->with_column_triggers)
  {
    my $method = $self->method_name('get_set_on_save') ||
                 $self->method_name('get_set');

    if($method)
    {
      my $meta = $self->parent or 
        Carp::croak "Missing parent for relationship '", $self->name, "'";

      my $column_map = $self->column_map;

      foreach my $column_name (keys %$column_map)
      {
        my $column   = $meta->column($column_name);
        my $accessor = $column->accessor_method_name;

        my $trigger_name = 'clear_rel_' . $self->name;

        unless(defined $column->builtin_trigger_index('on_set', $trigger_name))
        {
          my $wolumn = Scalar::Util::weaken($column);

          $column->add_builtin_trigger(
            event => 'on_set',
            name  => $trigger_name,
            code  => sub 
            {
              my($obj) = shift;
              return  if($self->{'disable_column_triggers'});
              local $wolumn->{'triggers_disabled'} = 1;
              $obj->$method(undef)  unless(defined $obj->$accessor());
            });
        }
      }
    }
  }
}

sub id
{
  my($self) = shift;

  my $column_map = $self->column_map;

  return $self->parent->class . ' ' .   $self->class . ' ' . 
    join("\0", map { join("\1", lc $_, lc $column_map->{$_}) } sort keys %$column_map) .
    join("\0", map { $_ . '=' . ($self->$_() || 0) } qw(required));
}

sub build_method_name_for_type
{
  my($self, $type) = @_;

  if($type eq 'get_set' || $type eq 'get_set_now' || $type eq 'get_set_on_save')
  {
    return $self->name;
  }
  elsif($type eq 'delete_now' || $type eq 'delete_on_save')
  {
    return 'delete_' . $self->name;
  }

  return undef;
}

sub optional 
{
  my($self) = shift;

  if(@_)
  {
    $self->required(!$_[0]);
  }

  return ! $self->required;
}

*soft = \&optional;

sub required
{
  my($self) = shift;

  my $fk = $self->foreign_key;
  return $fk->referential_integrity(@_)  if($fk);

  return $self->{'required'} = ($_[0] ? 1 : 0)    if(@_);
  return $self->{'required'}  if(defined $self->{'required'});
  return $self->{'default_required'}  if(defined $self->{'default_required'});

  my $meta = $self->parent or 
    Carp::croak "Missing parent for foreign key '", $self->name, "'";

  my $column_map = $self->column_map;

  # If any local key column allows null values, then 
  # the related object is not required.
  foreach my $column_name (keys %$column_map)
  {
    my $column = $meta->column($column_name) 
      or Carp::confess "No such column '$column_name' in table '",
           $self->parent->table, "' referenced from relationship '",
           $self->name, "'";

    unless($column->not_null)
    {
      return $self->{'default_required'} = 0;
    }
  }

  # If the local key columns are the same as the primary key columns
  # then the related object is not required.
  my $local_columns = join("\0", sort keys %$column_map);
  my $pk_columns    = join("\0", sort $meta->primary_key_column_names);

  if($local_columns eq $pk_columns && length($local_columns))
  {
    return $self->{'default_required'} = 0;
  }

  return $self->{'default_required'} = 1;
}

*referential_integrity = \&required;

sub requires_preexisting_parent_object { 0 }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Relationship::ManyToOne - Many to one table relationship metadata object.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Relationship::ManyToOne;

  $rel = Rose::DB::Object::Metadata::Relationship::ManyToOne->new(...);
  $rel->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for relationships in which a many rows in one table may refer to a single row in another table.

This class inherits from L<Rose::DB::Object::Metadata::Relationship>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Relationship> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, ...

=item C<get_set_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'get_set_now'>

=item C<get_set_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'get_set_on_save'>

=item C<delete_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'delete_now'>

=item C<delete_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'delete_on_save'>

=back

See the L<Rose::DB::Object::Metadata::Relationship|Rose::DB::Object::Metadata::Relationship/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 CLASS METHODS

=over 4

=item B<default_auto_method_types [TYPES]>

Get or set the default list of L<auto_method_types|Rose::DB::Object::Metadata::Relationship/auto_method_types>.  TYPES should be a list of relationship method types.  Returns the list of default relationship method types (in list context) or a reference to an array of the default relationship method types (in scalar context).  The default list contains "get_set_on_save" and "delete_on_save".

=back

=head1 OBJECT METHODS

=over 4

=item B<column_map [HASH | HASHREF]>

Get or set a reference to a hash that maps local column names to foreign column names.

=item B<build_method_name_for_type TYPE>

Return a method name for the relationship method type TYPE.  

For the method types "get_set", "get_set_now", and "get_set_on_save", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> is returned.

For the method types "delete_now" and "delete_on_save", the relationship's  L<name|Rose::DB::Object::Metadata::Relationship/name> prefixed with "delete_" is returned.

Otherwise, undef is returned.

=item B<foreign_key [FK]>

Get or set the L<Rose::DB::Object::Metadata::ForeignKey> object to which this object delegates all responsibility.

Many to one relationships encapsulate essentially the same information as foreign keys.  If a foreign key object is stored in this relationship object, then I<all compatible operations are passed through to the foreign key object.>  This includes making object method(s) and adding or modifying the local-to-foreign column map.  In other words, if a L<foreign_key|/foreign_key> is set, the relationship object simply acts as a proxy for the foreign key object.

=item B<is_singular>

Returns true.

=item B<manager_class [CLASS]>

Get or set the name of the L<Rose::DB::Object::Manager>-derived class used to fetch the object.

=item B<manager_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when fetching the object.

=item B<manager_count_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when counting objects.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects_count|Rose::DB::Object::Manager/get_objects_count> if this value is left undefined.

=item B<manager_iterator_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when creating an iterator.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects_iterator|Rose::DB::Object::Manager/get_objects_iterator> if this value is left undefined.

=item B<manager_delete_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when deleting objects.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<delete_objects|Rose::DB::Object::Manager/delete_objects> if this value is left undefined.

=item B<manager_args [HASHREF]>

Get or set a reference to a hash of name/value arguments to pass to the L<manager_method|/manager_method> when fetching the object.  See the documentation for L<Rose::DB::Object::Manager>'s L<get_objects|Rose::DB::Object::Manager/get_objects> method for a full list of valid arguments for use with the C<manager_args> parameter.

B<Note:> when the name of a relationship that has C<manager_args> is used in a L<Rose::DB::Object::Manager> L<with_objects|Rose::DB::Object::Manager/with_objects> or L<require_objects|Rose::DB::Object::Manager/require_objects> parameter value, I<only> the L<sort_by|Rose::DB::Object::Manager/sort_by> argument will be copied from C<manager_args> and incorporated into the query.

=item B<map_column LOCAL [, FOREIGN]>

If passed a local column name LOCAL, return the corresponding column name in the foreign table.  If passed both a local column name LOCAL and a foreign column name FOREIGN, set the local/foreign mapping and return the foreign column name.

=item B<object_args [HASHREF]>

Get or set a reference to a hash of name/value pairs to pass to the L<new|Rose::DB::Object/new> method when constructing the related object.  This attribute conflicts with any use of the C<manager_*> or C<query_args> attributes.

=item B<optional [BOOL]>

This method is the mirror image of the L<required|/required> method.   Passing a true value to this method is the same thing as setting L<required|/required> to false, and vice versa.  Similarly, the return value is the logical negation of L<required|/required>.

=item B<query_args [ARRAYREF]>

Get or set a reference to an array of query arguments to add to the L<query|Rose::DB::Object::Manager/query> passed to the L<manager_method|/manager_method> when fetching the object.

=item B<required [BOOL]>

Get or set the boolean value that determines what happens when the local columns in the L<column_map|/column_map> have L<defined|perlfunc/defined> values, but the object they relate to is not found.  If true, a fatal error will occur when the methods that fetch objects through this relationship are called.  If false, then the methods will simply return undef.

The default is false if one or more of the local columns L<allow null values|Rose::DB::Object::Metadata::Column/not_null> or if the local columns in the column map are the same as the L<primary key columns|Rose::DB::Object::Metadata/primary_key_columns>, true otherwise.

=item B<type>

Returns "many to one".

=item B<with_column_triggers [BOOL]>

Get or set a boolean value that indicates whether or not L<triggers|Rose::DB::Object::Metadata::Column/TRIGGERS> should be added to the local columns in the L<column map|/column_map> in an attempt to keep related objects and local columns in sync.  Defaults to false.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
