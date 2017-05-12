package Rose::DB::Object::Metadata::ForeignKey;

use strict;

use Carp();
use Scalar::Util();

use Rose::DB::Object::Metadata::Util qw(:all);

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

use Rose::DB::Object::Exception;

our $VERSION = '0.784';

our $Debug = 0;

use overload
(
  # "Undo" inherited overloaded stringification.  
  # (Using "no overload ..." didn't seem to work.)
  '""' => sub { overload::StrVal($_[0]) },
   fallback => 1,
);

__PACKAGE__->default_auto_method_types(qw(get_set_on_save delete_on_save));

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(hash_key share_db class key_columns foreign_key referential_integrity)
);

use Rose::Object::MakeMethods::Generic
(
  boolean =>
  [
    'share_db' => { default => 1 },
    'referential_integrity' => { default => 1 },
    'with_column_triggers' => { default => 0 },
    'disable_column_triggers',
  ],

  scalar => 'deferred_make_method_args',

  hash =>
  [
    _key_column  => { hash_key  => '_key_columns' },
    _key_columns => { interface => 'get_set_all' },
  ],
);

sub is_singular { 1 }

sub foreign_class { shift->class(@_) }

sub key_column
{
  my($self) = shift;

  if(@_ > 1)
  {
    $self->{'is_required'} = undef;
  }

  return $self->_key_column(@_);
}

sub key_columns
{
  my($self) = shift;

  if(@_)
  {
    $self->{'is_required'} = undef;
  }

  return $self->_key_columns(@_);
}

*column_map = \&key_columns;

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => 
  [
    __PACKAGE__->common_method_maker_argument_names,
    relationship_type => { interface => 'get_set_init' },
  ],
);

*rel_type = \&relationship_type;

__PACKAGE__->method_maker_info
(
  get_set =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'object_by_key',
    interface => 'get_set',
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

sub init_relationship_type { 'many to one' }

sub foreign_key { $_[0] }

sub type { 'foreign key' }

sub soft 
{
  my($self) = shift;

  if(@_)
  {
    $self->referential_integrity(!$_[0]);
  }

  return ! $self->referential_integrity;
}

sub is_required
{
  my($self) = shift;

  return $self->{'required'}     if(defined $self->{'required'});
  return $self->{'is_required'}  if(defined $self->{'is_required'});

  my $meta = $self->parent or 
    Carp::croak "Missing parent for foreign key '", $self->name, "'";

  my $key_columns = $self->key_columns;

  # If any local key column allows null values, then 
  # the foreign object is not required.
  foreach my $column_name (keys %$key_columns)
  {
    my $column = $meta->column($column_name) 
      or Carp::confess "No such column '$column_name' in table '",
           $self->parent->table, "' referenced from foreign key '",
           $self->name, "'";

    unless($column->not_null)
    {
      return $self->{'is_required'} = 0;
    }
  }

  return $self->{'is_required'} = 1;
}

sub make_methods
{
  my($self) = shift;
  $self->is_required; # initialize
  $self->SUPER::make_methods(@_);

  if($self->with_column_triggers)
  {
    my $method = $self->method_name('get_set_on_save') ||
                 $self->method_name('get_set');

    if($method)
    {
      my $meta = $self->parent or 
        Carp::croak "Missing parent for foreign key '", $self->name, "'";

      my $key_columns = $self->key_columns;

      foreach my $column_name (keys %$key_columns)
      {
        my $column       = $meta->column($column_name);
        my $accessor     = $column->accessor_method_name;
        my $trigger_name = 'clear_fk' . $self->name;

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

sub id
{
  my($self) = shift;

  my $key_columns = $self->key_columns;

  return $self->parent->class . ' ' . $self->class . ' ' . 
    join("\0", map { join("\1", lc $_, lc $key_columns->{$_}) } sort keys %$key_columns) . 
    #join("\0", map { $_ . '=' . ($self->$_() || 0) } qw(...));
    'required=' . $self->referential_integrity;
}

sub sanity_check
{
  my($self) = shift;

  my $key_columns = $self->key_columns;

  no warnings;
  unless(ref $key_columns eq 'HASH' && keys %$key_columns)
  {
    #Carp::croak "Foreign key '", $self->name, "' is missing a key_columns";
    return;
  }

  return 1;
}

sub is_ready_to_make_methods
{
  my($self) = shift;

  return 0  unless($self->sanity_check);

  my $error;

  TRY:
  {
    local $@;

    eval
    {
      # Workaround for http://rt.perl.org/rt3/Ticket/Display.html?id=60890
      local $SIG{'__DIE__'};

      $self->class->isa('Rose::DB::Object') or die
        Rose::DB::Object::Exception::ClassNotReady->new(
          "Missing or invalid foreign class");

      my $fk_meta = $self->class->meta or die
        Rose::DB::Object::Exception::ClassNotReady->new(
          "Missing meta object for " . $self->class);

      my $key_columns = $self->key_columns || {};

      foreach my $column_name (values %$key_columns)
      {
        unless($fk_meta->column($column_name))
        {
          die Rose::DB::Object::Exception::ClassNotReady->new(
                "No column '$column_name' in class " . $fk_meta->class);
        }

        unless($fk_meta->column_accessor_method_name($column_name) && 
               $fk_meta->column_mutator_method_name($column_name))
        {
          die Rose::DB::Object::Exception::ClassNotReady->new(
                "Foreign class not initialized");
        }
      }
    };

    $error = $@;
  }

  if($error)
  {
    if($Debug || $Rose::DB::Object::Metadata::Debug)
    {
      my $err = $error;
      $err =~ s/ at .*//;
      warn $self->parent->class, ': Foreign key ', $self->name, " NOT READY - $err";
    }

    die $error  unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception::ClassNotReady'));
  }

  return $error ? 0 : 1;
}

our $DEFAULT_INLINE_LIMIT = 80;

sub perl_hash_definition
{
  my($self, %args) = @_;

  my $meta = $self->parent;

  my $indent = defined $args{'indent'} ? $args{'indent'} : 
                 ($meta ? $meta->default_perl_indent : undef);

  my $braces = defined $args{'braces'} ? $args{'braces'} : 
                 ($meta ? $meta->default_perl_braces : undef);

  my $inline = defined $args{'inline'} ? $args{'inline'} : 0;
  my $inline_limit = defined $args{'inline'} ? $args{'inline_limit'} : $DEFAULT_INLINE_LIMIT;

  my $name_padding = $args{'name_padding'};

  my %attrs = map { $_ => 1 } $self->perl_foreign_key_definition_attributes;
  my %hash = $self->spec_hash;

  my @delete_keys = grep { !$attrs{$_} } keys %hash;
  delete @hash{@delete_keys};

  my $key_columns = $self->key_columns;

  # Only inline single-pair key column mappings
  if(keys %$key_columns > 1)
  {
    $inline_limit = 1;
    $inline = 0;
  }

  my $max_len = 0;
  my $min_len = -1;

  foreach my $name (keys %hash)
  {
    $max_len = length($name)  if(length $name > $max_len);
    $min_len = length($name)  if(length $name < $min_len || $min_len < 0);
  }

  if(defined $name_padding && $name_padding > 0)
  {
    return sprintf('%-*s => ', $name_padding, perl_quote_key($self->name)) .
           perl_hashref(hash         => \%hash, 
                        braces       => $braces,
                        inline       => $inline, 
                        inline_limit => $inline_limit,
                        indent       => $indent,
                        key_padding  => hash_key_padding(\%hash));
  }
  else
  {
    return perl_quote_key($self->name) . ' => ' .
           perl_hashref(hash         => \%hash, 
                        braces       => $braces,
                        inline       => $inline,
                        inline_limit => $inline_limit,
                        indent       => $indent,
                        key_padding  => hash_key_padding(\%hash));
  }
}

sub perl_foreign_key_definition_attributes { qw(class key_columns soft rel_type) }

# Some object keys have different names when they appear
# in hashref-style foreign key specs.  This hash maps
# between the two in the case where they differ.
sub spec_hash_map 
{
  {
    # object key    spec key
    method_name  => 'methods',
    _key_columns => 'key_columns',
    relationship_type => 'rel_type',
  }
}

# Return a hashref-style foreign key spec
sub spec_hash
{
  my($self) = shift;

  my $map = $self->spec_hash_map || {};

  my %spec;

  foreach my $key (keys(%$self))
  {
    if(exists $map->{$key})
    {
      my $spec_key = $map->{$key} or next;
      $spec{$spec_key} = $self->{$key};
    }
    else
    {
      $spec{$key} = $self->{$key};
    }
  }

  # Don't include this key if it has the default value.  Anal, I know...
  delete $spec{'rel_type'}  if($spec{'rel_type'} eq $self->init_relationship_type);

  return wantarray ? %spec : \%spec;
}

sub object_has_foreign_object
{
  my($self, $object) = @_;

  unless($object->isa($self->parent->class))
  {
    my $class = $self->parent->class;
    Carp::croak "Cannot check for foreign object related through the ", $self->name,
                " foreign key.  Object does not inherit from $class: $object";
  }

  return $object->{$self->hash_key} || 0;
}

sub hash_keys_used { shift->hash_key }

sub forget_foreign_object
{
  my($self, $object) = @_;

  foreach my $key ($self->hash_keys_used)
  {
    $object->{$key} = undef;
  }
}

sub requires_preexisting_parent_object { 0 }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::ForeignKey - Foreign key metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::ForeignKey;

  $fk = Rose::DB::Object::Metadata::ForeignKey->new(...);
  $fk->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for foreign keys in a database table.  It stores information about which columns in the local table map to which columns in the foreign table.

This class will create methods for C<the thing referenced by> the foreign key column(s).  You'll still need accessor method(s) for the foreign key column(s) themselves.

Both the local table and the foreign table must have L<Rose::DB::Object>-derived classes fronting them.

Foreign keys can represent both "L<one to one|Rose::DB::Object::Metadata::Relationship::OneToOne>" and "L<many to one|Rose::DB::Object::Metadata::Relationship::ManyToOne>" relationships.  To choose, set the L<relationship_type|/relationship_type> attribute to either "one to one" or "many to one".  The default is "many to one".

=head2 MAKING METHODS

A L<Rose::DB::Object::Metadata::ForeignKey>-derived object is responsible for creating object methods that manipulate objects referenced by a foreign key.  Each foreign key object can make zero or more methods for each available foreign key method type.  A foreign key method type describes the purpose of a method.  The default list of foreign key method types contains only one type:

=over 4

=item C<get_set>

A method that returns the object referenced by the foreign key.

=back

Methods are created by calling L<make_methods|/make_methods>.  A list of method types can be passed to the call to L<make_methods|/make_methods>.  If absent, the list of method types is determined by the L<auto_method_types|/auto_method_types> method.  A list of all possible method types is available through the L<available_method_types|/available_method_types> method.

These methods make up the "public" interface to foreign key method creation.  There are, however, several "protected" methods which are used internally to implement the methods described above.  (The word "protected" is used here in a vaguely C++ sense, meaning "accessible to subclasses, but not to the public.")  Subclasses will probably find it easier to override and/or call these protected methods in order to influence the behavior of the "public" method maker methods.

A L<Rose::DB::Object::Metadata::ForeignKey> object delegates method creation to a  L<Rose::Object::MakeMethods>-derived class.  Each L<Rose::Object::MakeMethods>-derived class has its own set of method types, each of which takes it own set of arguments.

Using this system, four pieces of information are needed to create a method on behalf of a L<Rose::DB::Object::Metadata::ForeignKey>-derived object:

=over 4

=item * The B<foreign key method type> (e.g., C<get_set>)

=item * The B<method maker class> (e.g., L<Rose::DB::Object::MakeMethods::Generic>)

=item * The B<method maker method type> (e.g., L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>)

=item * The B<method maker arguments> (e.g., C<interface =E<gt> 'get_set'>)

=back

This information can be organized conceptually into a "method map" that connects a foreign key method type to a method maker class and, finally, to one particular method type within that class, and its arguments.

The default method map for L<Rose::DB::Object::Metadata::ForeignKey> is:

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, 
C<interface =E<gt> 'get_set'> ...

=item C<get_set_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'get_set_now'> ...

=item C<get_set_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'get_set_on_save'> ...

=item C<delete_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'delete_now'> ...

=item C<delete_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'delete_on_save'> ...

=back

Each item in the map is a foreign key method type.  For each foreign key method type, the method maker class, the method maker method type, and the "interesting" method maker arguments are listed, in that order.

The "..." in the method maker arguments is meant to indicate that arguments have been omitted.  Arguments that are common to all foreign key method types are routinely omitted from the method map for the sake of brevity.

The purpose of documenting the method map is to answer the question, "What kind of method(s) will be created by this foreign key object for a given method type?"  Given the method map, it's possible to read the documentation for each method maker class to determine how methods of the specified type behave when passed the listed arguments.

Remember, the existence and behavior of the method map is really implementation detail.  A foreign key object is free to implement the public method-making interface however it wants, without regard to any conceptual or actual method map.

=head1 CLASS METHODS

=over 4

=item B<default_auto_method_types [TYPES]>

Get or set the default list of L<auto_method_types|/auto_method_types>.  TYPES should be a list of foreign key method types.  Returns the list of default foreign key method types (in list context) or a reference to an array of the default foreign key method types (in scalar context).  The default list contains the "get_set_on_save" and "delete_on_save" foreign key method types.

=back

=head1 OBJECT METHODS

=over 4

=item B<available_method_types>

Returns the full list of foreign key method types supported by this class.

=item B<auto_method_types [TYPES]>

Get or set the list of foreign key method types that are automatically created when L<make_methods|/make_methods> is called without an explicit list of foreign key method types.  The default list is determined by the L<default_auto_method_types|/default_auto_method_types> class method.

=item B<build_method_name_for_type TYPE>

Return a method name for the foreign key method type TYPE.  The default implementation returns the following.

For the method types "get_set", "get_set_now", and "get_set_on_save", the foreign key's L<name|/name> is returned.

For the method types "delete_now" and "delete_on_save", the foreign key's L<name|/name> prefixed with "delete_" is returned.

Otherwise, undef is returned.

=item B<class [CLASS]>

Get or set the class name of the L<Rose::DB::Object>-derived object that encapsulates rows from the table referenced by the foreign key column(s).

=item B<column_map [HASH | HASHREF]>

This is an alias for the L<key_columns|/key_columns> method.

=item B<key_column LOCAL [, FOREIGN]>

If passed a local column name LOCAL, return the corresponding column name in the foreign table.  If passed both a local column name LOCAL and a foreign column name FOREIGN, set the local/foreign mapping and return the foreign column name.

=item B<key_columns [ HASH | HASHREF ]>

Get or set a hash that maps local column names to foreign column names in the table referenced by the foreign key.  Returns a reference to a hash in scalar context, or a list of key/value pairs in list context.

=item B<make_methods PARAMS>

Create object method used to manipulate object referenced by the foreign key.  Any applicable L<column triggers|/with_column_triggers> are also added.  PARAMS are name/value pairs.  Valid PARAMS are:

=over 4

=item C<preserve_existing BOOL>

Boolean flag that indicates whether or not to preserve existing methods in the case of a name conflict.

=item C<replace_existing BOOL>

Boolean flag that indicates whether or not to replace existing methods in the case of a name conflict.

=item C<target_class CLASS>

The class in which to make the method(s).  If omitted, it defaults to the calling class.

=item C<types ARRAYREF>

A reference to an array of foreign key method types to be created.  If omitted, it defaults to the list of foreign key method types returned by L<auto_method_types|/auto_method_types>.

=back

If any of the methods could not be created for any reason, a fatal error will occur.

=item B<methods MAP>

Set the list of L<auto_method_types|/auto_method_types> and method names all at once.  MAP should be a reference to a hash whose keys are method types and whose values are either undef or method names.  If a value is undef, then the method name for that method type will be generated by calling B<build_method_name_for_type|/build_method_name_for_type>, as usual.  Otherwise, the specified method name will be used.

=item B<method_name TYPE [, NAME]>

Get or set the name of the relationship method of type TYPE.

=item B<method_types [TYPES]>

This method is an alias for the L<auto_method_types|/auto_method_types> method.

=item B<name [NAME]>

Get or set the name of the foreign key.  This name must be unique among all other foreign keys for a given L<Rose::DB::Object>-derived class.

=item B<referential_integrity [BOOL]>

Get or set the boolean value that determines what happens when the local L<key columns|/key_columns> have L<defined|perlfunc/defined> values, but the object they point to is not found.  If true, a fatal error will occur when the methods that fetch objects through this foreign key are called.  If false, then the methods will simply return undef.  The default is true.

=item B<rel_type [TYPE]>

This method is an alias for the L<relationship_type|/relationship_type> method described below.

=item B<relationship_type [TYPE]>

Get or set the relationship type represented by this foreign key.  Valid values for TYPE are "L<one to one|Rose::DB::Object::Metadata::Relationship::OneToOne>" and "L<many to one|Rose::DB::Object::Metadata::Relationship::ManyToOne>".

=item B<share_db [BOOL]>

Get or set the boolean flag that determines whether the L<db|Rose::DB::Object/db> attribute of the current object is shared with the foreign object to be fetched.  The default value is true.

=item B<soft [BOOL]>

This method is the mirror image of the L<referential_integrity|/referential_integrity> method.   Passing a true is the same thing as setting L<referential_integrity|/referential_integrity> to false, and vice versa.  Similarly, the return value is the logical negation of L<referential_integrity|/referential_integrity>.

=item B<type>

Returns "foreign key".

=item B<with_column_triggers [BOOL]>

Get or set a boolean value that indicates whether or not L<triggers|Rose::DB::Object::Metadata::Column/TRIGGERS> should be added to the L<key columns|/key_columns> in an attempt to keep foreign objects and foreign key columns in sync.  Defaults to false.

=back

=head1 PROTECTED API

These methods are not part of the public interface, but are supported for use by subclasses.  Put another way, given an unknown object that "isa" L<Rose::DB::Object::Metadata::ForeignKey>, there should be no expectation that the following methods exist.  But subclasses, which know the exact class from which they inherit, are free to use these methods in order to implement the public API described above.

=over 4 

=item B<method_maker_arguments TYPE>

Returns a hash (in list context) or reference to a hash (in scalar context) of name/value arguments that will be passed to the L<method_maker_class|/method_maker_class> when making the foreign key method type TYPE.

=item B<method_maker_class TYPE [, CLASS]>

If CLASS is passed, the name of the L<Rose::Object::MakeMethods>-derived class used to create the object method of type TYPE is set to CLASS.

Returns the name of the L<Rose::Object::MakeMethods>-derived class used to create the object method of type TYPE.

=item B<method_maker_type TYPE [, NAME]>

If NAME is passed, the name of the method maker method type for the foreign key method type TYPE is set to NAME.

Returns the method maker method type for the foreign key method type TYPE.  

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
