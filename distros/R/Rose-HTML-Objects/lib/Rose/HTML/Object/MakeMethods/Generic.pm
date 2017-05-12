package Rose::HTML::Object::MakeMethods::Generic;

use strict;

use Carp();

use base 'Rose::Object::MakeMethods';

our $VERSION = '0.606';

sub array
{
  my($class, $name, $args) = @_;

  require Rose::HTML::Text;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  #unless($class->can('parent'))
  #{
  #  $methods{'parent'} = sub
  #  {
  #    my($self) = shift; 
  #    return Scalar::Util::weaken($self->{'parent'} = shift)  if(@_);
  #    return $self->{'parent'};
  #  };
  #}

  if($interface eq 'get_set_init')
  {
    my $init_method = $args->{'init_method'} || "init_$name";

    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return array contents
      unless(@_)
      {
        $self->{$key} = $self->$init_method()  unless(defined $self->{$key});
        return wantarray ? @{$self->{$key} ||= []} : $self->{$key};
      }

      # If called with a array ref, set new value
      if(@_ == 1 && ref $_[0] eq 'ARRAY')
      {
        $self->{$key} = [ map { _coerce_html_object($self, $_) } @{$_[0]} ];
      }
      else
      {
        $self->{$key} = [ map { _coerce_html_object($self, $_) } @_ ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'get_set_inited')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return array contents
      unless(@_)
      {
        $self->{$key} = [] unless(defined $self->{$key});
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      # If called with a array ref, set new value
      if(@_ == 1 && ref $_[0] eq 'ARRAY')
      {
        $self->{$key} = [ map { _coerce_html_object($self, $_) } @{$_[0]} ];
      }
      else
      {
        $self->{$key} = [ map { _coerce_html_object($self, $_) } @_ ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    }
  }
  elsif($interface eq 'get_set_item')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      Carp::croak "Missing array index"  unless(@_);

      if(@_ == 2)
      {
        return $self->{$key}[$_[0]] = _coerce_html_object($self, $_[1]);
      }
      else
      {
        return $self->{$key}[$_[0]]
      }
    }
  }
  elsif($interface eq 'get_item')
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      Carp::croak "Missing array index"  unless(@_);
      return $self->{$key}[$_[0]];
    }
  }
  elsif($interface eq 'delete_item')
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      Carp::croak "Missing array index"  unless(@_);
      no warnings;
      splice(@{$self->{$key} || []}, $_[0], 1);
    }
  }
  elsif($interface eq 'unshift')
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      Carp::croak "Missing value(s) to add"  unless(@_);
      unshift(@{$self->{$key} ||= []}, map { _coerce_html_object($self, $_) } (@_ == 1 && ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_);
    }
  }
  elsif($interface eq 'shift')
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      return splice(@{$self->{$key} ||= []}, 0, $_[0])  if(@_);
      return shift(@{$self->{$key} ||= []})
    }
  }
  elsif($interface eq 'clear')
  {
    $methods{$name} = sub
    {
      $_[0]->{$key} = []
    }
  }
  elsif($interface eq 'reset')
  {
    $methods{$name} = sub
    {
      $_[0]->{$key} = undef;
    }
  }
  elsif($interface =~ /^(?:push|add)$/)
  {
    $methods{$name} = sub
    {
      my($self) = shift;
      Carp::croak "Missing value(s) to add"  unless(@_);
      push(@{$self->{$key} ||= []}, map { _coerce_html_object($self, $_) } (@_ == 1 && ref $_[0] && ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_);
    }
  }
  elsif($interface eq 'pop')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        my $a = $self->{$key} ||= [];
        my $offset = @$a - $_[0];
        return splice(@$a, $offset < 0 ? 0 : $offset)  
      }

      return pop(@{$self->{$key} ||= []})
    }
  }
  elsif($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      # If called with no arguments, return array contents
      unless(@_)
      {
        return wantarray ? (defined $self->{$key} ? @{$self->{$key}} : ()) : $self->{$key}  
      }

      # If called with a array ref, set new value
      if(@_ == 1 && ref $_[0] eq 'ARRAY')
      {
        $self->{$key} = [ map { _coerce_html_object($self, $_) } @{$_[0]} ];
      }
      else
      {
        $self->{$key} = [ map { _coerce_html_object($self, $_) } @_ ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub _coerce_html_object
{
  my($self, $arg) = (shift, shift);

  if(!ref $arg)
  {
    return Rose::HTML::Text->new(text => $arg, parent => $self);
  }
  elsif(!$arg->isa('Rose::HTML::Object'))
  {
    return Rose::HTML::Text->new(text => $arg, parent => $self);
  }

  $arg->parent($self);

  return $arg;
}

1;
