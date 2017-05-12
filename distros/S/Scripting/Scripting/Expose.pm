# $Source: /Users/clajac/cvsroot//Scripting/Scripting/Expose.pm,v $
# $Author: clajac $
# $Date: 2003/07/21 10:10:05 $
# $Revision: 1.10 $

package Scripting::Expose;

use Attribute::Handlers;

use Scripting::Expose::Class;
use Scripting::Expose::Function;

use strict;

my %Classes;
my %Functions;
my %Variables;
my %Packages;

sub is_valid_symbol {
  my $sym = shift;
  return $sym =~ /^[A-Za-z][A-Za-z0-9_]*$/ ? 1 : 0;
}

sub import {
  shift;
  die "Odd number of arguments in use\n" if(@_ & 1);
  my %args = (@_);

  my $pkg = (caller)[0];

  # Class name
  my $name = $pkg;
  $name = $args{as} if(exists $args{as});
  
  die "Undefined class name in '$pkg'\n" unless(defined $name);
  die "Empty class name in '$pkg'\n" if($name eq '');
  die "Unsupported class name '$name' in '$pkg'\n" unless(is_valid_symbol($name));
    
  # For categories
  my $to;
  if (exists $args{to}) {
    $to = $args{to};
    die "To must be a scalar or an ARRAY reference in '$pkg'\n" unless(ref $to eq '' || ref eq 'ARRAY');
    $to = [$to] unless(ref $to);

    for (@$to) {
      die "Invalid to '$_' in '$pkg'\n" unless(is_valid_symbol($_));
    }
  } else {
    $to = [qw(_Global)];
  }
    
  $Packages{$pkg} = {} unless(ref $Packages{$pkg} eq 'HASH');
  $Packages{$pkg}->{$_} = 1 for(@$to);

  if ($name) {
    my $class = Scripting::Expose::Class->new($name, $pkg);
    if (exists $Classes{$class->package} && $class->package ne $pkg) {
      die "Class '@{[$class->class]}' already in package '@{[$class->package]}'\n";
    }

    $Classes{$class->package} = $class;

    unless (exists $Functions{$pkg}) {
      my $func_table = Scripting::Expose::Function->new();
      $Functions{$pkg} = $func_table;
    }
  }

  1;
}

sub _process {
  my ($pkg, $symbol, $ref, $handler, $options, $phase) = @_;

  die "Can't expose anonymous subrutines\n" if($symbol eq 'ANON');
  die "Invalid symbol '$symbol'\n" unless(ref $symbol eq 'GLOB');

  my ($name) = *$symbol =~ /^.*::(.*)$/;
  my $orig_name = $name;
  my $secure = 0;

  if ($options) {
    die "Odd number of arguments to '$handler' in '$pkg'\n" if(ref $options ne 'ARRAY' || @$options & 1);
    my %args = (@$options);

    if (exists $args{as} && ($name = $args{as})) {
      die "Undefined name for '$orig_name' in '$pkg'\n" unless(defined $name);
      die "Empty name for '$orig_name' in '$pkg'\n" if($name eq '');
      die "Unsupported name '$name' for '$orig_name' in '$pkg'\n" unless(is_valid_symbol($name));
    }

    if (exists $args{secure}) {
      die "Unsupported security '$args{secure}' for '$orig_name' in '$pkg'\n" unless($args{secure} =~ /^arguments$/);
      $secure = $args{secure};
    }
  }

  die "Package '$pkg' not bound as class\n" if($handler =~ /Method$/ && not exists $Classes{$pkg});

  if($handler eq 'Constructor') {
    die "Constructor already defined in '$Classes{$pkg}->{class}'\n" if($Classes{$pkg}->has_constructor());
    die "Can't mix Contstructor/InstanceMethod with ClassMethods in '$pkg'\n" if($Classes{$pkg}->is_class_object());
    $Classes{$pkg}->add_constructor($ref,$secure);
  } elsif($handler eq 'ClassMethod') {
    die "ClassMethod '$name' already bound in '$Classes{$pkg}->{class}'\n" if($Classes{$pkg}->has_method($name));
    die "Can't mix ClassMethods with Constructor/InstanceMethod in '$pkg'\n" if($Classes{$pkg}->is_instance_object());
    $Classes{$pkg}->add_class_method($name, $ref, $secure);
  } elsif ($handler eq 'InstanceMethod') {
    die "InstanceMethod '$name' already bound in '$Classes{$pkg}->{class}'\n" if($Classes{$pkg}->has_method($name));
    die "Can't mix Contstructor/InstanceMethod with ClassMethods in '$pkg'\n" if($Classes{$pkg}->is_class_object());
    $Classes{$pkg}->add_instance_method($name, $ref, $secure);
  } elsif ($handler eq 'Function') {
    $Functions{$pkg}->add_function($name, $ref, $secure);
  }
}

sub UNIVERSAL::Constructor : ATTR(CODE) {
  my ($pkg, $symbol, $ref, $handler, $options, $phase) = @_;
  _process($pkg, $symbol, $ref, 'Constructor', $options, $phase);
}

sub UNIVERSAL::ClassMethod : ATTR(CODE) {
  my ($pkg, $symbol, $ref, $handler, $options, $phase) = @_;
  _process($pkg, $symbol, $ref, 'ClassMethod', $options, $phase);
}

sub UNIVERSAL::InstanceMethod : ATTR(CODE) {
  my ($pkg, $symbol, $ref, $handler, $options, $phase) = @_;
  _process($pkg, $symbol, $ref, 'InstanceMethod', $options, $phase);
}

sub UNIVERSAL::Function : ATTR(CODE) {
  my ($pkg, $symbol, $ref, $handler, $options, $phase) = @_;
  _process($pkg, $symbol, $ref, 'Function', $options, $phase);
}

sub has_namespace {
  my ($pkg, $ns) = @_;

  for (values %Packages) {
    return 1 if(exists $_->{$ns});
  }
    
  0;
}

sub functions_for_namespace {
  my ($self, $ns) = @_;

  my @func;
  for(grep { exists $Packages{$_}->{$ns} } keys %Packages) {
    push @func, $Functions{$_}->functions;
  }

  return @func;
}

sub classes_for_namespace {
  my ($self, $ns) = @_;

  my @classes;
  for(grep { exists $Packages{$_}->{$ns} } keys %Packages) {
    push @classes, $Classes{$_};
  }

  return @classes;
}

1;
