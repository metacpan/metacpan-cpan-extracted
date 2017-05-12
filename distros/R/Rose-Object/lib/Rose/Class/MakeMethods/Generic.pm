package Rose::Class::MakeMethods::Generic;

use strict;

use Carp();

our $VERSION = '0.854';

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

our %Scalar;
# (
#   class_name =>
#   {
#     some_attr_name1 => ...,
#     some_attr_name2 => ...,
#     ...
#   },
#   ...
# );

sub scalar
{
  my($class, $name, $args, $options) = @_;

  my %methods;

  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      return $Scalar{$_[0]}{$name} = $_[1]  if(@_ > 1);
      return $Scalar{$_[0]}{$name};
    };
  }
  elsif($interface eq 'get_set_init')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {      
      return $Scalar{$_[0]}{$name} = $_[1]  if(@_ > 1);
      return defined $Scalar{$_[0]}{$name} ? 
        $Scalar{$_[0]}{$name} : ($Scalar{$_[0]}{$name} = $_[0]->$init_method())
    };
  }

  return \%methods;
}

our %Inheritable_Scalar;
# (
#   class_name =>
#   {
#     some_attr_name1 => ...,
#     some_attr_name2 => ...,
#     ...
#   },
#   ...
# );

sub inheritable_scalar
{
  my($class, $name, $args, $options) = @_;

  my %methods;

  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set')
  {
    $methods{$name} = sub 
    {
      my($class) = ref($_[0]) ? ref(shift) : shift;

      if(@_)
      {
        return $Inheritable_Scalar{$class}{$name} = shift;
      }

      return $Inheritable_Scalar{$class}{$name}
        if(exists $Inheritable_Scalar{$class}{$name});

      my @parents = ($class);

      while(my $parent = shift(@parents))
      {
        no strict 'refs';
        foreach my $subclass (@{$parent . '::ISA'})
        {
          push(@parents, $subclass);

          if(exists $Inheritable_Scalar{$subclass}{$name})
          {
            return $Inheritable_Scalar{$subclass}{$name}
          }
        }
      }

      return undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

our %Inheritable_Boolean;

sub inheritable_boolean
{
  my($class, $name, $args, $options) = @_;

  my %methods;

  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set')
  {
    $methods{$name} = sub 
    {
      my($class) = ref($_[0]) ? ref(shift) : shift;

      if(@_)
      {
        return $Inheritable_Boolean{$class}{$name} = $_[0] ? 1 : 0;
      }

      return $Inheritable_Boolean{$class}{$name}
        if(exists $Inheritable_Boolean{$class}{$name});

      my @parents = ($class);

      while(my $parent = shift(@parents))
      {
        no strict 'refs';
        foreach my $subclass (@{$parent . '::ISA'})
        {
          push(@parents, $subclass);

          if(exists $Inheritable_Boolean{$subclass}{$name})
          {
            return $Inheritable_Boolean{$subclass}{$name}
          }
        }
      }

      return undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

our %Hash;
# (
#   class_name =>
#   {
#     key =>
#     {
#       some_attr_name1 => ...,
#       some_attr_name2 => ...,
#       ...
#     },
#     ...
#   },
#   ...
# );

sub hash
{
  my($class, $name, $args) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  if($interface eq 'get_set_all')
  {
    $methods{$name} = sub
    {
      my($class) = ref $_[0] ? ref shift : shift;

      # If called with no arguments, return hash contents
      return wantarray ? %{$Hash{$class}{$key} || {}} : $Hash{$class}{$key}  unless(@_);

      # Set hash to arguments
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $Hash{$class}{$key} = $_[0];
      }
      else
      {
        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        while(@_)
        {
          local $_ = shift;
          $Hash{$class}{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$Hash{$class}{$key} || {}} : $Hash{$class}{$key};
    }
  }
  elsif($interface eq 'clear')
  {
    $methods{$name} = sub
    {
      $Hash{$_[0]}{$key} = {}
    }
  }
  elsif($interface eq 'reset')
  {
    $methods{$name} = sub
    {
      $Hash{$_[0]}{$key} = undef
    }
  }
  elsif($interface eq 'delete')
  {
    $methods{($interface eq 'manip' ? 'delete_' : '') . $name} = sub
    {
      Carp::croak "Missing key(s) to delete"  unless(@_ > 1);
      delete @{$Hash{$_[0]}{$key}}{@_[1 .. $#_]};
    }
  }
  elsif($interface eq 'exists')
  {
    $methods{$name . ($interface eq 'manip' ? '_exists' : '')} = sub
    {
      Carp::croak "Missing key argument"  unless(@_ == 2);
      defined $Hash{$_[0]}{$key} ? exists $Hash{$_[0]}{$key}{$_[1]} : undef;
    }
  }
  elsif($interface =~ /^(?:keys|names)$/)
  {
    $methods{$name} = sub
    {
      wantarray ? (defined $Hash{$_[0]}{$key} ? keys %{$Hash{$_[0]}{$key}} : ()) :
                  (defined $Hash{$_[0]}{$key} ? [ keys %{$Hash{$_[0]}{$key}} ] : []);
    }
  }
  elsif($interface eq 'values')
  {
    $methods{$name} = sub
    {
      wantarray ? (defined $Hash{$_[0]}{$key} ? values %{$Hash{$_[0]}{$key}} : ()) :
                  (defined $Hash{$_[0]}{$key} ? [ values %{$Hash{$_[0]}{$key}} ] : []);
    }
  }
  elsif($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($class) = ref $_[0] ? ref shift : shift;

      # If called with no arguments, return hash contents
      unless(@_)
      {
        return wantarray ? (defined $Hash{$class}{$key} ? %{$Hash{$class}{$key}} : ()) : $Hash{$class}{$key}  
      }

      # If called with a hash ref, set value
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $Hash{$class}{$key} = $_[0];
      }
      else
      {      
        # If called with an index, get that value, or a slice for array refs
        if(@_ == 1)
        {
          return ref $_[0] eq 'ARRAY' ? @{$Hash{$class}{$key}}{@{$_[0]}} : 
                                        $Hash{$class}{$key}{$_[0]};
        }

        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        while(@_)
        {
          local $_ = shift;
          $Hash{$class}{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$Hash{$class}{$key} || {}} : $Hash{$class}{$key};
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}
our %Inheritable_Hash;
# (
#   class_name =>
#   {
#     key =>
#     {
#       some_attr_name1 => ...,
#       some_attr_name2 => ...,
#       ...
#     },
#     ...
#   },
#   ...
# );

sub inheritable_hash
{
  my($class, $name, $args) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $init_method = sub
  {
    my($class) = ref $_[0] ? ref shift : shift;

    # Inherit shallow copy from subclass
    my @parents = ($class);

    SEARCH: while(my $parent = shift(@parents))
    {
      no strict 'refs';
      foreach my $subclass (@{$parent . '::ISA'})
      {
        push(@parents, $subclass);

        if(exists $Inheritable_Hash{$subclass}{$key})
        {
          $Inheritable_Hash{$class}{$key} = { %{$Inheritable_Hash{$subclass}{$key}} };
          last SEARCH;
        }
      }
    }
  };

  if($interface eq 'get_set_all')
  {
    $methods{$name} = sub
    {
      my($class) = ref $_[0] ? ref shift : shift;

      defined $Inheritable_Hash{$class}{$key} || $init_method->($class);

      # If called with no arguments, return hash contents
      return wantarray ? %{$Inheritable_Hash{$class}{$key} || {}} : $Inheritable_Hash{$class}{$key}  unless(@_);

      # Set hash to arguments
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $Inheritable_Hash{$class}{$key} = $_[0];
      }
      else
      {
        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        while(@_)
        {
          local $_ = shift;
          $Inheritable_Hash{$class}{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$Inheritable_Hash{$class}{$key} || {}} : $Inheritable_Hash{$class}{$key};
    }
  }
  elsif($interface eq 'clear')
  {
    $methods{$name} = sub
    {
      $Inheritable_Hash{$_[0]}{$key} = {}
    }
  }
  elsif($interface eq 'reset')
  {
    $methods{$name} = sub
    {
      $Inheritable_Hash{$_[0]}{$key} = undef;
    }
  }
  elsif($interface eq 'delete')
  {
    $methods{($interface eq 'manip' ? 'delete_' : '') . $name} = sub
    {
      Carp::croak "Missing key(s) to delete"  unless(@_ > 1);
      defined $Inheritable_Hash{$_[0]}{$key} || $init_method->($_[0]);
      delete @{$Inheritable_Hash{$_[0]}{$key}}{@_[1 .. $#_]};
    }
  }
  elsif($interface eq 'exists')
  {
    $methods{$name . ($interface eq 'manip' ? '_exists' : '')} = sub
    {
      Carp::croak "Missing key argument"  unless(@_ == 2);
      defined $Inheritable_Hash{$_[0]}{$key} || $init_method->($_[0]);
      defined $Inheritable_Hash{$_[0]}{$key} ? exists $Inheritable_Hash{$_[0]}{$key}{$_[1]} : undef;
    }
  }
  elsif($interface =~ /^(?:keys|names)$/)
  {
    $methods{$name} = sub
    {
      defined $Inheritable_Hash{$_[0]}{$key} || $init_method->($_[0]);
      wantarray ? (defined $Inheritable_Hash{$_[0]}{$key} ? keys %{$Inheritable_Hash{$_[0]}{$key} || {}} : ()) :
                  (defined $Inheritable_Hash{$_[0]}{$key} ? [ keys %{$Inheritable_Hash{$_[0]}{$key} || {}} ] : []);
    }
  }
  elsif($interface eq 'values')
  {
    $methods{$name} = sub
    {
      defined $Inheritable_Hash{$_[0]}{$key} || $init_method->($_[0]);
      wantarray ? (defined $Inheritable_Hash{$_[0]}{$key} ? values %{$Inheritable_Hash{$_[0]}{$key} || {}} : ()) :
                  (defined $Inheritable_Hash{$_[0]}{$key} ? [ values %{$Inheritable_Hash{$_[0]}{$key} || {}} ] : []);
    }
  }
  elsif($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($class) = ref $_[0] ? ref shift : shift;

      defined $Inheritable_Hash{$class}{$key} || $init_method->($class);

      # If called with no arguments, return hash contents
      unless(@_)
      {
        return wantarray ? (defined $Inheritable_Hash{$class}{$key} ? %{$Inheritable_Hash{$class}{$key} || {}} : ()) : $Inheritable_Hash{$class}{$key}  
      }

      # If called with a hash ref, set value
      if(@_ == 1 && ref $_[0] eq 'HASH')
      {
        $Inheritable_Hash{$class}{$key} = $_[0];
      }
      else
      {      
        # If called with an index, get that value, or a slice for array refs
        if(@_ == 1)
        {
          return ref $_[0] eq 'ARRAY' ? @{$Inheritable_Hash{$class}{$key}}{@{$_[0]}} : 
                                        $Inheritable_Hash{$class}{$key}{$_[0]};
        }

        # Push on new values and return complete set
        Carp::croak "Odd number of items in assigment to $name"  if(@_ % 2);

        while(@_)
        {
          local $_ = shift;
          $Inheritable_Hash{$class}{$key}{$_} = shift;
        }
      }

      return wantarray ? %{$Inheritable_Hash{$class}{$key} || {}} : $Inheritable_Hash{$class}{$key};
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

use constant CLASS_VALUE     => 1;
use constant INHERITED_VALUE => 2;
use constant DELETED_VALUE   => 3;

our %Inherited_Hash;
# (
#   some_name =>
#   {
#     class1 => 
#     {
#       meta  => { ... },
#       cache => 
#       {
#         meta =>
#         {
#           attr1 => CLASS_VALUE,
#           attr2 => DELETED_VALUE,
#           ...
#         },
#         attrs =>
#         {
#           attr1 => value1,
#           attr2 => value2,
#           ...
#         },
#       },
#     },
#     class2 => ...,
#     ...
#   },
#   ...
# );

# Used as array indexes to replace {'meta'}, {'attrs'}, and {'cache'}
use constant META  => 0;
use constant CACHE => 1;
use constant ATTRS => 1;

# XXX: This implementation is space-inefficient and pretty silly
sub inherited_hash
{
  my($class, $name, $args) = @_;

  my %methods;

  # Interface example:
  # name:               object_type_class
  # plural_name:        object_type_classes
  #
  # get_set:            object_type_class
  # get_set_all_method: object_type_classes
  # keys_method:        object_type_class_keys
  # cache_method:       object_type_classes_cache
  # exists_method:      object_type_class_exists
  # add_method:         add_object_type_class
  # adds_method:        add_object_type_classes
  # delete_method:      delete_object_type_class
  # deletes_method:     delete_object_type_classes
  # clear_method        clear_object_type_classes
  # inherit_method:     inherit_object_type_class
  # inherits_method:    inherit_object_type_classes

  my $plural_name = $args->{'plural_name'} || $name . 's';

  my $get_set_method     = $name;
  my $get_set_all_method = $args->{'get_set_all_method'} || $args->{'hash_method'} || $plural_name;
  my $keys_method        = $args->{'keys_method'}     || $name . '_keys';
  my $cache_method       = $args->{'cache_method'}    || $plural_name . '_cache';
  my $exists_method      = $args->{'exists_method'}   || $args->{'exists_method'} || $name . '_exists';
  my $add_method         = $args->{'add_method'}      || 'add_' . $name;
  my $adds_method        = $args->{'adds_method'}     || 'add_' . $plural_name;
  my $delete_method      = $args->{'delete_method'}   || 'delete_' . $name;
  my $deletes_method     = $args->{'deletes_method'}  || 'delete_' . $plural_name;
  my $clear_method       = $args->{'clear_method'}    || 'clear_' . $plural_name;
  my $inherit_method     = $args->{'inherit_method'}  || 'inherit_' . $name;
  my $inherits_method    = $args->{'inherits_method'} || 'inherit_' . $plural_name;

  my $interface       = $args->{'interface'} || 'all';

  my $add_implies     = $args->{'add_implies'};
  my $delete_implies  = $args->{'delete_implies'};
  my $inherit_implies = $args->{'inherit_implies'};

  $add_implies = [ $add_implies ]
    if(defined $add_implies && !ref $add_implies);

  $delete_implies = [ $delete_implies ]
    if(defined $delete_implies && !ref $delete_implies);

  $inherit_implies = [ $inherit_implies ]
    if(defined $inherit_implies && !ref $inherit_implies);

  $methods{$cache_method} = sub
  {
    my($class) = ref($_[0]) || $_[0];

    if($Inherited_Hash{$name}{$class}[META]{'cache_is_valid'})
    {
      return   
        wantarray ? (%{$Inherited_Hash{$name}{$class}[CACHE] ||= []}) : 
                    ($Inherited_Hash{$name}{$class}[CACHE] ||= []);
    }

    my $cache = $Inherited_Hash{$name}{$class}[CACHE] ||= [];

    my @parents = ($class);

    while(my $parent = shift(@parents))
    {
      no strict 'refs';
      foreach my $superclass (@{$parent . '::ISA'})
      {
        push(@parents, $superclass);

        if($superclass->can($cache_method))
        {
          my $supercache = $superclass->$cache_method();

          while(my($attr, $state) = each %{$supercache->[META] || {}})
          {
            next  if($state == DELETED_VALUE);

            no warnings 'uninitialized';
            unless(exists $cache->[ATTRS]{$attr})
            {
              $cache->[ATTRS]{$attr} = $supercache->[ATTRS]{$attr};
              $cache->[META]{$attr} = INHERITED_VALUE;
            }
          }
        }
        # Slower method for superclasses that don't want to implement the
        # cache method (which is not strictly part of the public API)
        elsif($superclass->can($keys_method))
        {
          foreach my $attr ($superclass->$keys_method())
          {
            unless(exists $Inherited_Hash{$name}{$class}[CACHE][ATTRS]{$attr})
            {
              $Inherited_Hash{$name}{$class}[CACHE][META]{$attr} = INHERITED_VALUE;
              $Inherited_Hash{$name}{$class}[CACHE][ATTRS]{$attr} = 
                $Inherited_Hash{$name}{$superclass}[CACHE][ATTRS]{$attr};
            }
          }
        }
      } 
    }

    $Inherited_Hash{$name}{$class}[META]{'cache_is_valid'} = 1;  

    my $want = wantarray;

    return  unless(defined $want);
    $want ? (%{$Inherited_Hash{$name}{$class}[CACHE] ||= []}) : 
            ($Inherited_Hash{$name}{$class}[CACHE] ||= []);
  };

  $methods{$get_set_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    return 0  unless(defined $_[0]);

    my $key = shift;

    if(@_)
    {
      Carp::croak "More than one value passed to $get_set_method()"  if(@_ > 1);
      $class->$adds_method($key, @_);
    }
    else
    {
      if($Inherited_Hash{$name}{$class}[META]{'cache_is_valid'})
      {
        my $cache = $Inherited_Hash{$name}{$class}[CACHE] ||= [];

        no warnings 'uninitialized';
        return $cache->[ATTRS]{$key}  unless($cache->[META]{$key} == DELETED_VALUE);
        return undef;
      }

      my $cache = $class->$cache_method();

      no warnings 'uninitialized';
      return $cache->[ATTRS]{$key}  unless($cache->[META]{$key} == DELETED_VALUE);
      return undef;
    }
  };

  $methods{$keys_method} = sub
  {
    my($class) = shift;
    $class = ref $class  if(ref $class);
    return wantarray ? keys %{$class->$get_set_all_method()} : 
                       [ keys %{$class->$get_set_all_method()} ];
  };

  $methods{$get_set_all_method} = sub
  {
    my($class) = shift;

    $class = ref $class  if(ref $class);

    if(@_)
    {      
      $class->$clear_method();
      return $class->$adds_method(@_);
    }

    my $cache = $class->$cache_method();
    my %hash  = %{$cache->[ATTRS] || {}};

    foreach my $k (keys %hash)
    {
      delete $hash{$k}  if($Inherited_Hash{$name}{$class}[CACHE][META]{$k} == DELETED_VALUE);
    }

    return wantarray ? %hash : \%hash;
  };

  $methods{$exists_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;

    my $key = shift;

    return 0  unless(defined $key);

    if($Inherited_Hash{$name}{$class}[META]{'cache_is_valid'})
    {
      my $cache = $Inherited_Hash{$name}{$class}[CACHE] ||= [];
      return (exists $cache->[ATTRS]{$key} && $cache->[META]{$key} != DELETED_VALUE) ? 1 : 0;
    }

    my $cache = $class->$cache_method();

    return (exists $cache->[ATTRS]{$key} && $cache->[META]{$key} != DELETED_VALUE) ? 1 : 0;
  };

  $methods{$add_method} = sub { shift->$adds_method(@_) };

  $methods{$adds_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing name/value pair(s) to add")  unless(@_);

    my @attrs;
    my $count = 0;

    my $cache = $Inherited_Hash{$name}{$class}[CACHE] ||= [];

    # XXX: Lame duplication to avoid copying the hash
    if(@_ == 1 && ref $_[0] eq 'HASH')
    {
      while(my($attr, $value) = each(%{$_[0]}))
      {  
        next  unless(defined $attr);

        push(@attrs, $attr);

        $cache->[ATTRS]{$attr} = $value;
        $cache->[META]{$attr}  = CLASS_VALUE;

        if($add_implies)
        {
          foreach my $method (@$add_implies)
          {
            $class->$method($attr => $value);
          }
        }

        $count++;
      }
    }
    else
    {
      Carp::croak("Odd number of arguments passed to $adds_method")  if(@_ % 2);

      while(@_)
      {
        my($attr, $value) = (shift, shift);

        push(@attrs, $attr);

        no strict 'refs';
        next  unless(defined $attr);
        $cache->[ATTRS]{$attr} = $value;
        $cache->[META]{$attr}  = CLASS_VALUE;

        if($add_implies)
        {
          foreach my $method (@$add_implies)
          {
            $class->$method($attr => $value);
          }
        }

        $count++;
      }
    }

    if($count)
    {
      foreach my $test_class (keys %{$Inherited_Hash{$name}})
      {
        if($test_class->isa($class) && $test_class ne $class)
        {
          $Inherited_Hash{$name}{$test_class}[META]{'cache_is_valid'} = 0;

          foreach my $attr (@attrs)
          {
            delete $Inherited_Hash{$name}{$test_class}[CACHE][ATTRS]{$attr};
          }
        }
      }
    }

    return $count;
  };

  $methods{$clear_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    my @keys = $class->$keys_method();
    return  unless(@keys);
    $class->$deletes_method(@keys);
  };

  $methods{$delete_method} = sub { shift->$deletes_method(@_) };

  $methods{$deletes_method} = sub 
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing value(s) to delete")  unless(@_);

    # Init set if it doesn't exist
    unless(exists $Inherited_Hash{$name}{$class})
    {
      $class->$cache_method();
    }

    my $count = 0;

    my $cache = $Inherited_Hash{$name}{$class}[CACHE] ||= [];

    foreach my $attr (@_)
    {
      no strict 'refs';
      next  unless(defined $attr);

      if(exists $cache->[ATTRS]{$attr} && 
                $cache->[META]{$attr} != DELETED_VALUE)
      {
        $cache->[META]{$attr} = DELETED_VALUE;
        $count++;

        if($delete_implies)
        {
          foreach my $method (@$delete_implies)
          {
            $class->$method($attr);
          }
        }

        foreach my $test_class (keys %{$Inherited_Hash{$name}})
        {
          next  if($class eq $test_class);

          my $test_cache = $Inherited_Hash{$name}{$test_class}[CACHE] ||= [];

          if($test_class->isa($class) && exists $test_cache->[ATTRS]{$attr} &&
             $test_cache->[META]{$attr} == INHERITED_VALUE)
          {
            delete $test_cache->[ATTRS]{$attr};
            delete $test_cache->[META]{$attr};
            $Inherited_Hash{$name}{$test_class}[META]{'cache_is_valid'} = 0;
          }
        }
      }
    }

    return $count;
  };

  $methods{$inherit_method} = sub { shift->$inherits_method(@_) };

  $methods{$inherits_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing value(s) to inherit")  unless(@_);

    my $count = 0;

    my $cache = $Inherited_Hash{$name}{$class}[CACHE] ||= [];

    foreach my $attr (@_)
    {
      if(exists $cache->[ATTRS]{$attr})
      {
        delete $cache->[ATTRS]{$attr};
        delete $cache->[META]{$attr};
        $Inherited_Hash{$name}{$class}[META]{'cache_is_valid'} = 0;
        $count++;
      }

      if($inherit_implies)
      {
        foreach my $method (@$inherit_implies)
        {
          $class->$method($attr);
        }
      }
    }

    return $count;
  };

  if($interface ne 'all')
  {
    Carp::croak "Unknown interface: $interface";
  }

  return \%methods;
}


1;

__END__

=head1 NAME

Rose::Class::MakeMethods::Generic - Create simple class methods.

=head1 SYNOPSIS

  package MyClass;

  use Rose::Class::MakeMethods::Generic
  (
    scalar => 
    [
      'error',
      'type' => { interface => 'get_set_init' },
    ],

    inheritable_scalar => 'name',
  );

  sub init_type { 'special' }
  ...

  package MySubClass;
  our @ISA = qw(MyClass);
  ...

  MyClass->error(123);

  print MyClass->type; # 'special'

  MyClass->name('Fred');
  print MySubClass->name; # 'Fred'

  MyClass->name('Wilma');
  print MySubClass->name; # 'Wilma'

  MySubClass->name('Bam');
  print MyClass->name;    # 'Wilma'
  print MySubClass->name; # 'Bam'

=head1 DESCRIPTION

L<Rose::Class::MakeMethods::Generic> is a method maker that inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.  All methods work only with classes, not objects.

=head1 METHODS TYPES

=over 4

=item B<scalar>

Create get/set methods for scalar class attributes.

=over 4

=item Options

=over 4

=item C<init_method>

The name of the class method to call when initializing the value of an undefined attribute.  This option is only applicable when using the C<get_set_init> interface.  Defaults to the method name with the prefix C<init_> added.

=item C<interface>

Choose one of the two possible interfaces.  Defaults to C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a simple get/set accessor method for a class attribute.  When called with an argument, the value of the attribute is set.  The current value of the attribute is returned.

=item C<get_set_init>

Behaves like the C<get_set> interface unless the value of the attribute is undefined.  In that case, the class method specified by the C<init_method> option is called and the attribute is set to the return value of that method.

=back

=back

Example:

    package MyClass;

    use Rose::Class::MakeMethods::Generic
    (
      scalar => 'power',
      'scalar --get_set_init' => 'name',
    );

    sub init_name { 'Fred' }
    ...

    MyClass->power(99);    # returns 99
    MyClass->name;         # returns "Fred"
    MyClass->name('Bill'); # returns "Bill"

=item B<inheritable_boolean>

Create get/set methods for boolean class attributes that are inherited by subclasses until/unless their values are changed.

=over 4

=item Options

=over 4

=item C<interface>

Choose the interface.  This is kind of pointless since there is only one interface right now.  Defaults to C<get_set>, obviously.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set accessor method for a class attribute.  When called with an argument, the value of the attribute is set to 1 if that argument is true or 0 if it is false.  The value of the attribute is then returned.

If called with no arguments, and if the attribute was never set for this class, then a left-most, breadth-first search of the parent classes is initiated.  The value returned is taken from first parent class encountered that has ever had this attribute set.

=back

=back

Example:

    package MyClass;

    use Rose::Class::MakeMethods::Generic
    (
      inheritable_boolean => 'enabled',
    );
    ...

    package MySubClass;
    our @ISA = qw(MyClass);
    ...

    package MySubSubClass;
    our @ISA = qw(MySubClass);
    ...

    $x = MyClass->enabled;       # undef
    $y = MySubClass->enabled;    # undef
    $z = MySubSubClass->enabled; # undef

    MyClass->enabled(1);
    $x = MyClass->enabled;       # 1
    $y = MySubClass->enabled;    # 1
    $z = MySubSubClass->enabled; # 1

    MyClass->enabled(0);
    $x = MyClass->enabled;       # 0
    $y = MySubClass->enabled;    # 0
    $z = MySubSubClass->enabled; # 0

    MySubClass->enabled(1);
    $x = MyClass->enabled;       # 0
    $y = MySubClass->enabled;    # 1
    $z = MySubSubClass->enabled; # 1

    MyClass->enabled(1);
    MySubClass->enabled(undef);
    $x = MyClass->enabled;       # 1
    $y = MySubClass->enabled;    # 0
    $z = MySubSubClass->enabled; # 0

    MySubSubClass->enabled(1);
    $x = MyClass->enabled;       # 1
    $y = MySubClass->enabled;    # 0
    $z = MySubSubClass->enabled; # 0

=item B<inheritable_scalar>

Create get/set methods for scalar class attributes that are inherited by subclasses until/unless their values are changed.

=over 4

=item Options

=over 4

=item C<interface>

Choose the interface.  This is kind of pointless since there is only one interface right now.  Defaults to C<get_set>, obviously.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a get/set accessor method for a class attribute.  When called with an argument, the value of the attribute is set and then returned.

If called with no arguments, and if the attribute was never set for this class, then a left-most, breadth-first search of the parent classes is initiated.  The value returned is taken from first parent class encountered that has ever had this attribute set.

=back

=back

Example:

    package MyClass;

    use Rose::Class::MakeMethods::Generic
    (
      inheritable_scalar => 'name',
    );
    ...

    package MySubClass;
    our @ISA = qw(MyClass);
    ...

    package MySubSubClass;
    our @ISA = qw(MySubClass);
    ...

    $x = MyClass->name;       # undef
    $y = MySubClass->name;    # undef
    $z = MySubSubClass->name; # undef

    MyClass->name('Fred');
    $x = MyClass->name;       # 'Fred'
    $y = MySubClass->name;    # 'Fred'
    $z = MySubSubClass->name; # 'Fred'

    MyClass->name('Wilma');
    $x = MyClass->name;       # 'Wilma'
    $y = MySubClass->name;    # 'Wilma'
    $z = MySubSubClass->name; # 'Wilma'

    MySubClass->name('Bam');
    $x = MyClass->name;       # 'Wilma'
    $y = MySubClass->name;    # 'Bam'
    $z = MySubSubClass->name; # 'Bam'

    MyClass->name('Koop');
    MySubClass->name(undef);
    $x = MyClass->name;       # 'Koop'
    $y = MySubClass->name;    # undef
    $z = MySubSubClass->name; # undef

    MySubSubClass->name('Sam');
    $x = MyClass->name;       # 'Koop'
    $y = MySubClass->name;    # undef
    $z = MySubSubClass->name; # 'Sam'

=item B<hash>

Create methods to manipulate a hash of class attributes.

=over 4

=item Options

=over 4

=item C<hash_key>

The key to use for the storage of this attribute.  Defaults to the name of the method.

=item C<interface>

Choose which interface to use.  Defaults to C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

If called with no arguments, returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

If called with one argument, and that argument is a reference to a hash, that hash reference is used as the new value for the attribute.  Returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

If called with one argument, and that argument is a reference to an array, then a list of the hash values for each key in the array is returned.

If called with one argument, and it is not a reference to a hash or an array, then the hash value for that key is returned.

If called with an even number of arguments, they are taken as name/value pairs and are added to the hash.  It then returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

Passing an odd number of arguments greater than 1 causes a fatal error.

=item C<get_set_all>

If called with no arguments, returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

If called with one argument, and that argument is a reference to a hash, that hash reference is used as the new value for the attribute.  Returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

Otherwise, the hash is emptied and the arguments are taken as name/value pairs that are then added to the hash.  It then returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

=item C<clear>

Sets the attribute to an empty hash.

=item C<reset>

Sets the attribute to undef.

=item C<delete>

Deletes the key(s) passed as arguments.  Failure to pass any arguments causes a fatal error.

=item C<exists>

Returns true of the argument exists in the hash, false otherwise. Failure to pass an argument or passing more than one argument causes a fatal error.

=item C<keys>

Returns the keys of the hash in list context, or a reference to an array of the keys of the hash in scalar context.  The keys are not sorted.

=item C<names>

An alias for the C<keys> interface.

=item C<values>

Returns the values of the hash in list context, or a reference to an array of the values of the hash in scalar context.  The values are not sorted.

=back

=back

Example:

    package MyClass;

    use Rose::Class::MakeMethods::Generic
    (
      hash =>
      [
        param        => { hash_key =>'params' },
        params       => { interface=>'get_set_all' },
        param_names  => { interface=>'keys',   hash_key=>'params' },
        param_values => { interface=>'values', hash_key=>'params' },
        param_exists => { interface=>'exists', hash_key=>'params' },
        delete_param => { interface=>'delete', hash_key=>'params' },

        clear_params => { interface=>'clear', hash_key=>'params' },
        reset_params => { interface=>'reset', hash_key=>'params' },
      ],
    );
    ...

    MyClass->params; # undef

    MyClass->params(a => 1, b => 2); # add pairs
    $val = MyClass->param('b'); # 2

    %params = MyClass->params; # copy hash keys and values
    $params = MyClass->params; # get hash ref

    MyClass->params({ c => 3, d => 4 }); # replace contents

    MyClass->param_exists('a'); # false

    $keys = join(',', sort MyClass->param_names);  # 'c,d'
    $vals = join(',', sort MyClass->param_values); # '3,4'

    MyClass->delete_param('c');
    MyClass->param(f => 7, g => 8);

    $vals = join(',', sort MyClass->param_values); # '4,7,8'

    MyClass->clear_params;
    $params = MyClass->params; # empty hash

    MyClass->reset_params;
    $params = MyClass->params; # undef

=item B<inheritable_hash>

Create methods to manipulate a hash of class attributes that can be inherited by subclasses.

The hash of attributes is inherited by subclasses using a one-time copy.  Any subclass that accesses or manipulates the hash in any way will immediately get its own private copy of the hash I<as it exists in the superclass at the time of the access or manipulation>.  

The superclass from which the hash is copied is the closest ("least super") class that has ever accessed or manipulated this hash.  The copy is a "shallow" copy, duplicating only the keys and values.  Reference values are not recursively copied.

Setting to hash to undef (using the 'reset' interface) will cause it to be re-copied from a superclass the next time it is accessed.

=over 4

=item Options

=over 4

=item C<hash_key>

The key to use for the storage of this attribute.  Defaults to the name of the method.

=item C<interface>

Choose which interface to use.  Defaults to C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

If called with no arguments, returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

If called with one argument, and that argument is a reference to a hash, that hash reference is used as the new value for the attribute.  Returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

If called with one argument, and that argument is a reference to an array, then a list of the hash values for each key in the array is returned.

If called with one argument, and it is not a reference to a hash or an array, then the hash value for that key is returned.

If called with an even number of arguments, they are taken as name/value pairs and are added to the hash.  It then returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

Passing an odd number of arguments greater than 1 causes a fatal error.

=item C<get_set_all>

If called with no arguments, returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

If called with one argument, and that argument is a reference to a hash, that hash reference is used as the new value for the attribute.  Returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

Otherwise, the hash is emptied and the arguments are taken as name/value pairs that are then added to the hash.  It then returns a list of key/value pairs in list context or a reference to the actual hash used to store values in scalar context.

=item C<clear>

Sets the attribute to an empty hash.

=item C<reset>

Sets the attribute to undef.

=item C<delete>

Deletes the key(s) passed as arguments.  Failure to pass any arguments causes a fatal error.

=item C<exists>

Returns true of the argument exists in the hash, false otherwise. Failure to pass an argument or passing more than one argument causes a fatal error.

=item C<keys>

Returns the keys of the hash in list context, or a reference to an array of the keys of the hash in scalar context.  The keys are not sorted.

=item C<names>

An alias for the C<keys> interface.

=item C<values>

Returns the values of the hash in list context, or a reference to an array of the values of the hash in scalar context.  The values are not sorted.

=back

=back

Example:

    package MyClass;

    use Rose::Class::MakeMethods::Generic
    (
      inheritable_hash =>
      [
        param        => { hash_key =>'params' },
        params       => { interface=>'get_set_all' },
        param_names  => { interface=>'keys',   hash_key=>'params' },
        param_values => { interface=>'values', hash_key=>'params' },
        param_exists => { interface=>'exists', hash_key=>'params' },
        delete_param => { interface=>'delete', hash_key=>'params' },

        clear_params => { interface=>'clear', hash_key=>'params' },
        reset_params => { interface=>'reset', hash_key=>'params' },
      ],
    );
    ...

    package MySubClass;
    our @ISA = qw(MyClass);
    ...

    MyClass->params; # undef

    MyClass->params(a => 1, b => 2); # add pairs
    $val = MyClass->param('b'); # 2

    %params = MyClass->params; # copy hash keys and values
    $params = MyClass->params; # get hash ref

    # Inherit a copy of params from MyClass
    $params = MySubClass->params; # { a => 1, b => 2 }

    MyClass->params({ c => 3, d => 4 }); # replace contents

    # MySubClass params are still as the existed at the time
    # they were originally copied from MyClass
    $params = MySubClass->params; # { a => 1, b => 2 }

    # MySubClass can manipulate its own params as it wishes
    MySubClass->param(z => 9);

    $params = MySubClass->params; # { a => 1, b => 2, z => 9 }

    MyClass->param_exists('a'); # false

    $keys = join(',', sort MyClass->param_names);  # 'c,d'
    $vals = join(',', sort MyClass->param_values); # '3,4'

    # Reset params (set to undef) so that they will be re-copied
    # from MyClass the next time they're accessed
    MySubClass->reset_params;

    MyClass->delete_param('c');
    MyClass->param(f => 7, g => 8);

    $vals = join(',', sort MyClass->param_values); # '4,7,8'

    # Inherit a copy of params from MyClass
    $params = MySubClass->params; # { d => 4, f => 7, g => 8 }

=item B<inherited_hash>

Create a family of class methods for managing an inherited hash.

An inherited hash is made up of the union of the hashes of all superclasses, minus any keys that are explicitly deleted in the current class.

=over 4

=item Options

=over 4

=item C<add_implies>

A method name, or reference to a list of method names, to call when a key is added to the hash.  Each added name/value pair is passed to each method in the C<add_implies> list, one pair at a time.

=item C<add_method>

The name of the class method used to add a single name/value pair to the hash. Defaults to the method name with the prefix C<add_> added.

=item C<adds_method>

The name of the class method used to add one or more name/value pairs to the hash.  Defaults to C<plural_name> with the prefix C<add_> added.

=item C<cache_method>

The name of the class method used to retrieve (or generate, if it doesn't exist) the internal cache for the hash.  This should be considered a private method, but it is listed here because it does take up a spot in the method namespace.  Defaults to C<plural_name> with C<_cache> added to the end.

=item C<clear_method>

The name of the class method used to clear the contents of the hash.  Defaults to C<plural_name> with a C<clear_> prefix added.

=item C<delete_implies>

A method name, or reference to a list of method names, to call when a key is removed from the hash.  Each deleted key is passed as an argument to each method in the C<delete_implies> list, one key per call.

=item C<delete_method>

The name of the class method used to remove a single key from the hash.  Defaults to the method name with the prefix C<delete_> added.

=item C<deletes_method>

The name of the class method used to remove one or more keys from the hash.  Defaults to C<plural_name> with a C<delete_> prefix added.

=item C<exists_method>

The name of the class method that tests for the existence of a key in the hash.  Defaults to the method name with the suffix C<_exists> added.

=item C<get_set_all_method>

The name of the class method use to set or fetch the entire hash.  The hash may be passed as a reference to a hash or as a list of name/value pairs.  Returns the hash (in list context) or a reference to a hash (in scalar context).  Defaults to C<plural_name>.

=item C<hash_method>

This is an alias for the C<get_set_all_method> parameter.

=item C<inherit_method>

The name of the class method used to indicate that an inherited key that was previously deleted from the hash should return to being inherited.  Defaults to the method name with the prefix C<inherit_> added.

=item C<inherits_method>

The name of the class method used to indicate that one or more inherited keys that were previously deleted from the hash should return to being inherited.  Defaults to the C<plural_name> with the prefix C<inherit_> added.

=item C<interface>

Choose the interface.  This is kind of pointless since there is only one interface right now.  Defaults to C<all>, obviously.

=item C<keys_method>

The name of the class method that returns a reference to a list of keys in scalar context, or a list of keys in list context.   Defaults to C<plural_name> with "_keys" added to the end.

=item C<plural_name>

The plural version of the method name, used to construct the default names for some other methods.  Defaults to the method name with C<s> added.

=back

=item Interfaces

=over 4

=item C<all>

Creates the entire family of methods described above.  The example
below illustrates their use.

=back

=back

Example:

    package MyClass;

    use Rose::Class::MakeMethods::Generic
    (
      inherited_hash =>
      [
        pet_color =>
        {
          keys_method     => 'pets',
          delete_implies  => 'delete_special_pet_color',
          inherit_implies => 'inherit_special_pet_color',
        },

        special_pet_color =>
        {
          keys_method     => 'special_pets',
          add_implies => 'add_pet_color',
        },
      ],
    );
    ...

    package MySubClass;
    our @ISA = qw(MyClass);
    ...


    MyClass->pet_colors(Fido => 'white',
                        Max  => 'black',
                        Spot => 'yellow');

    MyClass->special_pet_color(Toby => 'tan');

    MyClass->pets;              # Fido, Max, Spot, Toby
    MyClass->special_pets;      # Toby

    MySubClass->pets;           # Fido, Max, Spot, Toby
    MyClass->pet_color('Toby'); # tan

    MySubClass->special_pet_color(Toby => 'gold');

    MyClass->pet_color('Toby');         # tan
    MyClass->special_pet_color('Toby'); # tan

    MySubClass->pet_color('Toby');         # gold
    MySubClass->special_pet_color('Toby'); # gold

    MySubClass->inherit_pet_color('Toby');

    MySubClass->pet_color('Toby');         # tan
    MySubClass->special_pet_color('Toby'); # tan

    MyClass->delete_pet_color('Max');

    MyClass->pets;    # Fido, Spot, Toby
    MySubClass->pets; # Fido, Spot, Toby

    MyClass->special_pet_color(Max => 'mauve');

    MyClass->pets;    # Fido, Max, Spot, Toby
    MySubClass->pets; # Fido, Max, Spot, Toby

    MyClass->special_pets;    # Max, Toby
    MySubClass->special_pets; # Max, Toby

    MySubClass->delete_special_pet_color('Max');

    MyClass->pets;    # Fido, Max, Spot, Toby
    MySubClass->pets; # Fido, Max, Spot, Toby

    MyClass->special_pets;    # Max, Toby
    MySubClass->special_pets; # Toby

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
