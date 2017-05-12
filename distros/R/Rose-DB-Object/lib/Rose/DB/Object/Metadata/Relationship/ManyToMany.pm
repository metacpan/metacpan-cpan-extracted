package Rose::DB::Object::Metadata::Relationship::ManyToMany;

use strict;

use Carp();
use Scalar::Util qw(weaken);

use Rose::DB::Object::Metadata::Relationship;
our @ISA = qw(Rose::DB::Object::Metadata::Relationship);

use Rose::DB::Object::Exception;
use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Generic;

use Rose::DB::Object::Constants qw(PRIVATE_PREFIX);

our $VERSION = '0.784';

our $Debug = 0;

__PACKAGE__->default_auto_method_types(qw(find get_set_on_save add_on_save));

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(share_db map_class map_from map_to manager_class manager_method
     manager_count_method manager_iterator_method manager_find_method
     manager_args query_args map_record_method)
);

use Rose::Object::MakeMethods::Generic
(
  boolean =>
  [
    'share_db' => { default => 1 },
  ],
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => 
  [
    __PACKAGE__->common_method_maker_argument_names,
  ],

  # These are set by the method maker when make_methods() is called

  scalar => 
  [
    'foreign_class', # class to be fetched
  ],

  hash =>
  [
    # Map from map-table columns to self-table columns
    'column_map',
  ]
);

__PACKAGE__->method_maker_info
(
  count =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_map',
    interface => 'count',
  },

  find =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_map',
    interface => 'find',
  },

  iterator =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_map',
    interface => 'iterator',
  },

  get_set =>
  {
    class => 'Rose::DB::Object::MakeMethods::Generic',
    type  => 'objects_by_map',
    interface => 'get_set',
  },

  get_set_now =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_map',
    interface => 'get_set_now',
  },

  get_set_on_save =>
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_map',
    interface => 'get_set_on_save',
  },

  add_now => 
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_map',
    interface => 'add_now',
  },

  add_on_save => 
  {
    class     => 'Rose::DB::Object::MakeMethods::Generic',
    type      => 'objects_by_map',
    interface => 'add_on_save',
  },
);

sub type { 'many to many' }

sub is_singular { 0 }

use constant MAP_RECORD_ATTR   => PRIVATE_PREFIX . '_map_record';
use constant MAP_RECORD_METHOD => 'map_record';

MAKE_MAP_RECORD_METHOD:
{
  my $counter = 1;

  sub make_map_record_method
  {
    my($map_to_class, $map_record_method, $map_class) = @_;

    my $key = MAP_RECORD_ATTR . '_' . $counter++;

    no strict 'refs';
    *{"${map_to_class}::$map_record_method"} = sub 
    {
      my($self) = shift;

      if(@_)
      {
        my $arg    = shift;
        my $weaken = shift;

        if(ref $arg eq 'HASH')
        {
          return $self->{$key} = $map_class->new(%$arg);
        }
        elsif(!ref $arg || !UNIVERSAL::isa($arg, $map_class))
        {
          Carp::croak "Illegal map record argument: $arg";
        }

        return $weaken ? (weaken($self->{$key} = $arg)) : ($self->{$key} = $arg);
      }

      return $self->{$key}; # ||= $map_class->new;
    };

    $map_to_class->meta->map_record_method_key($map_record_method => $key);

    return $key;
  }
}

sub manager_args
{
  my($self) = shift;

  return $self->{'manager_args'}  unless(@_);

  my $args = $self->{'manager_args'} = shift;

  if(my $method = $args->{'with_map_records'})
  {
    $method = MAP_RECORD_METHOD  unless($method =~ /^[A-Za-z_]\w*$/);

    $self->map_record_method($method);
  }

  return $args;
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

sub sanity_check
{
  my($self) = shift;

  defined $self->map_class or 
    Carp::croak $self->type, " relationship '", $self->name,
                "' is missing a map_class";

  return 1;
}
my $i;
my %C;

sub is_ready_to_make_methods
{
  my($self) = shift;

  my $error;

  TRY:
  {
    local $@;

    # This code is (ug) duplicated from the method-maker itself, and
    # slightly modified to run here.  If the method-maker can't get all
    # the info it needs, then we're not yet ready to make these methods.
    eval
    {
      # Workaround for http://rt.perl.org/rt3/Ticket/Display.html?id=60890
      local $SIG{'__DIE__'};

      my $map_class = $self->map_class or die "Missing map class";

      unless(UNIVERSAL::isa($map_class, 'Rose::DB::Object'))
      {
        die Rose::DB::Object::Exception::ClassNotReady->new(
          "Map class $map_class not yet ready");
      }

      my $map_meta  = $map_class->meta or die
        Rose::DB::Object::Exception::ClassNotReady->new(
          "Missing meta object for $map_class");

      my $map_from  = $self->map_from;
      my $map_to    = $self->map_to;
      my $relationship = $self;

      my $target_class = $self->parent->class;
      my $meta         = $target_class->meta or die
        Rose::DB::Object::Exception::ClassNotReady->new(
          "Missing meta object for $target_class");

      my($map_to_class, $map_to_meta, $map_to_method);

      # "map" is the map table, "self" is the $target_class, and "remote"
      # is the foreign object class
      my(%map_column_to_self_method,
         %map_column_to_self_column,
         %map_method_to_remote_method);

      # Also grab the foreign object class that the mapper points to,
      # the relationship name that points back to us, and the class 
      # name of the objects we really want to fetch.
      my($require_objects, $local_rel, $foreign_class, %seen_fk);

      foreach my $item ($map_meta->foreign_keys, $map_meta->relationships)
      {
        # Track which foreign keys we've seen
        if($item->isa('Rose::DB::Object::Metadata::ForeignKey'))
        {
          $seen_fk{$item->id}++;
        }
        elsif($item->isa('Rose::DB::Object::Metadata::Relationship'))
        {
          # Skip a relationship if we've already seen the equivalent foreign key
          next  if($seen_fk{$item->id});
        }

        if($item->can('class') && $item->class eq $target_class)
        {
          # Skip if there was an explicit local relationship name and
          # this is not that name.
          unless($map_from && $item->name ne $map_from)
          {
            if(%map_column_to_self_method)
            {
              die Rose::DB::Object::Exception::ClassNotReady->new(
                "Map class $map_class has more than one foreign key " .
                "and/or 'many to one' relationship that points to the " .
                "class $target_class.  Please specify one by name " .
                "with a 'local' parameter in the 'map' hash");
            }

            $map_from = $local_rel = $item->name;

            my $map_columns = 
              $item->can('column_map') ? $item->column_map : $item->key_columns;

            # "local" and "foreign" here are relative to the *mapper* class
            while(my($local_column, $foreign_column) = each(%$map_columns))
            {
              my $foreign_method = $meta->column_accessor_method_name($foreign_column)
                or die Rose::DB::Object::Exception::ClassNotReady->new(
                     "Missing accessor method for column '$foreign_column'" .
                     " in class " . $meta->class);
              $map_column_to_self_method{$local_column} = $foreign_method;
              $map_column_to_self_column{$local_column} = $foreign_column;
            }

            next;
          }
        }

        if($item->isa('Rose::DB::Object::Metadata::ForeignKey') ||
              $item->type eq 'many to one')
        {
          # Skip if there was an explicit foreign relationship name and
          # this is not that name.
          next  if($map_to && $item->name ne $map_to);

          $map_to = $item->name;

          if($require_objects)
          {
            die Rose::DB::Object::Exception::ClassNotReady->new(
              "Map class $map_class has more than one foreign key " .
              "and/or 'many to one' relationship that points to a " .
              "class other than $target_class.  Please specify one " .
              "by name with a 'foreign' parameter in the 'map' hash");
          }

          $map_to_class = $item->class;

          unless(UNIVERSAL::isa($map_to_class, 'Rose::DB::Object'))
          {
            die Rose::DB::Object::Exception::ClassNotReady->new(
              "Map-to-class $map_to_class not yet ready");
          }

          $map_to_meta  = $map_to_class->meta or die
            Rose::DB::Object::Exception::ClassNotReady->new(
              "Missing meta object for $map_to_class");

          my $map_columns = 
            $item->can('column_map') ? $item->column_map : $item->key_columns;

          # "local" and "foreign" here are relative to the *mapper* class
          while(my($local_column, $foreign_column) = each(%$map_columns))
          {
            my $local_method = $map_meta->column_accessor_method_name($local_column)
              or die Rose::DB::Object::Exception::ClassNotReady->new(
                "Missing accessor method for column '$local_column'" .
                " in class " . $map_meta->class);

            my $foreign_method = $map_to_meta->column_accessor_method_name($foreign_column)
              or die Rose::DB::Object::Exception::ClassNotReady->new(
                "Missing accessor method for column '$foreign_column'" .
                " in class " . $map_to_meta->class);

            # local           foreign
            # Map:color_id => Color:id
            $map_method_to_remote_method{$local_method} = $foreign_method;
          }

          $require_objects = [ $item->name ];
          $foreign_class = $item->class;

          $map_to_method = $item->method_name('get_set') || 
                           $item->method_name('get_set_now') ||
                           $item->method_name('get_set_on_save') ||
                           die Rose::DB::Object::Exception::ClassNotReady->new(
                             "No 'get_*' method found for " . $item->name);
        }
      }

      unless(%map_column_to_self_method)
      {
        die Rose::DB::Object::Exception::ClassNotReady->new(
          "Could not find a foreign key or 'many to one' relationship "  .
          "in $map_class that points to $target_class");
      }

      unless(%map_column_to_self_column)
      {
        die Rose::DB::Object::Exception::ClassNotReady->new(
          "Could not find a foreign key or 'many to one' relationship " .
          "in $map_class that points to " . ($map_to_class || $map_to));
      }

      unless($require_objects)
      {
        # Make a second attempt to find a suitable foreign relationship in the
        # map class, this time looking for links back to $target_class so long as
        # it's a different relationship than the one used in the local link.
        foreach my $item ($map_meta->foreign_keys, $map_meta->relationships)
        {
          # Skip a relationship if we've already seen the equivalent foreign key
          if($item->isa('Rose::DB::Object::Metadata::Relationship'))
          {
            next  if($seen_fk{$item->id});
          }

          if(($item->isa('Rose::DB::Object::Metadata::ForeignKey') ||
             $item->type eq 'many to one') &&
             $item->class eq $target_class && $item->name ne $local_rel)
          {  
            if($require_objects)
            {
              die Rose::DB::Object::Exception::ClassNotReady->new(
                "Map class $map_class has more than two foreign keys " .
                "and/or 'many to one' relationships that points to a " .
                "$target_class.  Please specify which ones to use " .
                "by including 'local' and 'foreign' parameters in the " .
                "'map' hash");
            }

            $require_objects = [ $item->name ];
            $foreign_class = $item->class;
            $map_to_method = $item->method_name('get_set') ||
                             $item->method_name('get_set_now') ||
                             $item->method_name('get_set_on_save') ||
                             die Rose::DB::Object::Exception::ClassNotReady->new(
                               "No 'get_*' method found for " . $item->name);
          }
        }
      }

      unless($require_objects)
      {
        die Rose::DB::Object::Exception::ClassNotReady->new(
          "Could not find a foreign key or 'many to one' relationship " .
          "in $map_class that points to a class other than $target_class");
      }

      unless($foreign_class)
      {
        die Rose::DB::Object::Exception::ClassNotReady->new("Missing foreign class");
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
      warn $self->parent->class, ': many-to-many relationship ', $self->name, " NOT READY - $err";
    }

    die $error  unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception::ClassNotReady'));
  }

  return $error ? 0 : 1;
}

sub perl_relationship_definition_attributes
{
  grep { $_ !~ /^(?:column_map|foreign_class)$/ }
    shift->SUPER::perl_relationship_definition_attributes(@_);
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Relationship::ManyToMany - Many to many table relationship metadata object.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Relationship::ManyToMany;

  $rel = Rose::DB::Object::Metadata::Relationship::ManyToMany->new(...);
  $rel->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for relationships in which rows from one table are connected to rows in another table through an intermediate table that maps between them. 

This class inherits from L<Rose::DB::Object::Metadata::Relationship>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Relationship> documentation for more information.

=head1 EXAMPLE

Consider the following tables.

    CREATE TABLE widgets
    (
      id    SERIAL PRIMARY KEY,
      name  VARCHAR(255)
    );

    CREATE TABLE colors
    (
      id    SERIAL PRIMARY KEY,
      name  VARCHAR(255)
    );

    CREATE TABLE widget_color_map
    (
      id         SERIAL PRIMARY KEY,
      widget_id  INT NOT NULL REFERENCES widgets (id),
      color_id   INT NOT NULL REFERENCES colors (id),
      UNIQUE(widget_id, color_id)
    );

Given these tables, each widget can have zero or more colors, and each color can be applied to zero or more widgets.  This is the type of "many to many" relationship that this class is designed to handle.

In order to do so, each of the three of the tables that participate in the relationship must be fronted by its own L<Rose::DB::Object>-derived class.  Let's call those classes C<Widget>, C<Color>, and C<WidgetColorMap>.

The class that maps between the other two classes is called the "L<map class|/map_class>."  In this example, it's C<WidgetColorMap>.  The map class B<must> have a foreign key and/or "many to one" relationship pointing to each of the two classes that it maps between.

When it comes to actually creating the three classes that participate in a "many to many" relationship, there's a bit of a "chicken and egg" problem.  All these classes need to know about each other more or less "simultaneously," but they must be defined in a serial fashion, and may be loaded in any order by the user.

In order to account for this, method creation may be deferred for any foreign key or relationship that does not yet have all the information it requires to do its job.  This should be transparent to the developer.

Here's a complete example using the C<Widget>, C<Color>, and C<WidgetColorMap> classes.  First, the C<Widget> class which has a "many to many" relationship through which it can retrieve its colors.

  package Widget;

  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup
  (
    table => 'widgets',

    columns =>
    [
      id   => { type => 'int', primary_key => 1 },
      name => { type => 'varchar', length => 255 },
    ],

    relationships =>
    [
      # Define "many to many" relationship to get colors
      colors =>
      {
        type      => 'many to many',
        map_class => 'WidgetColorMap',

        # These are only necessary if the relationship is ambiguous
        #map_from  => 'widget',
        #map_to    => 'color',
      },
    ],
  );

  1;

Next, the C<Color> class which has a "many to many" relationship through which it can retrieve all the widgets that have this color.

  package Color;

  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup
  (
    table => 'colors',

    columns =>
    [
      id   => { type => 'int', primary_key => 1 },
      name => { type => 'varchar', length => 255 },
    ],

    relationships =>
    [
      # Define "many to many" relationship to get widgets
      widgets =>
      {
        type      => 'many to many',
        map_class => 'WidgetColorMap',

        # These are only necessary if the relationship is ambiguous
        #map_from  => 'color',
        #map_to    => 'widget',
      },
    ],
  );

  1;

Finally, the C<WidgetColorMap> class must have a foreign key or "many to one" relationship for each of the two classes that it maps between (C<Widget> and C<Color>).

  package WidgetColorMap;

  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup
  (
    table => 'widget_color_map',

    columns =>
    [
      id        => { type => 'int', primary_key => 1 },
      widget_id => { type => 'int' },
      color_id  => { type => 'int' },
    ],

    foreign_keys =>
    [
      # Define foreign keys that point to each of the two classes 
      # that this class maps between.
      color => 
      {
        class => 'Color',
        key_columns => { color_id => 'id' },
      },

      widget => 
      {
        class => 'Widget',
        key_columns => { widget_id => 'id' },
      },
    ],
  );

  1;

Here's an initial set of data and some examples of the above classes in action.  First, the data:

  INSERT INTO widgets (id, name) VALUES (1, 'Sprocket');
  INSERT INTO widgets (id, name) VALUES (2, 'Flange');

  INSERT INTO colors (id, name) VALUES (1, 'Red');
  INSERT INTO colors (id, name) VALUES (2, 'Green');
  INSERT INTO colors (id, name) VALUES (3, 'Blue');

  INSERT INTO widget_color_map (widget_id, color_id) VALUES (1, 1);
  INSERT INTO widget_color_map (widget_id, color_id) VALUES (1, 2);
  INSERT INTO widget_color_map (widget_id, color_id) VALUES (2, 3);

Now the code:

  use Widget;
  use Color;

  $widget = Widget->new(id => 1);
  $widget->load;

  @colors = map { $_->name } $widget->colors; # ('Red', 'Green')

  $color = Color->new(id => 1);
  $color->load;

  @widgets = map { $_->name } $color->widgets; # ('Sprocket')

=head1 METHOD MAP

=over 4

=item C<count>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, C<interface =E<gt> 'count'> ...

=item C<find>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, C<interface =E<gt> 'find'> ...

=item C<iterator>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, C<interface =E<gt> 'iterator'> ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, 
C<interface =E<gt> 'get_set'> ...

=item C<get_set_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, C<interface =E<gt> 'get_set_now'> ...

=item C<get_set_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, C<interface =E<gt> 'get_set_on_save'> ...

=item C<add_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, C<interface =E<gt> 'add_now'> ...

=item C<add_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<objects_by_map|Rose::DB::Object::MakeMethods::Generic/objects_by_map>, C<interface =E<gt> 'add_on_save'> ...

=back

See the L<Rose::DB::Object::Metadata::Relationship|Rose::DB::Object::Metadata::Relationship/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 CLASS METHODS

=over 4

=item B<default_auto_method_types [TYPES]>

Get or set the default list of L<auto_method_types|Rose::DB::Object::Metadata::Relationship/auto_method_types>.   TYPES should be a list of relationship method types.  Returns the list of default relationship method types (in list context) or a reference to an array of the default relationship method types (in scalar context).  The default list contains  "get_set_on_save" and "add_on_save".

=back

=head1 OBJECT METHODS

=over 4

=item B<build_method_name_for_type TYPE>

Return a method name for the relationship method type TYPE.  

For the method types "get_set", "get_set_now", and "get_set_on_save", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> is returned.

For the method types "add_now" and "add_on_save", the relationship's  L<name|Rose::DB::Object::Metadata::Relationship/name> prefixed with "add_" is returned.

For the method type "find", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> prefixed with "find_" is returned.

For the method type "count", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> suffixed with "_count" is returned.

For the method type "iterator", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> suffixed with "_iterator" is returned.

Otherwise, undef is returned.

=item B<is_singular>

Returns false.

=item B<manager_class [CLASS]>

Get or set the name of the L<Rose::DB::Object::Manager>-derived class that the L<map_class|/map_class> will use to fetch records.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<Rose::DB::Object::Manager> if this value is left undefined.

=item B<manager_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when fetching records.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects|Rose::DB::Object::Manager/get_objects> if this value is left undefined.

=item B<manager_count_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when counting objects.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects_count|Rose::DB::Object::Manager/get_objects_count> if this value is left undefined.

=item B<manager_iterator_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when creating an iterator.  The L<make_methods|Rose::DB::Object::Metadata::Relationship/make_methods> method will use L<get_objects_iterator|Rose::DB::Object::Manager/get_objects_iterator> if this value is left undefined.

=item B<manager_args [HASHREF]>

Get or set a reference to a hash of name/value arguments to pass to the L<manager_method|/manager_method> when fetching objects.  For example, this can be used to enforce a particular sort order for objects fetched via this relationship.  Modifying the L<example|/EXAMPLE> above:

  Widget->meta->add_relationship
  (
    colors =>
    {
      type         => 'many to many',
      map_class    => 'WidgetColorMap',
      manager_args => { sort_by => Color->meta->table . '.name' },
    },
  );

This would ensure that a C<Widget>'s C<colors()> are listed in alphabetical order.  Note that the "name" column is prefixed by the name of the table fronted by the C<Color> class.  This is important because several tables may have a column named "name."  If this relationship is used to form a JOIN in a query along with one of those tables, then the "name" column will be ambiguous.  Adding a table name prefix disambiguates the column name.

Also note that the table name is not hard-coded.  Instead, it is fetched from the L<Rose::DB::Object>-derived class that fronts the table.  This is more verbose, but is a much better choice than including the literal table name when it comes to long-term maintenance of the code.

See the documentation for L<Rose::DB::Object::Manager>'s L<get_objects|Rose::DB::Object::Manager/get_objects> method for a full list of valid arguments for use with the C<manager_args> parameter, but remember that you can define your own custom L<manager_class> and thus can also define what kinds of arguments C<manager_args> will accept.

B<Note:> when the name of a relationship that has C<manager_args> is used in a L<Rose::DB::Object::Manager> L<with_objects|Rose::DB::Object::Manager/with_objects> or L<require_objects|Rose::DB::Object::Manager/require_objects> parameter value, I<only> the L<sort_by|Rose::DB::Object::Manager/sort_by> argument will be copied from C<manager_args> and incorporated into the query.

=item B<map_class [CLASS]>

Get or set the name of the L<Rose::DB::Object>-derived class that fronts the table that maps between the other two tables.  This class must have a foreign key and/or "many to one" relationship for each of the two tables that it maps between.

In the L<example|EXAMPLE> above, the map class is C<WidgetColorMap>.

=item B<map_from [NAME]>

Get or set the name of the "many to one" relationship or foreign key in L<map_class|/map_class> that points to the object of the current class.  Setting this value is only necessary if the L<map class|/map_class> has more than one foreign key or "many to one" relationship that points to one of the classes that it maps between.

In the L<example|EXAMPLE> above, the value of L<map_from|/map_from> would be "widget" when defining the "many to many" relationship in the C<Widget> class, or "color" when defining the "many to many" relationship in the C<Color> class.  Neither of these settings is necessary in the example because the C<WidgetColorMap> class has one foreign key that points to each class, so there is no ambiguity.

=item B<map_to [NAME]>

Get or set the name of the "many to one" relationship or foreign key in L<map_class|/map_class> that points to the "foreign" object to be fetched.  Setting this value is only necessary if the L<map class|/map_class> has more than one foreign key or "many to one" relationship that points to one of the classes that it maps between.

In the L<example|EXAMPLE> above, the value of L<map_from> would be "color" when defining the "many to many" relationship in the C<Widget> class, or "widget" when defining the "many to many" relationship in the C<Color> class.  Neither of these settings is necessary in the example because the C<WidgetColorMap> class has one foreign key that points to each class, so there is no ambiguity.

=item B<query_args [ARRAYREF]>

Get or set a reference to an array of query arguments to add to the L<query|Rose::DB::Object::Manager/query> passed to the L<manager_method|/manager_method> when fetching objects.

This can be used to limit the objects fetched via this relationship.  For example, modifying the L<example|/EXAMPLE> above:

  Widget->meta->add_relationship
  (
    colors =>
    {
      type       => 'many to many',
      map_class  => 'WidgetColorMap',
      query_args => [ name => { like => '%e%' } ],
    },
  );

See the documentation for L<Rose::DB::Object::Manager>'s L<get_objects|Rose::DB::Object::Manager/get_objects> method for a full list of valid C<query> arguments.

=item B<share_db [BOOL]>

Get or set a boolean flag that indicates whether or not all of the classes involved in fetching objects via this relationship (including the objects themselves) will share the same L<Rose::DB>-derived L<db|Rose::DB::Object/db> object.  Defaults to true.

=item B<type>

Returns "many to many".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
