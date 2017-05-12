package Rose::Class::MakeMethods::Set;

use strict;

use Carp();

our $VERSION = '0.81';

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

our %Inheritable_Set;
# (
#   some_attr_name =>
#   {
#     class1 => 
#     {
#       meta  => { ... },
#       cache => { ... },
#     },
#     class2 => ...,
#     ...
#   },
#   ...
# );

sub inheritable_set
{
  my($class, $name, $args) = @_;

  my %methods;

  # Interface example:
  # name:            required_html_attr
  # plural_name:     required_html_attrs
  # list_method:     required_html_attrs
  # hash_method:     required_html_attrs_hash
  # test_method:     is_required_html_attr (or html_attr_is_required)
  # add_method:      add_required_html_attr
  # adds_method:     add_required_html_attrs
  # delete_method:   delete_required_html_attr
  # deletes_method:  delete_required_html_attrs
  # clear_method:    clear_required_html_attrs

  my $plural_name = $args->{'plural_name'} || $name . 's';

  my $list_method     = $args->{'list_method'}    || $plural_name;
  my $hash_method     = $args->{'hash_method'}    || $plural_name  . '_hash';
  my $test_method     = $args->{'test_method'}    || $args->{'test_method'} || 'is_' . $name;
  my $add_method      = $args->{'add_method'}     || 'add_' . $name;
  my $adds_method     = $args->{'adds_method'}    || $add_method . 's';
  my $delete_method   = $args->{'delete_method'}  || 'delete_' . $name;
  my $deletes_method  = $args->{'deletes_method'} || 'delete_' . $plural_name;
  my $clear_method    = $args->{'clear_method'}   || 'clear_' . $plural_name;
  my $value_method    = $args->{'value_method'}   || $name . '_value';

  my $interface      = $args->{'interface'} || 'all';
  my $add_implies    = $args->{'add_implies'};
  my $delete_implies = $args->{'delete_implies'};

  $add_implies = [ $add_implies ]
    if(defined $add_implies && !ref $add_implies);

  $delete_implies = [ $delete_implies ]
    if(defined $delete_implies && !ref $delete_implies);

  $methods{$test_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;

    return 0  unless(defined $_[0]);

    no strict 'refs';
    return 1  if(exists $class->$hash_method()->{$_[0]});
    return 0;
  };

  $methods{$hash_method} = sub
  {
    my($class) = ref($_[0]) || $_[0];

    unless(exists $Inheritable_Set{$name}{$class})
    {
      no strict 'refs';

      my @parents = ($class);

      while(my $parent = shift(@parents))
      {
        no strict 'refs';
        foreach my $subclass (@{$parent . '::ISA'})
        {
          push(@parents, $subclass);

          if(exists $Inheritable_Set{$name}{$subclass})
          {
            while(my($k, $v) = each(%{$Inheritable_Set{$name}{$subclass}}))
            {
              next  if(exists $Inheritable_Set{$name}{$class}{$k});
              $Inheritable_Set{$name}{$class}{$k} = $v;
            }
          }
        } 
      }
    }

    $Inheritable_Set{$name}{$class} ||= {};
    return wantarray ? %{$Inheritable_Set{$name}{$class}} : 
                       $Inheritable_Set{$name}{$class};
  };

  $methods{$list_method} = sub
  {
    my($class) = shift;

    $class = ref $class  if(ref $class);

    if(@_)
    {      
      $class->$clear_method();
      $class->$adds_method(@_);
      return  unless(defined wantarray);
    }

    return wantarray ? sort keys %{$class->$hash_method()} : 
                       [ sort keys %{$class->$hash_method()} ];
  };

  $methods{$add_method} = sub { shift->$adds_method(@_) };

  $methods{$adds_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing value(s) to add")  unless(@_);

    my $count = 0;
    my $req_hash = $class->$hash_method();

    return 0  unless(defined $_[0]);

    my %attrs;

    foreach my $arg (grep { defined } @_)
    {
      if(ref $arg eq 'HASH')
      {
        $attrs{$_} = $arg->{$_}  for(keys %$arg);
      }
      else
      {
        $attrs{$arg} = undef;
      }
    }

    while(my($attr, $val) = each(%attrs))
    {
      no strict 'refs';
      next  unless(defined $attr);
      $req_hash->{$attr} = $val;

      if($add_implies)
      {
        foreach my $method (@$add_implies)
        {
          $class->$method($attr);
        }
      }

      $count++;
    }

    return $count;
  };

  $methods{$clear_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    my @values = $class->$list_method();
    return  unless(@values);
    $class->$deletes_method(@values);
  };

  $methods{$delete_method} = sub { shift->$deletes_method(@_) };

  $methods{$deletes_method} = sub 
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing value(s) to delete")  unless(@_);

    my $count = 0;
    my $req_hash = $class->$hash_method();

    foreach my $attr (@_)
    {
      no strict 'refs';
      next  unless(defined $attr);
      next  unless(exists $req_hash->{$attr});
      delete $req_hash->{$attr};
      $count++;

      if($delete_implies)
      {
        foreach my $method (@$delete_implies)
        {
          $class->$method($attr);
        }
      }
    }

    return $count;
  };  

  $methods{$value_method} = sub
  {
    my($class) = ref($_[0]) || $_[0];

    my $hash = $class->$hash_method();
    return undef  unless($_[1] && exists $hash->{$_[1]});
    return $hash->{$_[1]} = $_[2]  if(@_ > 2);
    return $hash->{$_[1]};
  };

  if($interface ne 'all')
  {
    Carp::croak "Unknown interface: $interface";
  }

  return \%methods;
}

use constant CLASS_VALUE     => 1;
use constant INHERITED_VALUE => 2;
use constant DELETED_VALUE   => 3;

our %Inherited_Set;
# (
#   some_attr_name =>
#   {
#     class1 => 
#     {
#       meta  => { ... },
#       cache => { ... },
#     },
#     class2 => ...,
#     ...
#   },
#   ...
# );

sub inherited_set
{
  my($class, $name, $args) = @_;

  my %methods;

  # Interface example:
  # name:            valid_html_attr
  # plural_name:     valid_html_attrs
  # list_method:     valid_html_attrs
  # cache_method:    valid_html_attrs_cache
  # hash_method:     valid_html_attrs_hash
  # test_method:     is_valid_html_attr (or html_attr_is_valid)
  # add_method:      add_valid_html_attr
  # adds_method:     add_valid_html_attrs
  # delete_method:   delete_valid_html_attr
  # deletes_method:  delete_valid_html_attrs
  # clear_method     clear_valid_html_attrs
  # inherit_method:  inherit_valid_html_attr
  # inherits_method: inherit_valid_html_attrs

  my $plural_name = $args->{'plural_name'} || $name . 's';

  my $list_method     = $args->{'list_method'}     || $plural_name;
  my $cache_method    = $args->{'cache_method'}    || $plural_name . '_cache';
  my $hash_method     = $args->{'hash_method'}     || $plural_name  . '_hash';
  my $test_method     = $args->{'test_method'}     || $args->{'test_method'} || 'is_' . $name;
  my $add_method      = $args->{'add_method'}      || 'add_' . $name;
  my $adds_method     = $args->{'adds_method'}     || $add_method . 's';
  my $delete_method   = $args->{'delete_method'}   || 'delete_' . $name;
  my $deletes_method  = $args->{'deletes_method'}  || 'delete_' . $plural_name;
  my $clear_method    = $args->{'clear_method'}    || 'clear_' . $plural_name;
  my $inherit_method  = $args->{'inherit_method'}  || 'inherit_' . $name;
  my $inherits_method = $args->{'inherits_method'} || $inherit_method . 's';

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

    if($Inherited_Set{$name}{$class}{'meta'}{'cache_is_valid'})
    {
      return   
        wantarray ? (%{$Inherited_Set{$name}{$class}{'cache'} ||= {}}) : 
                    ($Inherited_Set{$name}{$class}{'cache'} ||= {});
    }

    my @parents = ($class);

    while(my $parent = shift(@parents))
    {
      no strict 'refs';
      foreach my $subclass (@{$parent . '::ISA'})
      {
        push(@parents, $subclass);

        if($subclass->can($cache_method))
        {
          my $cache = $subclass->$cache_method();

          while(my($attr, $val) = each %$cache)
          {
            next  if($val == DELETED_VALUE);
            $Inherited_Set{$name}{$class}{'cache'}{$attr} = INHERITED_VALUE
              unless(exists $Inherited_Set{$name}{$class}{'cache'}{$attr});        
          }
        }
        # Slower method for subclasses that don't want to implement the
        # cache method (which is not strictly part of the public API)
        elsif($subclass->can($list_method))
        {
          foreach my $attr ($subclass->$list_method())
          {
            $Inherited_Set{$name}{$class}{'cache'}{$attr} = INHERITED_VALUE
              unless(exists $Inherited_Set{$name}{$class}{'cache'}{$attr});
          }
        }
      } 
    }

    $Inherited_Set{$name}{$class}{'meta'}{'cache_is_valid'} = 1;  

    my $want = wantarray;

    return  unless(defined $want);
    $want ? (%{$Inherited_Set{$name}{$class}{'cache'} ||= {}}) : 
            ($Inherited_Set{$name}{$class}{'cache'} ||= {});
  };

  $methods{$hash_method} = sub
  {
    my($class) = ref($_[0]) || $_[0];

    my %hash = $class->$cache_method();

    while(my($k, $v) = each %hash)
    {
      delete $hash{$k}  if($v == DELETED_VALUE);
    }

    return wantarray ? %hash : \%hash;
  };

  $methods{$list_method} = sub
  {
    my($class) = shift;

    $class = ref $class  if(ref $class);

    if(@_)
    {      
      $class->$clear_method();
      $class->$adds_method(@_);
      return  unless(defined wantarray);
    }

    return wantarray ? sort keys %{$class->$hash_method()} : 
                       [ sort keys %{$class->$hash_method()} ];
  };

  $methods{$test_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    return 0  unless(defined $_[0]);

    if($Inherited_Set{$name}{$class}{'meta'}{'cache_is_valid'})
    {
      return (exists $Inherited_Set{$name}{$class}{'cache'}{$_[0]} &&
                     $Inherited_Set{$name}{$class}{'cache'}{$_[0]} != DELETED_VALUE) ? 1 : 0;
    }

    my $cache = $class->$cache_method();

    return (exists $cache->{$_[0]} && $cache->{$_[0]} != DELETED_VALUE) ? 1 : 0;
  };

  $methods{$add_method} = sub { shift->$adds_method(@_) };

  $methods{$adds_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing value(s) to add")  unless(@_);

    my $count = 0;

    foreach my $attr (@_)
    {
      no strict 'refs';
      next  unless(defined $attr);
      $Inherited_Set{$name}{$class}{'cache'}{$attr} = CLASS_VALUE;

      if($add_implies)
      {
        foreach my $method (@$add_implies)
        {
          $class->$method($attr);
        }
      }

      $count++;
    }

    # _invalidate_inherited_set_caches($class, $name)  if($count);
    # Inlined since it is private and only called once
    if($count)
    {
      foreach my $test_class (keys %{$Inherited_Set{$name}})
      {
        if($test_class->isa($class) && $test_class ne $class)
        {
          $Inherited_Set{$name}{$test_class}{'meta'}{'cache_is_valid'} = 0;
        }
      }
    }

    return $count;
  };

  $methods{$clear_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    my @values = $class->$list_method();
    return  unless(@values);
    $class->$deletes_method(@values);
  };

  $methods{$delete_method} = sub { shift->$deletes_method(@_) };

  $methods{$deletes_method} = sub 
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing value(s) to delete")  unless(@_);

    # Init set if it doesn't exist
    unless(exists $Inherited_Set{$name}{$class})
    {
      $class->$cache_method();
    }

    my $count = 0;

    foreach my $attr (@_)
    {
      no strict 'refs';
      next  unless(defined $attr);

      if(exists $Inherited_Set{$name}{$class}{'cache'}{$attr} && 
                $Inherited_Set{$name}{$class}{'cache'}{$attr} != DELETED_VALUE)
      {
        $Inherited_Set{$name}{$class}{'cache'}{$attr} = DELETED_VALUE;
        $count++;

        if($delete_implies)
        {
          foreach my $method (@$delete_implies)
          {
            $class->$method($attr);
          }
        }

        foreach my $test_class (keys %{$Inherited_Set{$name}})
        {
          next  if($class eq $test_class);

          if($test_class->isa($class) && exists $Inherited_Set{$name}{$test_class}{'cache'}{$attr} &&
             $Inherited_Set{$name}{$test_class}{'cache'}{$attr} == INHERITED_VALUE)
          {
            delete $Inherited_Set{$name}{$test_class}{'cache'}{$attr};
            $Inherited_Set{$name}{$test_class}{'meta'}{'cache_is_valid'} = 0;
          }
        }
      }
    }

    # Not required
    #_invalidate_inherited_set_caches($class, $name)  if($count);

    return $count;
  };

  $methods{$inherit_method} = sub { shift->$inherits_method(@_) };

  $methods{$inherits_method} = sub
  {
    my($class) = ref($_[0]) ? ref(shift) : shift;
    Carp::croak("Missing value(s) to inherit")  unless(@_);

    my $count = 0;

    foreach my $attr (@_)
    {
      if(exists $Inherited_Set{$name}{$class}{'cache'}{$attr} &&
         $Inherited_Set{$name}{$class}{'cache'}{$attr} == DELETED_VALUE)
      {
        delete $Inherited_Set{$name}{$class}{'cache'}{$attr};
        $Inherited_Set{$name}{$class}{'meta'}{'cache_is_valid'} = 0;
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

# Inlined above since it is private and only called once
# sub _invalidate_inherited_set_caches
# {
#   my($class, $name) = @_;
# 
#   foreach my $test_class (keys %{$Inherited_Set{$name}})
#   {
#     if($test_class->isa($class) && $test_class ne $class)
#     {
#       $Inherited_Set{$name}{$test_class}{'meta'}{'cache_is_valid'} = 0;
#     }
#   }
# }

1;

__END__

=head1 NAME

Rose::Class::MakeMethods::Set - Create class methods to manage sets.

=head1 SYNOPSIS

  package MyClass;

  use Rose::Class::MakeMethods::Set
  (
    inheritable_set =>
    [
      required_name =>
      {
        add_implies => 'add_valid_name',
        test_method => 'name_is_required', 
      },
    ],

    inherited_set =>
    [
      valid_name =>
      {
        test_method => 'name_is_valid', 
      },
    ],
  );

  ...

  package MySubClass;
  our @ISA = qw(MyClass);
  ...

  MyClass->add_valid_names('A', 'B', 'C');
  MyClass->add_required_name('D');

  $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D';
  $r1 = join(',', MyClass->required_names);    # 'D'

  $v2 = join(',', MySubClass->valid_names);    # 'A,B,C,D';
  $r2 = join(',', MySubClass->required_names); # 'D'

  MySubClass->add_required_names('X', 'Y');

  $v2 = join(',', MySubClass->valid_names);    # 'A,B,C,D,X,Y';
  $r2 = join(',', MySubClass->required_names); # 'D,X,Y'

  MySubClass->delete_valid_names('B', 'X');

  $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D';
  $r1 = join(',', MyClass->required_names);    # 'D'

  $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
  $r2 = join(',', MySubClass->required_names); # 'D,X,Y'

  MySubClass->delete_required_name('D');

  $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D';
  $r1 = join(',', MyClass->required_names);    # 'D'

  $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
  $r2 = join(',', MySubClass->required_names); # 'X,Y'

=head1 DESCRIPTION

L<Rose::Class::MakeMethods::Set> is a method maker that inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.  All methods work only with classes, not objects.

=head1 METHODS TYPES

=over 4

=item B<inheritable_set>

Create a family of class methods for managing an inheritable set of items, each with an optional associated value.  Each item must be a string, or must stringify to a unique string value, since a hash is used internally to store the set.

The set is inherited by subclasses, but any subclass that accesses or manipulates the set in any way will immediately get its own private copy of the set I<as it exists in the superclass at the time of the access or manipulation>.  The superclass from which the set is copied is the closest ("least super") class that has ever accessed or manipulated this set.

These may sound like wacky rules, but it may help to know that this family of methods was created for use in the L<Rose::HTML::Objects> family of modules to manage the set of required HTML attributes (and their optional default values) for various HTML tags.

=over 4

=item Options

=over 4

=item C<add_implies>

A method name, or reference to a list of method names, to call when an item is added to the set.  Each added attribute is passed as an argument to each method in the C<add_implies> list.

=item C<add_method>

The name of the class method used to add a single item to the set. Defaults to the method name with the prefix C<add_> added.

=item C<adds_method>

The name of the class method used to add one or more items to the set. Defaults to C<add_method> with C<s> added to the end.

=item C<clear_method>

The name of the class method used to clear the contents of the set. Defaults to C<plural_name> with a C<clear_> prefix added.

=item C<delete_implies>

A method name, or reference to a list of method names, to call when an item is removed from the set.  Each deleted attribute is passed as an argument to each method in the C<delete_implies> list.

=item C<delete_method>

The name of the class method used to remove a single item from the set. Defaults to the method name with the prefix C<delete_> added.

=item C<deletes_method>

The name of the class method used to remove one or more items from the set. Defaults to C<plural_name> with a C<delete_> prefix added.

=item C<hash_method>

The name of the class method that returns a reference to the actual hash that contains the set of items in scalar context, and a shallow copy of the hash in list context.  Defaults to C<plural_name> with C<_hash> added to the end.

=item C<interface>

Choose the interface.  This is kind of pointless since there is only one interface right now.  Defaults to C<all>, obviously.

=item C<list_method>

The name of the class method that returns a reference to a sorted list of items in scalar context, or a sorted list in list context.  If called with any arguments, the set is cleared with a call to C<clear_method>, then the set is repopulated by passing all of the arguments to a call to C<adds_method>.  The method name defaults to C<plural_name>.

=item C<plural_name>

The plural name of the items, used to construct the default names for some other methods.  Defaults to the method name with C<s> added.

=item C<test_method>

The name of the class method that tests for the existence of an item in the set.  Defaults to the method name with the prefix C<is_> added.

=item C<value_method>

The name of the class method used to get and set the (optional) value associated with each item in the set.  Defaults to the method name with C<_value> added to the end.

=back

=item Interfaces

=over 4

=item C<all>

Creates the entire family of methods described above.  The example below illustrates their use.

=back

=back

Example:

    package MyClass;

    use Rose::Class::MakeMethods::Set
    (
      inheritable_set =>
      [
        valid_name =>
        {
          test_method    => 'name_is_valid', 
          delete_implies => 'delete_required_name',
        },

        required_name =>
        {
          add_implies => 'add_valid_name',
          test_method => 'name_is_required', 
        },
      ],
    );

    package MySubClass;
    our @ISA = qw(MyClass);
    ...

    MyClass->add_valid_names('A', 'B', 'C');
    MyClass->add_required_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D';
    $r1 = join(',', MyClass->required_names);    # 'D'

    $v2 = join(',', MySubClass->valid_names);    # 'A,B,C,D';
    $r2 = join(',', MySubClass->required_names); # 'D'

    MySubClass->add_required_names('X', 'Y');

    $v2 = join(',', MySubClass->valid_names);    # 'A,B,C,D,X,Y';
    $r2 = join(',', MySubClass->required_names); # 'D,X,Y'

    MySubClass->delete_valid_names('B', 'X');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D';
    $r1 = join(',', MyClass->required_names);    # 'D'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
    $r2 = join(',', MySubClass->required_names); # 'D,Y'

    MySubClass->delete_required_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D';
    $r1 = join(',', MyClass->required_names);    # 'D'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
    $r2 = join(',', MySubClass->required_names); # 'Y'

    MyClass->name_is_required('D');    # true
    MySubClass->name_is_required('D'); # false

    $h = MyClass->valid_names_hash;

    # Careful!  This is the actual hash used for set storage!
    # You should use delete_valid_name() instead!
    delete $h->{'C'}; 

    MySubClass->required_name_value(Y => 'xval');

    print MySubClass->required_name_value('Y'); # 'xval'

    %r = MySubClass->required_names_hash;

    print $r{'Y'}; # 'xval'

    # Okay: %r is a (shallow) copy, not the actual hash
    delete $r{'Y'};

=item B<inherited_set>

Create a family of class methods for managing an inherited set of items. Each item must be a string, or must stringify to a unique string value, since a hash is used internally to store the set.

An inherited set is made up of the union of the sets of all superclasses, minus any items that are explicitly deleted in the current class.

=over 4

=item Options

=over 4

=item C<add_implies>

A method name, or reference to a list of method names, to call when an item is added to the set.  Each added attribute is passed as an argument to each method in the C<add_implies> list.

=item C<add_method>

The name of the class method used to add a single item to the set. Defaults to the method name with the prefix C<add_> added.

=item C<adds_method>

The name of the class method used to add one or more items to the set. Defaults to C<add_method> with C<s> added to the end.

=item C<cache_method>

The name of the class method used to retrieve (or generate, if it doesn't exist) the internal cache for the set.  This should be considered a private method, but it is listed here because it does take up a spot in the method namespace.  Defaults to C<plural_name> with C<_cache> added to the end.

=item C<clear_method>

The name of the class method used to clear the contents of the set. Defaults to C<plural_name> with a C<clear_> prefix added.

=item C<delete_implies>

A method name, or reference to a list of method names, to call when an item is removed from the set.  Each deleted attribute is passed as an argument to each method in the C<delete_implies> list.

=item C<delete_method>

The name of the class method used to remove a single item from the set. Defaults to the method name with the prefix C<delete_> added.

=item C<deletes_method>

The name of the class method used to remove one or more items from the set. Defaults to C<plural_name> with a C<delete_> prefix added.

=item C<hash_method>

The name of the class method that returns a hash (in list context) or a reference to a hash (in scalar context) that contains the set of items. The existence of a key in the hash indicates its existence in the set. Defaults to C<plural_name> with C<_hash> added to the end.

=item C<inherit_method>

The name of the class method used to indicate that an inherited value that was previously deleted from the set should return to being inherited.  Defaults to the method name with the prefix C<inherit_> added.

=item C<inherits_method>

The name of the class method used to indicate that one or more inherited values that were previously deleted from the set should return to being inherited.  Defaults to the C<inherit_method> name with C<s> added to the end.

=item C<interface>

Choose the interface.  This is kind of pointless since there is only one interface right now.  Defaults to C<all>, obviously.

=item C<list_method>

The name of the class method that returns a reference to a sorted list of items in scalar context, or a sorted list in list context.  If called with any arguments, the set is cleared with a call to C<clear_method>, then the set is repopulated by passing all of the arguments to a call to C<adds_method>.  The method name defaults to C<plural_name>.

=item C<plural_name>

The plural name of the items, used to construct the default names for some other methods.  Defaults to the method name with C<s> added.

=item C<test_method>

The name of the class method that tests for the existence of an item in the set.  Defaults to the method name with the prefix C<is_> added.

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

    use Rose::Class::MakeMethods::Set
    (
      inherited_set =>
      [
        valid_name =>
        {
          test_method     => 'name_is_valid', 
          delete_implies  => 'delete_required_name',
          inherit_implies => 'inherit_required_name',
        },

        required_name =>
        {
          add_implies => 'add_valid_name',
          test_method => 'name_is_required', 
        },
      ],
    );
    ...

    package MySubClass;
    our @ISA = qw(MyClass);
    ...

    MyClass->add_valid_names('A', 'B', 'C');
    MyClass->add_required_name('D');


    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D';
    $r1 = join(',', MyClass->required_names);    # 'D'

    $v2 = join(',', MySubClass->valid_names);    # 'A,B,C,D';
    $r2 = join(',', MySubClass->required_names); # 'D'

    MyClass->add_required_names('X', 'Y');

    $v2 = join(',', MySubClass->valid_names);    # 'A,B,C,D,X,Y';
    $r2 = join(',', MySubClass->required_names); # 'D,X,Y'

    MySubClass->delete_valid_names('B', 'X');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'D,X,Y'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
    $r2 = join(',', MySubClass->required_names); # 'D,Y'

    MySubClass->delete_required_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'D,X,Y'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
    $r2 = join(',', MySubClass->required_names); # 'Y'

    MySubClass->inherit_required_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'D,X,Y'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
    $r2 = join(',', MySubClass->required_names); # 'D,Y'

    MySubClass->delete_valid_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'D,X,Y'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,Y';
    $r2 = join(',', MySubClass->required_names); # 'Y'

    MySubClass->inherit_valid_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,D,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'D,X,Y'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
    $r2 = join(',', MySubClass->required_names); # 'D,Y'

    MyClass->delete_valid_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'X,Y'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,Y';
    $r2 = join(',', MySubClass->required_names); # 'Y'

    MySubClass->add_required_name('D');

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'X,Y'

    $v2 = join(',', MySubClass->valid_names);    # 'A,C,D,Y';
    $r2 = join(',', MySubClass->required_names); # 'D,Y'

    $h = MyClass->valid_names_hash;

    # This has no affect on the set.  $h is not a reference to the 
    # actual hash used for set storage.
    delete $h->{'C'}; 

    $v1 = join(',', MyClass->valid_names);       # 'A,B,C,X,Y';
    $r1 = join(',', MyClass->required_names);    # 'X,Y'

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
