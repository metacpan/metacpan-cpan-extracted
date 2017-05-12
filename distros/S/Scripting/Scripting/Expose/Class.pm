# $Source: /Users/clajac/cvsroot//Scripting/Scripting/Expose/Class.pm,v $
# $Author: clajac $
# $Date: 2003/07/21 07:33:21 $
# $Revision: 1.8 $

package Scripting::Expose::Class;
use strict;

sub new {
  my ($pkg, $class, $package) = @_;
  $pkg = ref $pkg || $pkg;

  my $self = bless {
		    class => $class,
		    package => $package,
		    constructor => undef,
		    class_methods => {},
		    instance_methods => {},
		   }, $pkg;

  return $self;
}

sub class {
  my $self = shift;
  return $self->{class};
}

sub package {
  my $self = shift;
  return $self->{package};
}

sub has_method {
  my ($self, $name) = @_;
  return exists $self->{class_methods}->{$name} || exists $self->{instance_methods}->{$name};
}

sub has_constructor {
  my ($self) = @_;
  return 1 if(defined $self->{constructor});
  return 0;
}

sub add_constructor {
  my ($self, $code, $secure) = @_;
  if($secure eq 'arguments') {
    $code = sub {
      $code->(@_, Scripting::Security->secure);
      };
  }
  $self->{constructor} = $code;
}

sub add_class_method {
  my ($self, $name, $code, $secure) = @_;
 
  if ($secure eq 'arguments') {
    $code = sub {
      $code->(@_, Scripting::Security->secure);
    };
  }

  $self->{class_methods}->{$name} = $code;
}    

sub add_instance_method {
  my ($self, $name, $code, $secure) = @_;

  if ($secure eq 'arguments') {
    $code = sub {
      $code->(@_, Scripting::Security->secure);
    };
  }

  $self->{instance_methods}->{$name} = $code;
}

sub is_instance_object {
  my ($self) = shift;
  return scalar(keys %{$self->{instance_methods}}) || defined $self->{constructor};
}

sub is_class_object {
  my ($self) = shift;

  return scalar(keys %{$self->{class_methods}});
}


1;
