package Object::Generic;
#
# Object::Generic.pm
#
# A generic base class for objects including 
# several set/get interfaces for key/value pairs within the object.
#
#    use Object::Generic;
#    $thing = new Object::Generic  color => 'red';
#
#    $color = $thing->get('color');
#    $color = $thing->get_color;
#    $color = $thing->color
#
#    $thing->set( color => 'blue' );
#    $thing->set_color('blue');
#    $thing->color('blue');
#
# See the bottom of this file for the documentation.
#
# $Id: Generic.pm 403 2005-09-08 20:17:37Z mahoney $
#
#
use strict;
use warnings;
use Object::Generic::False qw(false);

our $VERSION = '0.13';

my $false = Object::Generic::false();

sub new {
  my $class = shift;
  my $self  = bless {} => $class;
  $self->args(@_);
  return $self;
}

# Return a list of the current keys.
sub keys {
  my $self = shift;
  return keys %$self;
}

# Return true or false depending on whether a key has been defined.
sub exists {
  my $self = shift;
  my ($key) = @_;
  return 0 unless defined $key;
  return exists($self->{$key});
}

#
# If the hash for a given class is empty, then any key is allowed 
# in ->set_key() and its variants for that class.
# Otherwise, only the given keys are allowed.
# The allowed keys are defined relative to a given class name
# so that inherited classes will each have their own list of allowed keys.
#
# In other words, if MyClass inherits from Object::Generic,
# and only 'color' and 'height' are allowed keys for that class,
# then this hash will include  
#   $allowed_keys = { MyClass => { color=>1, height=>1 } }
# On the other hand, since there is no $allowed_keys->{Object::Generic},
# any key is allowed (by default) in Object::Generic.
#
our $allowed_keys = { };

# Usage: InheritedClass->set_allowed_keys( 'color', 'size' );
# This sets the keys for an entire class,  *not* for one instance.  
# If you want different objects with different sets of allowed keys, 
# define several classes that inherit from Object::Generic.
sub set_allowed_keys {
  my $class = shift;
  return 0 if ref($class); # do nothing and return false if this is an object.
  my @keys = @_;
  $allowed_keys->{$class}{$_} = 1 foreach @keys;
  return 1;  # return true
}

#
# Usage: if ( InheritedClass->allows_key($key) ){ ... }
#    or  if ( $object->allows_key($key) ){ ... }
sub allows_key {
  my $self_or_class = shift;  # either class or object method; don't care.
  my $class = ref($self_or_class) || $self_or_class;
  my ($key) = @_;
  return 1 unless exists($allowed_keys->{$class});
  return $allowed_keys->{$class}{$key};
}


# Usage: InheritedClass->define_accessors( @keys );
# For each $key, defines $obj->get_key(), $obj->set_key(), and $obj->key().
# Also calls set_allowed_keys, so as a side effect, other keys not in
# this won't be allowed unless given in another call to set_allowed_keys
# or define_accessors.  Note that this may be helpful if you're using
# multiple inheritance, since this can avoid the use of AUTOHANDLER which
# may not be available if there's another AUTOHANDER earlier in the 
# inheritence chain.
sub define_subs {
  my $class = shift;
  return if ref($class); # This can't be called from an object instance.
  my @keys = @_;
  $class->set_allowed_keys(@keys);
  for my $key (@keys){
    no strict 'refs';
    *{$class . '::' . $key } = sub {
      $_[0]->set( $key => $_[1] ) if exists $_[1];
      return $_[0]->get( $key );
     };
    *{$class . '::' . 'set_' . $key } = sub {
      $_[0]->set($key => $_[1]);
      return $_[0]->get($key);
    };
    *{$class . '::' . 'get_' . $key } = sub {
      return $_[0]->get($key);
    };
  }
}

# $obj->remove($key) is the same as delete($obj->{$key});
sub remove {
  my $self = shift;
  my $key  = shift;
  return unless $key;
  delete($self->{$key});
}

#
# The following ->set(key=>value) and ->get(value) methods
# are the only authorized way to access the internal data;
# all other internal and external methods (including 
# the memo-ized subs that AUTOHANDLER creates) use these.
# This makes it simpler to change the internal storage mechanism
# in an inherited class, at the cost of a bit of speed.
#

# Usage: $value = $object->get( 'key' );
sub get {
  my $self = shift;
  my ($key) = @_;
  return $false unless ref($self);
  return $false unless $self->exists($key);
  return $self->{$key};
}

# Usage: $object->set( key => $value );
sub set {
  my $self = shift;
  return $false unless ref($self);
  my ($key, $value) = @_;
  $self->{$key} = $value;
  return $value;
}

# $obj->args(@_) :
# Extract key => value pairs from the @_ and put them in the object's hash.
# The motivation runs like this:
#   When I call $foo->bar( one => 1, two => 2), 
#   I often want to have $foo->{one}=1 and $foo->{two}=2.
#   This subroutine does that.  
# While this is not the default behavior of all inherited methods, 
# any methods that do want this behavior can implement it with this method.
# Note that the CORE::keys syntax distinguishes this from $obj->keys()
sub args {
  my $self = shift;
  my %hash = @_;
  $self->set($_ => $hash{$_}) foreach CORE::keys(%hash);
  return $self;
}

sub DESTROY {  # Define this here so AUTOLOAD won't handle it.
}

sub AUTOLOAD {
  my $self = shift;
  my ($value) = (@_);
  return $false unless ref($self); # Don't handle class methods.
  our $AUTOLOAD;
  no strict 'refs';
  $AUTOLOAD =~ m/^(.*)::\w+$/;
  my $class = $1;
  (my $subname = $AUTOLOAD) =~ s/.*:://;      # Remove class:: from sub name.
  # -- debugging --
  #print " -- Generic::AUTOLOAD\n";
  #print "    autoload = '$AUTOLOAD'\n";
  #print "    subname  = '$subname'\n";
  #print "    class    = '$class'\n";
  if ($subname =~ /^set_(.*)$/){              # Define $obj->set_key($value)
    my $key = $1; 
    return $false unless $class->allows_key($key);
    *{$AUTOLOAD} = sub {  
      return $false unless exists $_[1];
      $_[0]->set( $key => $_[1] );
      return $_[1];
    };
  }
  elsif ($subname =~ /^get_(.*)$/){           # Define $obj->get_key()
    my $key = $1;
    return $false unless $class->allows_key($key);
    *{$AUTOLOAD} = sub {
      return $_[0]->get($key);
    };
  }
  else {                                      # Define $obj->key($value)
    my $key = $subname;
    return $false unless $class->allows_key($key);
    *{$AUTOLOAD} = sub {
      if (exists($_[1])){
	$_[0]->set( $key => $_[1] );
	return $_[1];
      }
      else {
	return $_[0]->get($key);
      }
    };
  }
  return $self->$subname(@_);                 # Call it.
}

1;

__END__

=head1 NAME

Object::Generic - A generic base class that allows storage of key/value pairs.

=head1 SYNOPSIS

  use Object::Generic;
  $thing = new Object::Generic  color => 'red';

  $color = $thing->get('color');
  $color = $thing->get_color;
  $color = $thing->color;

  $thing->set( color => 'blue' );
  $thing->set_color('blue');
  $thing->color('blue');

  $thing->remove('color');

  @key_list  = $thing->keys;
  $has_color = $thing->exists('color');

  package myClass;
  use base 'Object:Generic';
  myClass->set_allowed_keys('color', 'width', 'height', 'border');
  sub myMethod {
    my $self=shift;
    $self->args(@_);    # processes @args=(key=>value, key=>value, ...)
    print $self->width;
  }

  package otherClass;
  use base 'Object::Generic';
  otherClass->define_accessors(qw( name age weight ));
  my $guy = new OtherClass;
  $guy->name('Jim');  
  print "his name is " . $guy->name . "\n";

  package main;
  use myClass;
  $obj = new myClass color => 'green', width => 5;
  $usa = new Object::Generic language=>'english', hemisphere=>'north';
  $obj->set_country($usa);             # fails; 'country' not an allowed key.
  if ($obj->country->language){ ... }  # false, but isn't an error.
  $obj->myMethod( width => 10 );
  $obj->border(10) if $obj->allows_key('border');
  print $obj->border;

=head1 DESCRIPTION

This package defines an object that lets key/value pairs be stored
and fetched with either the typical $obj->set_key('value') 
and  $obj->get_key() syntax, or with a Class::DBI-ish $obj->key('value')
and $obj->key syntax.

The keys may be but do not need to be declared ahead of time.
Any previously undefined method invoked on 
an instance of Object::Generic defines a possible key.

The methods 'exists' and keys' serve the same purpose as the perl 
functions exists(%hash{key}) and keys(%hash).

Class methods, methods that try to fetch a value that has 
never been defined, and keys that aren't allowed
all return an Object::Generic::False which is false in a boolean context
but which allows error chaining without a fatal error.
In other words, even though $obj->foo is not defined, 
$obj->foo->bar->baz returns false (well, an Object::Generic::False)
rather than crashing.

A number of key/value pairs may be defined all at once with
the built-in $obj->args( key1=>'value1', key2=>'value2') method.

The Object::Generic class may be used as a base class; 
by default any methods in the inherited class that aren't defined 
will be treated as keys.

As an alternative to having the accessor subroutines (e.g. 
$object->name, $object->set_name, $object->get_name for key='name')
defined by AUTOLOAD the first time they're invoked, they may
be created explicitly with a call to $class->define_accessors(@keys).
This also calls $class->set_allowed_keys(@keys), which means that 
trying to access keys that aren't explicitly allowed will give an error.
One advantage to defining the accessors explicitly is that multiple
inheritence is easier, since the Object::Generic::AUTOLOAD isn't needed.

=head1 BUGS

This should be in the Class:: namespace somewhere.  Oops.

=head1 SEE ALSO

Object::Generic::False, Object::Generic::Session, Class::DBI

=head1 AUTHOR

Jim Mahoney, E<lt>mahoney@marlboro.edu<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jim Mahoney

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
