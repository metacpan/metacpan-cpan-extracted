# $Source: /Users/clajac/cvsroot//Scripting/Scripting/Expose/Function.pm,v $
# $Author: clajac $
# $Date: 2003/07/19 21:02:18 $
# $Revision: 1.5 $

package Scripting::Expose::Function;
use strict;

sub new {
  my ($pkg) = @_;
  $pkg = ref $pkg || $pkg;

  my $self = bless {
		    entries => {},
		   }, $pkg;

  return $self;
}

sub has_function {
  my ($self, $name);

  return exists $self->{entries}->{$name};
}

sub add_function {
  my ($self, $name, $code, $secure) = @_;

  if ($secure eq 'arguments') {
    $code = sub {
      $code->(@_, Scripting::Security->secure);
    };
  }

  $self->{entries}->{$name} = $code;
}

sub functions {
  my $self = shift;
  return %{$self->{entries}};
}

1;
