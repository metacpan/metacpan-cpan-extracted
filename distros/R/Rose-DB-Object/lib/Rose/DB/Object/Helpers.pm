package Rose::DB::Object::Helpers;

use strict;

use Rose::DB::Object::Constants qw(:all);

use Rose::Object::MixIn;
our @ISA = qw(Rose::Object::MixIn);

require Rose::DB::Object::Util;

use Carp;

our $VERSION = '0.812';

__PACKAGE__->export_tags
(
  all => 
  [
    qw(clone clone_and_reset load_or_insert load_or_save insert_or_update 
       insert_or_update_on_duplicate_key load_speculative
       column_value_pairs column_accessor_value_pairs 
       column_mutator_value_pairs 
       column_values_as_yaml column_values_as_json
       traverse_depth_first as_tree init_with_tree new_from_tree
       init_with_deflated_tree new_from_deflated_tree
       as_yaml new_from_yaml init_with_yaml
       as_json new_from_json init_with_json
       init_with_column_value_pairs
       has_loaded_related strip forget_related
       dirty_columns) 
  ],

  # This exists for the benefit of the test suite
  all_noprereq =>
  [
    qw(clone clone_and_reset load_or_insert load_or_save insert_or_update 
       insert_or_update_on_duplicate_key load_speculative
       column_value_pairs column_accessor_value_pairs 
       column_mutator_value_pairs 
       traverse_depth_first as_tree init_with_tree new_from_tree
       init_with_deflated_tree new_from_deflated_tree
       init_with_column_value_pairs
       has_loaded_related strip forget_related
       dirty_columns)
  ],
);

#
# Class data
#

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    '_json_object'
  ],
);

#
# Class methods
#

sub json_encoder
{
  my($class) = shift;

  my $json = $class->_json_object;

  unless(defined $json)
  {
    $json = $class->init_json_encoder;
  }

  return $json;
}

sub init_json_encoder
{
  require JSON;

  croak "JSON version 2.00 or later is required.  You have $JSON::VERSION"
    unless($JSON::VERSION >= 2.00);

  return JSON->new->utf8->space_after;
}

*json_decoder = \&json_encoder;

#
# Object methods
#

sub load_speculative { shift->load(@_, speculative => 1) }

sub load_or_insert
{
  my($self) = shift;

  my($ret, @ret, $loaded, $error);

  TRY:
  {
    local $@;

    # Ignore any errors due to missing primary/unique keys
    $loaded = eval
    {  
      if(wantarray)
      {
        @ret = $self->load(@_, speculative => 1);
        return $ret[0]  if($ret[0]); # return from eval
      }
      else
      {
        $ret = $self->load(@_, speculative => 1);
        return $ret  if($ret); # return from eval
      }

      return 0; # return from eval
    };

    $error = $@;
  }

  if($error)
  {
    # ...but re-throw all other errors
    unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
           $error->code == EXCEPTION_CODE_NO_KEY)
    {
      $self->meta->handle_error($self);
      return 0;
    }
  }

  return wantarray ? @ret : $ret  if($loaded);

  return $self->insert;
}

sub load_or_save
{
  my($self) = shift;

  my($ret, @ret, $loaded, $error);

  TRY:
  {
    local $@;

    # Ignore any errors due to missing primary/unique keys
    $loaded = eval
    {  
      if(wantarray)
      {
        @ret = $self->load(@_, speculative => 1);
        return $ret[0]  if($ret[0]); # return from eval
      }
      else
      {
        $ret = $self->load(@_, speculative => 1);
        return $ret  if($ret); # return from eval
      }

      return 0; # return from eval
    };

    $error = $@;
  }

  if($error)
  {
    # ...but re-throw all other errors
    unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
           $error->code == EXCEPTION_CODE_NO_KEY)
    {
      $self->meta->handle_error($self);
      return 0;
    }
  }

  return wantarray ? @ret : $ret  if($loaded);

  return $self->save;
}


sub insert_or_update
{
  my($self) = shift;

  # Initially trust the metadata
  if($self->{STATE_IN_DB()})
  {
    local $@;
    eval { $self->save(@_, update => 1) };
    return $self || 1  unless($@); 
  }

  my $meta = $self->meta;

  # This is more "correct"
  #my $clone = clone($self);

  # ...but this is a lot faster
  my $clone = bless { %$self }, ref($self);

  my($loaded, $error);

  TRY:
  {
    local $@;

    # Ignore any errors due to missing primary/unique keys
    eval { $loaded = $clone->load(speculative => 1) };

    $error = $@;
  }

  if($error)
  {
    # ...but re-throw all other errors
    unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
           $error->code == EXCEPTION_CODE_NO_KEY)
    {
      $meta->handle_error($self);
      return 0;
    }
  }

  if($loaded)
  {
    # The long way...
    my %pk;
    @pk{$meta->primary_key_column_mutator_names} = 
      map { $clone->$_() } $meta->primary_key_column_accessor_names;
    $self->init(%pk);

    # The short (but dirty) way
    #my @pk_keys = $meta->primary_key_column_db_value_hash_keys;
    #@$self{@pk_keys} = @$clone{@pk_keys};

    return $self->save(@_, update => 1);
  }

  return $self->save(@_, insert => 1)
}

sub insert_or_update_on_duplicate_key
{
  my($self) = shift;

  unless($self->db->supports_on_duplicate_key_update)
  {
    return insert_or_update($self, @_);
  }

  return $self->save(@_, insert => 1, on_duplicate_key_update => 1);
}

__PACKAGE__->pre_import_hook(column_values_as_yaml => sub { require YAML::Syck });

sub column_values_as_yaml
{
  local $_[0]->{STATE_SAVING()} = 1;
  YAML::Syck::Dump(scalar Rose::DB::Object::Helpers::column_value_pairs(shift))
}

__PACKAGE__->pre_import_hook(column_values_as_json => sub { require JSON });

sub column_values_as_json
{
  local $_[0]->{STATE_SAVING()} = 1;
  __PACKAGE__->json_encoder->encode(scalar Rose::DB::Object::Helpers::column_value_pairs(shift))
}

sub init_with_column_value_pairs
{
  my($self) = shift;

  my $hash = @_ == 1 ? shift : { @_ };
  my $meta = $self->meta;

  local $self->{STATE_LOADING()} = 1;

  while(my($name, $value) = each(%$hash))
  {
    next  unless(length $name);
    my $method = $meta->column($name)->mutator_method_name;
    $self->$method($value);
  }

  return $self;
}

sub column_value_pairs
{
  my($self) = shift;

  my %pairs;

  my $methods = $self->meta->column_accessor_method_names_hash;

  while(my($column, $method) = each(%$methods))
  {
    $pairs{$column} = $self->$method();
  }

  return wantarray ? %pairs : \%pairs;
}

sub key_column_value_pairs
{
  my($self) = shift;

  my %pairs;

  my $methods = $self->meta->key_column_accessor_method_names_hash;

  while(my($column, $method) = each(%$methods))
  {
    $pairs{$column} = $self->$method();
  }

  return wantarray ? %pairs : \%pairs;
}

sub column_accessor_value_pairs
{
  my($self) = shift;

  my %pairs;

  foreach my $method ($self->meta->column_accessor_method_names)
  {
    $pairs{$method} = $self->$method();
  }

  return wantarray ? %pairs : \%pairs;
}

sub column_mutator_value_pairs
{
  my($self) = shift;

  my %pairs;

  foreach my $column ($self->meta->columns)
  {
    my $method = $column->accessor_method_name;
    $pairs{$column->mutator_method_name} = $self->$method();
  }

  return wantarray ? %pairs : \%pairs;
}

sub clone
{
  my($self) = shift;
  my $class = ref $self;
  local $self->{STATE_CLONING()} = 1;
  my @mutators = $self->meta->column_mutator_method_names;
  my $mutator;
  return $class->new(map
  {
    (defined($mutator = shift(@mutators)) && defined $_) ? 
      ($mutator => $self->$_()) : ()
  }
  $self->meta->column_accessor_method_names);
}

sub clone_and_reset
{
  my($self) = shift;
  my $class = ref $self;
  local $self->{STATE_CLONING()} = 1;
  my @mutators = $self->meta->column_mutator_method_names;
  my $mutator;
  my $clone = $class->new(map
  {
    (defined($mutator = shift(@mutators)) && defined $_) ? 
      ($mutator => $self->$_()) : ()
  }
  $self->meta->column_accessor_method_names);

  my $meta = $class->meta;

  no strict 'refs';

  # Blank all primary and unique key columns
  foreach my $method ($meta->primary_key_column_mutator_names)
  {
    $clone->$method(undef);
  }

  foreach my $uk ($meta->unique_keys)
  {
    foreach my $column ($uk->columns)
    {
      my $method = $meta->column_mutator_method_name($column);
      $clone->$method(undef);
    }
  }

  # Also copy db object, if any
  if(my $db = $self->{'db'})
  {
    #$self->{FLAG_DB_IS_PRIVATE()} = 0;
    $clone->db($db);
  }

  return $clone;
}

sub has_loaded_related
{
  my($self) = shift;

  my $rel; # really a relationship or fk

  my $meta = $self->meta;

  if(@_ == 1)
  {
    my $name = shift;

    if($rel = $meta->foreign_key($name))
    {
      return $rel->object_has_foreign_object($self) ? 1 : 0;
    }
    elsif($rel = $meta->relationship($name))
    {
      return $rel->object_has_related_objects($self) ? 1 : 0;
    }
    else
    {
      croak "No foreign key or relationship named '$name' found in ",
            $meta->class;
    }
  }
  else
  {
    my %args = @_;
    my $name;

    if($name = $args{'foreign_key'})
    {
      $rel = $meta->foreign_key($name) 
        or croak "No foreign key named '$name' found in ", $meta->class;

      return $rel->object_has_foreign_object($self) ? 1 : 0;
    }
    elsif($name = $args{'relationship'})
    {
      $rel = $meta->relationship($name) 
        or croak "No relationship named '$name' found in ", $meta->class;

      return $rel->object_has_related_objects($self) ? 1 : 0;
    }
    else
    {
      croak "Missing foreign key or relationship name argument";
    }
  }
}

sub forget_related
{
  my($self) = shift;

  my $rel; # really a relationship or fk

  my $meta = $self->meta;

  if(@_ == 1)
  {
    my $name = shift;

    if($rel = $meta->foreign_key($name))
    {
      return $rel->forget_foreign_object($self);
    }
    elsif($rel = $meta->relationship($name))
    {
      return $rel->forget_related_objects($self);
    }
    else
    {
      croak "No foreign key or relationship named '$name' found in ",
            $meta->class;
    }
  }
  else
  {
    my %args = @_;
    my $name;

    if($name = $args{'foreign_key'})
    {
      $rel = $meta->foreign_key($name) 
        or croak "No foreign key named '$name' found in ", $meta->class;

      return $rel->forget_foreign_object($self);
    }
    elsif($name = $args{'relationship'})
    {
      $rel = $meta->relationship($name) 
        or croak "No relationship named '$name' found in ", $meta->class;

      return $rel->forget_related_objects($self);
    }
    else
    {
      croak "Missing foreign key or relationship name argument";
    }
  }
}

sub strip
{
  my($self) = shift;

  my %args = @_;

  my %leave = map { $_ => 1 } (ref $args{'leave'} ? @{$args{'leave'}} : ($args{'leave'} || ''));

  my $meta = $self->meta;

  if($leave{'relationships'} || $leave{'related_objects'})
  {
    foreach my $rel ($meta->relationships)
    {
      if(my $objs = $rel->object_has_related_objects($self))
      {
        foreach my $obj (@$objs)
        {
          Rose::DB::Object::Helpers::strip($obj, @_);
        }
      }
    }
  }
  else
  {
    foreach my $rel ($meta->relationships)
    {
      delete $self->{$rel->name};
    }
  }

  if($leave{'foreign_keys'} || $leave{'related_objects'})
  {
    foreach my $rel ($meta->foreign_keys)
    {
      if(my $obj = $rel->object_has_foreign_object($self))
      {
        Rose::DB::Object::Helpers::strip($obj, @_);
      }
    }
  }
  else
  {
    foreach my $fk ($meta->foreign_keys)
    {
      delete $self->{$fk->name};
    }
  }

  if($leave{'db'})
  {
    $self->{'db'}->dbh(undef)  if($self->{'db'});
  }
  else
  {
    delete $self->{'db'};
  }

  # Strip "on-save" code references: destructive!
  unless($args{'strip_on_save_ok'})
  {
    if(__contains_code_ref($self->{ON_SAVE_ATTR_NAME()}))
    {
      croak qq(Refusing to strip "on-save" actions from ), ref($self),
        qq( object without strip_on_save_ok parameter);
    }
  }

  delete $self->{ON_SAVE_ATTR_NAME()};

  # Reference to metadata object will be regenerated as needed
  delete $self->{META_ATTR_NAME()};

  return $self;
}

sub __contains_code_ref
{
  my($hash_ref) = shift;

  foreach my $key (keys %$hash_ref)
  {
    return 1  if(ref $hash_ref->{$key} eq 'CODE');

    if(ref $hash_ref->{$key} eq 'HASH')
    {
      return 1  if(__contains_code_ref($hash_ref->{$key}));
    }
    else
    {
      Carp::confess "Unexpected reference encountered: $hash_ref->{$key}";
    }
  }
}

# XXX: A value that is unlikely to exist in a primary key column value
use constant PK_JOIN => "\0\2,\3\0";

sub primary_key_as_string
{
  my($self, $joiner) = @_;
  return join($joiner || PK_JOIN, grep { defined } map { $self->$_() } $self->meta->primary_key_column_accessor_names);
}

use constant DEFAULT_MAX_DEPTH => 100;

sub traverse_depth_first
{
  my($self) = shift;

  my($context, $handlers, $exclude, $prune, $max_depth);

  my $visited    = {};
  my $force_load = 0;

  if(@_ == 1)
  {
    $handlers->{'object'} = shift;
  }
  else
  {
    my %args = @_;
    $handlers   = $args{'handlers'} || {};
    $force_load = $args{'force_load'} || 0;
    $context    = $args{'context'};
    $exclude    = $args{'exclude'} || 0;
    $prune      = $args{'prune'};
    $max_depth  = exists $args{'max_depth'} ? $args{'max_depth'} : DEFAULT_MAX_DEPTH;
    $visited = undef  if($args{'allow_loops'});
  }

  _traverse_depth_first($self, $context ||= {}, $handlers, $exclude, $prune, 0, $max_depth, undef, undef, $visited, $force_load);

  return $context;
}

require Rose::DB::Object::Util;

use constant OK            => 1;
use constant LOOP_AVOIDED  => -1;
use constant HIT_MAX_DEPTH => -2;
use constant FILTERED_OUT  => -3;

sub _traverse_depth_first
{
  my($self, $context, $handlers, $exclude, $prune, $depth, $max_depth, $parent, $rel_meta, $visited, $force_load) = @_;

  if($visited && $visited->{ref($self),Rose::DB::Object::Helpers::primary_key_as_string($self)}++)
  {
    return LOOP_AVOIDED;
  }

  if($handlers->{'object'})
  {
    if($exclude && $exclude->($self, $parent, $rel_meta))
    {
      return FILTERED_OUT;
    }

    if($force_load && !Rose::DB::Object::Util::is_in_db($self))
    {
      $self->load(speculative => 1);
    }

    $context = $handlers->{'object'}->($self, $context, $parent, $rel_meta, $depth);
  }

  if(defined $max_depth && $depth == $max_depth)
  {
    return HIT_MAX_DEPTH;
  }

  REL: foreach my $rel ($self->meta->relationships)
  {
    next  if($prune && $prune->($rel, $self, $depth));

    my $objs = $rel->object_has_related_objects($self);
    # XXX: Call above returns 0 if the collection is an empty array ref
    # XXX: and undef if it's not even a reference (e.g., undef).  This
    # XXX: distinguishes between a collection that has been loaded and
    # XXX: found to have zero items, and one that has never been loaded.
    # XXX: To "un-hack" this, we'd need true tracking of load/store
    # XXX: actions to related collections.  Or we could just omit the
    # XXX: empty collections from the traversal.
    $objs = []  if(defined $objs && !ref $objs);

    if($force_load || $objs)
    {
      unless($objs)
      {
        my $method = $rel->method_name('get_set_on_save') || 
                     $rel->method_name('get_set_now') ||
                     $rel->method_name('get_set') ||
                     next REL;

        $objs = $self->$method() || next REL;
        $objs = [ $objs ]  unless(ref $objs eq 'ARRAY');
      }

      my $c = $handlers->{'relationship'} ? 
        $handlers->{'relationship'}->($self, $context, $rel) : $context;

      OBJ: foreach my $obj (@$objs)
      {
        next OBJ  if($exclude && $exclude->($obj, $self, $rel));

        my $ret = _traverse_depth_first($obj, $c, $handlers, $exclude, $prune, $depth + 1, $max_depth, $self, $rel, $visited, $force_load);

        if($ret == LOOP_AVOIDED && $handlers->{'loop_avoided'})
        {
          $handlers->{'loop_avoided'}->($obj, $c, $self, $context, $rel) && last OBJ;
        }
      }
    }
  }

  return OK;
}

sub as_tree
{
  my($self) = shift;

  my %args = @_;

  my $deflate    = exists $args{'deflate'} ? $args{'deflate'} : 1;
  my $persistent_columns_only = exists $args{'persistent_columns_only'} ? $args{'persistent_columns_only'} : 0;

  my %tree;

  Rose::DB::Object::Helpers::traverse_depth_first($self, 
    context  => \%tree,
    handlers => 
    {
      object => sub
      {
        my($self, $context, $parent, $relationship, $depth) = @_;

        local $self->{STATE_SAVING()} = 1  if($deflate);

        my $cols = Rose::DB::Object::Helpers::column_value_pairs($self);

        unless($persistent_columns_only)
        {
          # XXX: Inlined version of what would be nonpersistent_column_value_pairs()
          my $methods = $self->meta->nonpersistent_column_accessor_method_names_hash;

          while(my($column, $method) = each(%$methods))
          {
            $cols->{$column} = $self->$method();
          }
        }

        if(ref $context eq 'ARRAY')
        {
          push(@$context, $cols);
          return $cols;
        }
        else
        {
          @$context{keys %$cols} = values %$cols;
          return $context;
        }
      },

      relationship => sub
      {
        my($self, $context, $relationship) = @_;

        my $name = $relationship->name;

        # Croak on name conflicts with columns
        if($self->meta->column($name))
        {
          croak "$self: relationship '", $relationship->name, 
                "' conflicts with column of the same name";
        }

        if($relationship->is_singular)
        {
          return $context->{$name} = {};
        }

        return $context->{$name} = [];
      },

      loop_avoided => sub
      {
        my($object, $context, $parent_object, $parent_context, $relationship) = @_;
        # If any item can't be included due to loops, wipe entire collection and bail
        delete $parent_context->{$relationship->name};
        return 1; # true return means stop processing items in this collection
      },
    },
    @_);

  return \%tree;
}

# XXX: This version requires all relationship and column mutators to have 
# XXX: the same names as the relationships and columns themselves.
# sub init_with_tree { shift->init(@_) }

# XXX: This version requires all relationship mutators to have the same 
# XXX: names as the relationships themselves.
# sub init_with_tree
# {
#   my($self) = shift;
# 
#   my $meta = $self->meta;
# 
#   while(my($name, $value) = each(%{@_ == 1 ? $_[0] : {@_}}))
#   {
#     next  unless(length $name);
#     my $method;
# 
#     if(my $column = $meta->column($name))
#     {
#       $method = $column->mutator_method_name;
#       $self->$method($value);
#     }
#     elsif($meta->relationship($name))
#     {
#       $self->$name($value);
#     }
#   }
# 
#   return $self;
# }

our $Deflated = 0;

sub init_with_deflated_tree
{
  local $Deflated = 1;
  Rose::DB::Object::Helpers::init_with_tree(@_);
}

sub init_with_tree
{
  my($self) = shift;

  my $meta = $self->meta;

  my %non_column;

  # Process all columns first
  while(my($name, $value) = each(%{@_ == 1 ? $_[0] : {@_}}))
  {
    next  unless(length $name);

    if(my $column = $meta->column($name))
    {
      local $self->{STATE_LOADING()} = 1  if($Deflated);
      my $method = $column->mutator_method_name;
      $self->$method($value);
    }
    else
    {
      $non_column{$name} = $value;
    }
  }

  # Process relationships and non-column attributes next
  while(my($name, $value) = each(%non_column))
  {
    if(my $rel = $meta->relationship($name))
    {
      my $method = $rel->method_name('get_set_on_save') || 
                $rel->method_name('get_set') ||
                next;

      my $ref = ref $value;

      if($ref eq 'HASH')
      {
        # Split hash into relationship values and everything else
        my %rel_vals;

        my %is_rel = map { $_->name => 1 } $rel->can('foreign_class') ? 
          $rel->foreign_class->meta->relationships : $rel->class->meta->relationships;

        foreach my $k (keys %$value)  
        {
          $rel_vals{$k} = delete $value->{$k}  if($is_rel{$k});
        }

        # %$value now has non-relationship keys only
        my $object = $self->$method(%$value);

        # Recurse on relationship key
        Rose::DB::Object::Helpers::init_with_tree($object, \%rel_vals)  if(%rel_vals);

        # Repair original hash
        @$value{keys %rel_vals} = values %rel_vals;
      }
      elsif($ref eq 'ARRAY')
      {
        my(@objects, @sub_objects);

        foreach my $item (@$value)
        {
          # Split hash into relationship values and everything else
          my %rel_vals;

          my %is_rel = map { $_->name => 1 } $rel->can('foreign_class') ? 
            $rel->foreign_class->meta->relationships : $rel->class->meta->relationships;

          foreach my $k (keys %$item)
          {
            $rel_vals{$k} = delete $item->{$k}  if($is_rel{$k});
          }

          # %$item now has non-relationship keys only
          push(@objects, { %$item }); # shallow copy is sufficient

          push(@sub_objects, \%rel_vals);

          # Repair original hash
          @$item{keys %rel_vals} = values %rel_vals;
        }

        # Add the related objects
        $self->$method(\@objects);

        # Recurse on the sub-objects
        foreach my $object (@{ $self->$method() })
        {
          my $sub_objects = shift(@sub_objects);
          Rose::DB::Object::Helpers::init_with_tree($object, $sub_objects)  if(%$sub_objects);
        }
      }
      else
      {
        Carp::cluck "Unknown reference encountered in $self tree: $name => $value";
      }
    }
    elsif($self->can($name))
    {
      $self->$name($value);
    }

    # XXX: Silently ignore all other name/value pairs
  }

  return $self;
}

sub new_from_tree
{
  my $self = shift->new;
  $self->Rose::DB::Object::Helpers::init_with_tree(@_);
}

sub new_from_deflated_tree
{
  my $self = shift->new;
  $self->Rose::DB::Object::Helpers::init_with_deflated_tree(@_);
}

__PACKAGE__->pre_import_hook(new_from_json => sub { require JSON });
__PACKAGE__->pre_import_hook(new_from_yaml => sub { require YAML::Syck });

sub new_from_json { new_from_tree(shift, __PACKAGE__->json_decoder->decode(@_)) }
sub new_from_yaml { new_from_tree(shift, YAML::Syck::Load(@_)) }

__PACKAGE__->pre_import_hook(init_with_json => sub { require JSON });
__PACKAGE__->pre_import_hook(init_with_yaml => sub { require YAML::Syck });

sub init_with_json { init_with_tree(shift, __PACKAGE__->json_decoder->decode(@_)) }
sub init_with_yaml { init_with_tree(shift, YAML::Syck::Load(@_)) }

__PACKAGE__->pre_import_hook(as_json => sub { require JSON });
__PACKAGE__->pre_import_hook(as_yaml => sub { require YAML::Syck });

sub as_json { __PACKAGE__->json_encoder->encode(scalar as_tree(@_, deflate => 1)) }
sub as_yaml { YAML::Syck::Dump(scalar as_tree(@_, deflate => 1)) }  

sub dirty_columns
{
  my($self) = shift;

  if(@_)
  {
    foreach my $column (@_)
    {
      my $name = 
        UNIVERSAL::isa($column, 'Rose::DB::Object::Metadata::Column') ? 
          $column->name : $column;
      Rose::DB::Object::Util::set_column_value_modified($self, $name);
    }

    return;
  }

  return wantarray ? keys %{$self->{MODIFIED_COLUMNS()}} :
                     scalar keys %{$self->{MODIFIED_COLUMNS()}};
}

1;

__END__

=head1 NAME

Rose::DB::Object::Helpers - A mix-in class containing convenience methods for Rose::DB::Object.

=head1 SYNOPSIS

  package MyDBObject;

  use Rose::DB::Object;
  our @ISA = qw(Rose::DB::Object);

  use Rose::DB::Object::Helpers 'clone', 
    { load_or_insert => 'find_or_create' };
  ...

  $obj = MyDBObject->new(id => 123);
  $obj->find_or_create();

  $obj2 = $obj->clone;

=head1 DESCRIPTION

L<Rose::DB::Object::Helpers> provides convenience methods from use with L<Rose::DB::Object>-derived classes.  These methods do not exist in L<Rose::DB::Object> in order to keep the method namespace clean.  (Each method added to L<Rose::DB::Object> is another potential naming conflict with a column accessor.)

This class inherits from L<Rose::Object::MixIn>.  See the L<Rose::Object::MixIn> documentation for a full explanation of how to import methods from this class.  The helper methods themselves are described below.

=head1 FUNCTIONS VS. METHODS

Due to the "wonders" of Perl 5's object system, any helper method described here can also be used as a L<Rose::DB::Object::Util>-style utility I<function> that takes a L<Rose::DB::Object>-derived object as its first argument.  Example:

  # Import two helpers
  use Rose::DB::Object::Helpers qw(clone_and_reset traverse_depth_first);

  $o = My::DB::Object->new(...);

  clone_and_reset($o); # Imported helper "method" called as function

  # Imported helper "method" with arguments called as function
  traverse_depth_first($o, handlers => { ... }, max_depth => 2);

Why, then, the distinction between L<Rose::DB::Object::Helpers> methods and L<Rose::DB::Object::Util> functions?  It's simply a matter of context.  The functions in L<Rose::DB::Object::Util> are most useful in the context of the internals (e.g., writing your own L<column method-maker|Rose::DB::Object::Metadata::Column/"MAKING METHODS">) whereas L<Rose::DB::Object::Helpers> methods are most often added to a common L<Rose::DB::Object>-derived base class and then called as object methods by all classes that inherit from it.

The point is, these are just conventions.  Use any of these subroutines as functions or as methods as you see fit.  Just don't forget to pass a L<Rose::DB::Object>-derived object as the first argument when calling as a function.

=head1 OBJECT METHODS

=head2 as_json [PARAMS]

Returns a JSON-formatted string created from the object tree as created by the L<as_tree|/as_tree> method.  PARAMS are the same as for the L<as_tree|/as_tree> method, except that the C<deflate> parameter is ignored (it is always set to true).

You must have the L<JSON> module version 2.12 or later installed in order to use this helper method.  If you have the L<JSON::XS> module version 2.2222 or later installed, this method will work a lot faster.

=head2 as_tree [PARAMS]

Returns a reference to a hash of name/value pairs representing the column values of this object as well as any nested sub-objects.  The PARAMS name/value pairs dictate the details of the sub-object traversal.  Valid parameters are:

=over 4

=item B<allow_loops BOOL>

If true, allow loops during the traversal (e.g., A -E<gt> B -E<gt> C -E<gt> A).  The default value is false.

=item B<deflate BOOL>

If true, the values in the tree will be simple scalars suitable for storage in the database (e.g., a date string like "2005-12-31" instead of a L<DateTime> object).  The default is true.

=item B<exclude CODEREF>

A reference to a subroutine that is called on each L<Rose::DB::Object>-derived object encountered during the traversal.  It is passed the object, the parent object (undef, if none), and the  L<Rose::DB::Object::Metadata::Relationship>-derived object (undef, if none) that led to this object.  If the subroutine returns true, then this object is not processed.  Example:

    exclude => sub
    {
      my($object, $parent, $rel_meta) = @_;
      ...
      return 1  if($should_exclude);
      return 0;
    },

=item B<force_load BOOL>

If true, related sub-objects will be loaded from the database.  If false, then only the sub-objects that have already been loaded from the database will be traversed.  The default is false.

=item B<max_depth DEPTH>

Do not descend past DEPTH levels.  Depth is an integer starting from 0 for the object that the L<as_tree|/as_tree> method was called on and increasing with each level of related objects.  The default value is 100.

=item B<persistent_columns_only BOOL>

If true, L<non-persistent columns|Rose::DB::Object::Metadata/nonpersistent_columns> will not be included in the tree.  The default is false.

=item B<prune CODEREF>

A reference to a subroutine that is called on each L<Rose::DB::Object::Metadata::Relationship>-derived object encountered during traversal.  It is passed the relationship object, the parent object, and the depth.  If the subroutine returns true, then the entire sub-tree below this relationship will not be traversed.  Example:

    prune => sub
    {
      my($rel_meta, $object, $depth) = @_;
      ...
      return 1  if($should_prune);
      return 0;
    },

=back

B<Caveats>: Currently, you cannot have a relationship and a column with the same name in the same class.  This should not happen without explicit action on the part of the class creator, but it is technically possible.  The result of serializing such an object using L<as_tree|/as_tree> is undefined.  This limitation may be removed in the future.

The exact format of the "tree" data structure returned by this method is not public and may change in the future (e.g., to overcome the limitation described above).

=head2 as_yaml [PARAMS]

Returns a YAML-formatted string created from the object tree as created by the L<as_tree|/as_tree> method.  PARAMS are the same as for the L<as_tree|/as_tree> method, except that the C<deflate> parameter is ignored (it is always set to true).

You must have the L<YAML::Syck> module installed in order to use this helper method.

=head2 clone

Returns a new object initialized with the column values of the existing object.  For example, imagine a C<Person> class with three columns, C<id>, C<name>, and C<age>.

    $a = Person->new(id => 123, name => 'John', age => 30);

This use of the C<clone()> method:

    $b = $a->clone;

is equivalent to this:

    $b = Person->new(id => $a->id, name => $a->name, age => $a->age);

=head2 clone_and_reset

This is the same as the L<clone|/clone> method described above, except that it also sets all of the L<primary|Rose::DB::Object::Metadata/primary_key_columns> and L<unique key columns|Rose::DB::Object::Metadata/unique_keys> to undef.  If the cloned object has a L<db|Rose::DB::Object/db> attribute, then it is copied to the clone object as well.

For example, imagine a C<Person> class with three columns, C<id>, C<name>, and C<age>, where C<id> is the primary key and C<name> is a unique key.

    $a = Person->new(id => 123, name => 'John', age => 30, db => $db);

This use of the C<clone_and_reset()> method:

    $b = $a->clone_and_reset;

is equivalent to this:

    $b = Person->new(id => $a->id, name => $a->name, age => $a->age);
    $b->id(undef);   # reset primary key
    $b->name(undef); # reset unique key
    $b->db($a->db);  # copy db

=head2 column_values_as_json

Returns a string containing a JSON representation of the object's column values.  You must have the L<JSON> module version 2.12 or later installed in order to use this helper method.  If you have the L<JSON::XS> module version 2.2222 or later installed, this method will work a lot faster.

=head2 column_values_as_yaml

Returns a string containing a YAML representation of the object's column values.  You must have the L<YAML::Syck> module installed in order to use this helper method.

=head2 column_accessor_value_pairs

Returns a hash (in list context) or reference to a hash (in scalar context) of column accessor method names and column values.  The keys of the hash are the L<accessor method names|Rose::DB::Object::Metadata::Column/accessor_method_name> for the columns.  The values are retrieved by calling the L<accessor method|Rose::DB::Object::Metadata::Column/accessor_method_name> for each column.

=head2 column_mutator_value_pairs

Returns a hash (in list context) or reference to a hash (in scalar context) of column mutator method names and column values.  The keys of the hash are the L<mutator method names|Rose::DB::Object::Metadata::Column/mutator_method_name> for the columns.  The values are retrieved by calling the L<accessor method|Rose::DB::Object::Metadata::Column/accessor_method_name> for each column.

=head2 column_value_pairs

Returns a hash (in list context) or reference to a hash (in scalar context) of column name and value pairs.  The keys of the hash are the L<names|Rose::DB::Object::Metadata::Column/name> of the columns.  The values are retrieved by calling the L<accessor method|Rose::DB::Object::Metadata::Column/accessor_method_name> for each column.

=head2 dirty_columns [ NAMES | COLUMNS ]

Given a list of column names or L<Rose::DB::Object::Metadata::Column>-derived objects, mark each column in the invoking object as L<modifed|Rose::DB::Object::Util/set_column_value_modified>.

If passed no arguments, returns a list of all modified columns in list context or the number of modified columns in scalar context.

=head2 forget_related [ NAME | PARAMS ]

Given a foreign key or relationship name, forget any L<previously loaded|/has_loaded_related> objects related by the specified foreign key or relationship.  Normally, any objects loaded by the default accessor methods for relationships and foreign keys are fetched from the database only the first time they are asked for, and simply returned thereafter.  Asking them to be "forgotten" causes them to be fetched anew from the database the next time they are asked for.

If the related object name is passed as a plain string NAME, then a foreign key with that name is looked up.  If no such foreign key exists, then a relationship with that name is looked up.  If no such relationship or foreign key exists, a fatal error will occur.  Example:

    $foo->forget_related('bar');

It's generally not a good idea to add a foreign key and a relationship with the same name, but it is technically possible.  To specify the domain of the name, pass the name as the value of a C<foreign_key> or C<relationship> parameter.  Example:

    $foo->forget_related(foreign_key => 'bar');
    $foo->forget_related(relationship => 'bar');

=head2 has_loaded_related [ NAME | PARAMS ]

Given a foreign key or relationship name, return true if one or more related objects have been loaded into the current object, false otherwise.

If the name is passed as a plain string NAME, then a foreign key with that name is looked up.  If no such foreign key exists, then a relationship with that name is looked up.  If no such relationship or foreign key exists, a fatal error will occur.  Example:

    $foo->has_loaded_related('bar');

It's generally not a good idea to add a foreign key and a relationship with the same name, but it is technically possible.  To specify the domain of the name, pass the name as the value of a C<foreign_key> or C<relationship> parameter.  Example:

    $foo->has_loaded_related(foreign_key => 'bar');
    $foo->has_loaded_related(relationship => 'bar');

=head2 init_with_column_value_pairs [ HASH | HASHREF ]

Initialize an object with a hash or reference to a hash of column/value pairs.  This differs from the inherited L<init|Rose::Object/init> method in that it accepts column names rather than method names.  A column name may not be the same as its mutator method name if the column is L<aliased|Rose::DB::Object::Metadata/alias_column>, for example.

    $p = Person->new; # assume "type" column is aliased to "person_type"

    # init() takes method/value pairs
    $p->init(person_type => 'cool', age => 30);

    # Helper takes a hashref of column/value pairs
    $p->init_with_column_value_pairs({ type => 'cool', age => 30 });

    # ...or a hash of column/value pairs
    $p->init_with_column_value_pairs(type => 'cool', age => 30);

=head2 init_with_json JSON

Initialize the object with a JSON-formatted string.  The JSON string must be in the format returned by the L<as_json|/as_json> (or L<column_values_as_json|/column_values_as_json>) method.  Example:

    $p1 = Person->new(name => 'John', age => 30);
    $json = $p1->as_json;

    $p2 = Person->new;
    $p2->init_with_json($json);

    print $p2->name; # John
    print $p2->age;  # 30

=head2 init_with_deflated_tree TREE

This is the same as the L<init_with_tree|/init_with_tree> method, except that it expects all the values to be simple scalars suitable for storage in the database (e.g., a date string like "2005-12-31" instead of a L<DateTime> object).  In other words, the TREE should be in the format generated by the L<as_tree|/as_tree> method called with the C<deflate> parameter set to true.  Initializing objects in this way is slightly more efficient.

=head2 init_with_tree TREE

Initialize the object with a Perl data structure in the format returned from the L<as_tree|/as_tree> method.  Example:

    $p1 = Person->new(name => 'John', age => 30);
    $tree = $p1->as_tree;

    $p2 = Person->new;
    $p2->init_with_tree($tree);

    print $p2->name; # John
    print $p2->age;  # 30

=head2 init_with_yaml YAML

Initialize the object with a YAML-formatted string.  The YAML string must be in the format returned by the L<as_yaml|/as_yaml> (or L<column_values_as_yaml|/column_values_as_yaml>) method.  Example:

    $p1 = Person->new(name => 'John', age => 30);
    $yaml = $p1->as_yaml;

    $p2 = Person->new;
    $p2->init_with_yaml($yaml);

    print $p2->name; # John
    print $p2->age;  # 30

=head2 insert_or_update [PARAMS]

If the object already exists in the database, then update it.  Otherwise, insert it.  Any PARAMS are passed on to the call to L<save|Rose::DB::Object/save> (which is supplied with the appropriate C<insert> or C<update> boolean parameter).

This method differs from the standard L<save|Rose::DB::Object/save> method in that L<save|Rose::DB::Object/save> decides to L<insert|Rose::DB::Object/insert> or L<update|Rose::DB::Object/update> based solely on whether or not the object was previously L<load|Rose::DB::Object/load>ed.  This method will take the extra step of actually attempting to L<load|Rose::DB::Object/load> the object to see whether or not it's in the database.

The return value of the L<save|Rose::DB::Object/save> method is returned.

=head2 insert_or_update_on_duplicate_key [PARAMS]

Update or insert a row with a single SQL statement, depending on whether or not a row with the same primary or unique key already exists.  Any PARAMS are passed on to the call to L<save|Rose::DB::Object/save> (which is supplied with the appropriate C<insert> or C<update> boolean parameter).

If the current database does not support the "ON DUPLICATE KEY UPDATE" SQL extension, then this method simply calls the L<insert_or_update|/insert_or_update> method, passing all PARAMS.

Currently, the only database that supports "ON DUPLICATE KEY UPDATE" is MySQL, and only in version 4.1.0 or later.  You can read more about the feature here:

L<http://dev.mysql.com/doc/refman/5.1/en/insert-on-duplicate.html>

Here's a quick example of the SQL syntax:

    INSERT INTO table (a, b, c) VALUES (1, 2, 3) 
      ON DUPLICATE KEY UPDATE a = 1, b = 2, c = 3;

Note that there are two sets of columns and values in the statement.  This presents a choice: which columns to put in the "INSERT" part, and which to put in the "UPDATE" part.

When using this method, if the object was previously L<load|Rose::DB::Object/load>ed from the database, then values for all columns are put in both the "INSERT" and "UPDATE" portions of the statement.

Otherwise, all columns are included in both clauses I<except> those belonging to primary keys or unique keys which have only undefined values.  This is important because it allows objects to be updated based on a single primary or unique key, even if other possible keys exist, but do not have values set.  For example, consider this table with the following data:

    CREATE TABLE parts
    (
      id      INT PRIMARY KEY,
      code    CHAR(3) NOT NULL,
      status  CHAR(1),

      UNIQUE(code)
    );

    INSERT INTO parts (id, code, status) VALUES (1, 'abc', 'x');

This code will update part id 1, setting its "status" column to "y".

    $p = Part->new(code => 'abc', status => 'y');
    $p->insert_or_update_on_duplicate_key;

The resulting SQL:

    INSERT INTO parts (code, status) VALUES ('abc', 'y') 
      ON DUPLICATE KEY UPDATE code = 'abc', status = 'y';

Note that the "id" column is omitted because it has an undefined value.  The SQL statement will detect the duplicate value for the unique key "code" and then run the "UPDATE" portion of the query, setting "status" to "y".

This method returns true if the row was inserted or updated successfully, false otherwise.  The true value returned on success will be the object itself.  If the object L<overload>s its boolean value such that it is not true, then a true value will be returned instead of the object itself.

Yes, this method name is very long.  Remember that you can rename methods on import.  It is expected that most people will want to rename this method to "insert_or_update", using it in place of the normal L<insert_or_update|/insert_or_update> helper method:

    package My::DB::Object;
    ...
    use Rose::DB::Object::Helpers 
      { insert_or_update_on_duplicate_key => 'insert_or_update' };

=head2 load_or_insert [PARAMS]

Try to L<load|Rose::DB::Object/load> the object, passing PARAMS to the call to the L<load()|Rose::DB::Object/load> method.  The parameter "speculative => 1" is automatically added to PARAMS.  If no such object is found, then the object is L<insert|Rose::DB::Object/insert>ed.

Example:

    # Get object id 123 if it exists, otherwise create it now.
    $obj = MyDBObject->new(id => 123)->load_or_insert;

=head2 load_or_save [PARAMS]

Try to L<load|Rose::DB::Object/load> the object, passing PARAMS to the call to the L<load()|Rose::DB::Object/load> method.  The parameter "speculative => 1" is automatically added to PARAMS.  If no such object is found, then the object is L<save|Rose::DB::Object/save>d.

This methods differs from L<load_or_insert|/load_or_insert> in that the L<save|Rose::DB::Object/save> method will also save sub-objects.  See the documentation for L<Rose::DB::Object>'s L<save|Rose::DB::Object/save> method for more information.

Example:

    @perms = (Permission->new(...), Permission->new(...));

    # Get person id 123 if it exists, otherwise create it now
    # along with permission sub-objects.
    $person = Person->new(id => 123, perms => \@perms)->load_or_save;

=head2 load_speculative [PARAMS]

Try to L<load|Rose::DB::Object/load> the object, passing PARAMS to the call to the L<load()|Rose::DB::Object/load> method along with the "speculative => 1" parameter.  See the documentation for L<Rose::DB::Object>'s L<load|Rose::DB::Object/load> method for more information.

Example:

    $obj = MyDBObject->new(id => 123);

    if($obj->load_speculative)
    {
      print "Found object id 123\n";
    }
    else
    {
      print "Object id 123 not found\n";
    }

=head2 new_from_json JSON

The method is the equivalent of creating a new object and then calling the L<init_with_json|/init_with_json> method on it, passing JSON as an argument.  See the L<init_with_json|/init_with_json> method for more information.

=head2 new_from_deflated_tree TREE

The method is the equivalent of creating a new object and then calling the L<init_with_deflated_tree|/init_with_deflated_tree> method on it, passing TREE as an argument.  See the L<init_with_deflated_tree|/init_with_deflated_tree> method for more information.

=head2 new_from_tree TREE

The method is the equivalent of creating a new object and then calling the L<init_with_tree|/init_with_tree> method on it, passing TREE as an argument.  See the L<init_with_tree|/init_with_tree> method for more information.

=head2 new_from_yaml YAML

The method is the equivalent of creating a new object and then calling the L<init_with_yaml|/init_with_yaml> method on it, passing YAML as an argument.  See the L<init_with_yaml|/init_with_yaml> method for more information.

=head2 strip [PARAMS]

This method prepares an object for serialization by stripping out internal structures known to contain code references or other values that do not survive serialization.  The object itself is returned, now stripped.

B<Note:> Operations that were scheduled to happen "on L<save()|Rose::DB::Object/save>" will I<also> be stripped out by this method.  Examples include the databsae update or insertion of any child objects attached to the parent object using C<get_set_on_save>, C<add_on_save>, or C<delete_on_save> methods.  If such operations exist, an exception will be thrown unless the C<strip_on_save_ok> parameter is true.

If your object has these kinds of pending changes, either L<save()|Rose::DB::Object/save> first and then L<strip()|/strip>, or L<clone()|/clone> and then L<strip()|/strip> the clone.

By default, the L<db|Rose::DB::Object/db> object and all sub-objects (foreign keys or relationships) are removed.  PARAMS are optional name/value pairs.  Valid PARAMS are:

=over 4

=item B<leave [ NAME  | ARRAYREF ]>

This parameter specifies which items to leave un-stripped.  The value may be an item name or a reference to an array of item names.  Valid names are:

=over 4

=item B<db>

Do not remove the L<db|Rose::DB::Object/db> object.  The L<db|Rose::DB::Object/db> object will have its DBI database handle (L<dbh|Rose::DB/dbh>) removed, however.

=item B<foreign_keys>

Do not removed sub-objects that have L<already been loaded|/has_loaded_related> by this object through L<foreign keys|Rose::DB::Object::Metadata/foreign_keys>.

=item B<relationships>

Do not removed sub-objects that have L<already been loaded|/has_loaded_related> by this object through L<relationships|Rose::DB::Object::Metadata/relationships>.

=item B<related_objects>

Do not remove any sub-objects (L<foreign keys|Rose::DB::Object::Metadata/foreign_keys> or L<relationships|Rose::DB::Object::Metadata/relationships>) that have L<already been loaded|/has_loaded_related> by this object.  This option is the same as specifying both the C<foreign_keys> and C<relationships> names.

=back

=item B<strip_on_save_ok BOOL>

If true, do not throw an exception when pending "on-save" changes exist in the object; just strip them.  (See description above for details.)  

=back

=head2 B<traverse_depth_first [ CODEREF | PARAMS ]>

Do a depth-first traversal of the L<Rose::DB::Object>-derived object that this method is called on, descending into related objects. If a reference to a subroutine is passed as the sole argument, it is taken as the value of the C<object> key to the C<handlers> parameter hash (see below).  Otherwise, PARAMS name/value pairs are expected.  Valid parameters are:

=over 4

=item B<allow_loops BOOL>

If true, allow loops during the traversal (e.g., A -E<gt> B -E<gt> C -E<gt> A).  The default value is false.

=item B<context SCALAR>

An arbitrary context variable to be passed along to (and possibly modified by) each handler routine (see C<handlers> parameter below).  The context may be any scalar value (e.g., an object, a reference to a hash, etc.)

=item B<exclude CODEREF>

A reference to a subroutine that is called on each L<Rose::DB::Object>-derived object encountered during the traversal.  It is passed the object, the parent object (undef, if none), and the  L<Rose::DB::Object::Metadata::Relationship>-derived object (undef, if none) that led to this object.  If the subroutine returns true, then this object is not processed.  Example:

    exclude => sub
    {
      my($object, $parent, $rel_meta) = @_;
      ...
      return 1  if($should_exclude);
      return 0;
    },

=item B<force_load BOOL>

If true, related sub-objects will be loaded from the database.  If false, then only the sub-objects that have already been loaded from the database will be traversed.  The default is false.

=item B<handlers HASHREF>

A reference to a hash of handler subroutines.  Valid keys, calling context, and the arguments passed to the referenced subroutines are as follows.

=over 4

=item B<object>

This handler is called whenever a L<Rose::DB::Object>-derived object is encountered.  This includes the object that L<traverse_depth_first|/traverse_depth_first> was called on as well as any sub-objects.  The handler is passed the object, the C<context>, the parent object (undef, if none), the L<Rose::DB::Object::Metadata::Relationship>-derived object through which this object was arrived at (undef if none), and the depth.

The handler I<must> return the value to be used as the C<context> during the traversal of any related sub-objects.  The context returned may be different than the context passed in.  Example:

    handlers =>
    {
      object => sub
      {
        my($object, $context, $parent, $rel_meta, $depth) = @_;
        ...

        return $context; # Important!
      }
      ...
    }

=item B<relationship>

This handler is called just before a L<Rose::DB::Object::Metadata::Relationship>-derived object is descended into  (i.e., just before the sub-objectes related through this relationship are processed). The handler is passed the object that contains the relationship, the C<context>, the C<context>, and the L<relationship|Rose::DB::Object::Metadata::Relationship> object itself.

The handler I<must> return the value to be used as the C<context> during the traversal of the objects related through this relationship.  (If you do not define this handler, then the current context object will be used.)  The context returned may be different than the context passed in.  Example:

    handlers =>
    {
      relationship => sub
      {
        my($object, $context, $rel_meta) = @_;
        ...

        return $context; # Important!
      }
      ...
    }

=item B<loop_avoided>

This handler is called after the traversal refuses to process a sub-object in order to avoid a loop.  (This only happens if the C<allow_loops> is parameter is false, obviously.)  The handler is passed the object that was not processed, the C<context>, the parent object, the I<previous> C<context>, and the L<Rose::DB::Object::Metadata::Relationship>-derived object through which the sub-object was related.  Example:

    handlers =>
    {
      loop_avoided => sub
      {
        my($object, $context, $parent, $prev_context, $rel_meta) = @_;
        ...
      }
      ...
    }

=back

=item B<max_depth DEPTH>

Do not descend past DEPTH levels.  Depth is an integer starting from 0 for the object that the L<traverse_depth_first|/traverse_depth_first> method was called on and increasing with each level of related objects.  The default value is 100.

=item B<prune CODEREF>

A reference to a subroutine that is called on each L<Rose::DB::Object::Metadata::Relationship>-derived object encountered during traversal.  It is passed the relationship object, the parent object, and the depth.  If the subroutine returns true, then the entire sub-tree below this relationship will not be traversed.  Example:

    prune => sub
    {
      my($rel_meta, $object, $depth) = @_;
      ...
      return 1  if($should_prune);
      return 0;
    },

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
