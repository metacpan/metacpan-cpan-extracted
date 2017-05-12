package Rose::DB::Object::Util;

use strict;

use Carp;

use Rose::DB::Object::Helpers();

use Rose::DB::Object::Constants
  qw(PRIVATE_PREFIX STATE_IN_DB STATE_LOADING STATE_SAVING MODIFIED_COLUMNS
     ON_SAVE_ATTR_NAME);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = 
  qw(is_in_db is_loading is_saving
     set_state_in_db set_state_loading set_state_saving
     unset_state_in_db unset_state_loading unset_state_saving
     row_id column_value_formatted_key column_value_is_inflated_key
     column_value_formatted_key_for_db 
     lazy_column_values_loaded_key modified_column_names has_modified_columns
     has_modified_children has_loaded_related set_column_value_modified
     unset_column_value_modified get_column_value_modified
     post_save_set_related_objects_code post_save_add_related_objects_code
     pre_save_set_foreign_object_code);

our %EXPORT_TAGS = 
(
  all          => \@EXPORT_OK,
  get_state    => [ qw(is_in_db is_loading is_saving) ],
  set_state    => [ qw(set_state_in_db set_state_loading set_state_saving) ],
  unset_state  => [ qw(unset_state_in_db unset_state_loading unset_state_saving) ],
  columns      => [ qw(set_column_value_modified get_column_value_modified 
                       unset_column_value_modified modified_column_names 
                       has_modified_columns) ],
  children     => [ qw(has_modified_children has_loaded_related) ],
  on_save_code => [ qw(post_save_set_related_objects_code 
                       post_save_add_related_objects_code
                       pre_save_set_foreign_object_code) ],
);

$EXPORT_TAGS{'state'} = [ map { @$_ } @EXPORT_TAGS{qw(get_state set_state unset_state)} ];

our $VERSION = '0.772';

sub is_in_db   { shift->{STATE_IN_DB()}   }
sub is_loading { shift->{STATE_LOADING()} }
sub is_saving  { shift->{STATE_SAVING()}  }

sub set_state_in_db   { shift->{STATE_IN_DB()} = 1   }
sub set_state_loading { shift->{STATE_LOADING()} = 1 }
sub set_state_saving  { shift->{STATE_SAVING()} = 1  }

sub unset_state_in_db   { shift->{STATE_IN_DB()} = 0   }
sub unset_state_loading { shift->{STATE_LOADING()} = 0 }
sub unset_state_saving  { shift->{STATE_SAVING()} = 0  }

sub get_column_value_modified
{
  my($object, $name) = (shift, shift);
  return $object->{MODIFIED_COLUMNS()}{$name};
}

sub set_column_value_modified
{
  my($object, $name) = (shift, shift);
  my $key = column_value_formatted_key_for_db($object->meta->column($name)->hash_key, $object->db);
  delete $object->{$key};
  return $object->{MODIFIED_COLUMNS()}{$name} = 1;
}

sub unset_column_value_modified
{
  my($object, $name) = (shift, shift);
  return delete $object->{MODIFIED_COLUMNS()}{$name};
}

sub modified_column_names
{
  keys(%{shift->{MODIFIED_COLUMNS()} || {}});
}

sub has_modified_columns
{
  if(@_ > 1 && !$_[1])
  {
    shift->{MODIFIED_COLUMNS()} = {};
  }

  scalar %{shift->{MODIFIED_COLUMNS()} || {}}
}

sub has_loaded_related 
{
  if(@_ == 2) # $object, $name
  {
    return Rose::DB::Object::Helpers::has_loaded_related(@_);
  }

  my %args = @_;
  my $object = delete $args{'object'} or croak "Missing object parameter";

  Rose::DB::Object::Helpers::has_loaded_related($object, %args);
}

sub has_modified_children
{
  my($self) = shift;

  my $meta = $self->meta;

  foreach my $fk ($meta->foreign_keys)
  {
    my $foreign_object = $fk->object_has_foreign_object($self) || next;

    if(has_modified_columns($foreign_object) || 
       has_modified_children($foreign_object))
    {
      return 1;
    }
  }

  foreach my $rel ($meta->relationships)
  {
    my $related_objects = $rel->object_has_related_objects($self) || next;

    foreach my $rel_object (@$related_objects)
    {
      if(has_modified_columns($rel_object) || 
         has_modified_children($rel_object))
      {
        return 1;
      }
    }
  }

  return 0;
}

# XXX: A value that is unlikely to exist in a primary key column value
use constant PK_JOIN => "\0\2,\3\0";

sub row_id
{
  my($object) = shift;

  my $meta = $object->meta or croak "$object has no meta attribute";

  return 
    join(PK_JOIN, 
         map { $object->$_() } 
         map { $meta->column_accessor_method_name($_) }
         $meta->primary_key_column_names);
}

sub column_value_formatted_key
{
  my($key) = shift;
  return PRIVATE_PREFIX . "_${key}_formatted";
}

sub column_value_formatted_key_for_db
{
  my($key, $db) = @_;
  return join($;, column_value_formatted_key($key),  $db->driver || 'unknown');
}

sub column_value_is_inflated_key
{
  my($key) = shift;
  return PRIVATE_PREFIX . "_${key}_is_inflated";
}

sub lazy_column_values_loaded_key
{
  my($key) = shift;
  return PRIVATE_PREFIX . "_lazy_loaded";
}

sub post_save_set_related_objects_code
{
  my($object, $rel_name, $code) = @_;

  if(@_ > 2)
  {
    if(defined $code)
    {
      return $object->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'} = $code;
    }
    else
    {
      return delete $object->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
    }
  }

  return $object->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
}

sub post_save_add_related_objects_code
{
  my($object, $rel_name, $code) = @_;

  if(@_ > 2)
  {
    if(defined $code)
    {
      return $object->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'} = $code;
    }
    else
    {
      return delete $object->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};
    }
  }

  return $object->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};
}

sub pre_save_set_foreign_object_code
{
  my($object, $fk_name, $code) = @_;

  if(@_ > 2)
  {
    if(defined $code)
    {
      return $object->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'} = $code;
    }
    else
    {
      return delete $object->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'};
    }
  }

  return $object->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'};
}

1;

__END__

=head1 NAME

Rose::DB::Object::Util - Utility functions for use in Rose::DB::Object subclasses and method makers.

=head1 SYNOPSIS

  package MyDBObject;

  use Rose::DB::Object::Util qw(:all);

  use Rose::DB::Object;
  our @ISA = qw(Rose::DB::Object);
  ...
  sub whatever
  {
    my($self) = shift;
    ...
    if(is_loading($self)) 
    {
      ...
      set_state_in_db($self);
    }
    ...
  }

=head1 DESCRIPTION

L<Rose::DB::Object::Util> provides functions that are useful for developers who are subclassing L<Rose::DB::Object> or otherwise extending or modifying its behavior.

L<Rose::DB::Object>s have some awareness of their current situation.  Certain optimizations rely on this awareness.  For example, when loading column values directly from the database, there's no reason to validate the format of the data or immediately "inflate" the values.  The L<is_loading|/is_loading> function will tell you when these steps can safely be skipped.

Similarly, it may be useful to set these state characteristics in your code.  The C<set_sate_*> functions provide that ability.

=head1 EXPORTS

C<Rose::DB::Object::Util> does not export any function names by default.

The 'get_state' tag:

    use Rose::DB::Object::Util qw(:get_state);

will cause the following function names to be imported:

    is_in_db()
    is_loading()
    is_saving()

The 'set_state' tag:

    use Rose::DB::Object::Util qw(:set_state);

will cause the following function names to be imported:

    set_state_in_db()
    set_state_loading()
    set_state_saving()

The 'unset_state' tag:

    use Rose::DB::Object::Util qw(:unset_state);

will cause the following function names to be imported:

    unset_state_in_db()
    unset_state_loading()
    unset_state_saving()

the 'state' tag:

    use Rose::DB::Object::Util qw(:unset_state);

will cause the following function names to be imported:

    is_in_db()
    is_loading()
    is_saving()
    set_state_in_db()
    set_state_loading()
    set_state_saving()
    unset_state_in_db()
    unset_state_loading()
    unset_state_saving()

The 'columns' tag:

    use Rose::DB::Object::Util qw(:columns);

will cause the following function names to be imported:

    get_column_value_modified()
    set_column_value_modified()
    unset_column_value_modified()
    modified_column_names()
    has_modified_columns()

The 'children' tag:

    use Rose::DB::Object::Util qw(:children);

will cause the following function names to be imported:

    has_loaded_related()
    has_modified_children()

The 'all' tag:

    use Rose::DB::Object::Util qw(:all);

will cause the following function names to be imported:

    is_in_db()
    is_loading()
    is_saving()

    set_state_in_db()
    set_state_loading()
    set_state_saving()

    unset_state_in_db()
    unset_state_loading()
    unset_state_saving()

    get_column_value_modified()
    set_column_value_modified()
    unset_column_value_modified()
    modified_column_names()
    has_modified_columns()

    has_loaded_related()
    has_modified_children()

=head1 FUNCTIONS

=over 4

=item B<get_column_value_modified OBJECT, COLUMN>

Returns true if the column named COLUMN in OBJECT is modified, false otherwise.

=item B<has_loaded_related [ OBJECT, NAME | PARAMS ]>

Given an OBJECT and a foreign key or relationship name, return true if one or more related objects have been loaded into OBJECT, false otherwise.

If the name is passed as a plain string NAME, then a foreign key with that name is looked up.  If no such foreign key exists, then a relationship with that name is looked up.  If no such relationship or foreign key exists, a fatal error will occur.  Example:

    has_loaded_related($object, 'bar');

It's generally not a good idea to add a foreign key and a relationship with the same name, but it is technically possible.  To specify the domain of the name, pass the name as the value of a C<foreign_key> or C<relationship> parameter.  You must also pass the object as the value of the C<object> parameter.  Example:

    has_loaded_related(object => $object, foreign_key => 'bar');
    has_loaded_related(object => $object, relationship => 'bar');

=item B<has_modified_children OBJECT>

Returns true if OBJECT L<has_loaded_related|/has_loaded_related> objects, at least one of which L<has_modified_columns|/has_modified_columns> or L<has_modified_children|/has_modified_children>, false otherwise.

=item B<has_modified_columns OBJECT>

Returns true if OBJECT has any modified columns, false otherwise.

=item B<is_in_db OBJECT>

Given the L<Rose::DB::Object>-derived object OBJECT, returns true if the object was L<load|Rose::DB::Object/load>ed from, or has ever been L<save|Rose::DB::Object/save>d into, the database, or false if it has not.

=item B<is_loading OBJECT>

Given the L<Rose::DB::Object>-derived object OBJECT, returns true if the object is currently being L<load|Rose::DB::Object/load>ed, false otherwise.

=item B<is_saving OBJECT>

Given the L<Rose::DB::Object>-derived object OBJECT, returns true if the object is currently being L<save|Rose::DB::Object/save>d, false otherwise.

=item B<modified_column_names OBJECT>

Returns a list containing the names of all the modified columns in OBJECT.

=item B<set_column_value_modified OBJECT, COLUMN>

Mark the column named COLUMN in OBJECT as modified.

=item B<unset_column_value_modified OBJECT, COLUMN>

Clear the modified mark, if any, on the column named COLUMN in OBJECT.

=item B<set_state_in_db OBJECT>

Mark the L<Rose::DB::Object>-derived object OBJECT as having been L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d into the database at some point in the past.

=item B<set_state_loading OBJECT>

Indicate that the L<Rose::DB::Object>-derived object OBJECT is currently being L<load|Rose::DB::Object/load>ed from the database.

=item B<set_state_saving OBJECT>

Indicate that the L<Rose::DB::Object>-derived object OBJECT is currently being L<save|Rose::DB::Object/save>d into the database.

=item B<unset_state_in_db OBJECT>

Mark the L<Rose::DB::Object>-derived object OBJECT as B<not> having been L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d into the database at some point in the past.

=item B<unset_state_loading OBJECT>

Indicate that the L<Rose::DB::Object>-derived object OBJECT is B<not> currently being L<load|Rose::DB::Object/load>ed from the database.

=item B<unset_state_saving OBJECT>

Indicate that the L<Rose::DB::Object>-derived object OBJECT is B<not> currently being L<save|Rose::DB::Object/save>d into the database.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
