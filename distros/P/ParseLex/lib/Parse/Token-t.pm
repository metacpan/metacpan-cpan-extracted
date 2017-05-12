# Copyright (c)  Philippe Verdret, 1995-1998

require 5.003;
use strict;

package Parse::Token;

my $old_next = \&next;
*next = sub {			# add some actions before and after the routine call
  my $self = $_[0];
  if ($Parse::Token::trace) {
    my $name = $self->name;
    $self->context("try to find:\t$name");
    my $reader = $self->reader;
    my $pendingToken = $reader->[$Lex::PEND_TOKEN];
    if ($pendingToken) {
      if ($pendingToken->name eq 'EOI') {
	$self->context("End of input at line $.");	
	return undef;
      } else {
	$self->context("pending token:\t", $pendingToken->name);
      }
    }
  }
  my $string = &$old_next(@_);
  if ($Parse::Token::trace) {
    if ($self->status) {
      $self->context("token found: $string");
    } else {
      $self->context("token not found");
    }
  }
  $string;
};

my $old_isnext = \&isnext;
*isnext = sub {
  my $self = $_[0];
  if ($Parse::Token::trace) {
    my $name = $self->name;
    $self->context("try to find:\t$name");
    my $reader = $self->reader;
    my $pendingToken = $reader->[$Lex::PEND_TOKEN];
    if ($pendingToken) {
      if ($pendingToken->name eq 'EOI') {
	$self->context("End of input at line $.");	
	return undef;
      } else {
	$self->context("pending token:\t", $pendingToken->name);
      }
    }
  }
  my $status = &$old_isnext(@_);
  if ($Parse::Token::trace) {
    if ($self->status) {
      $self->context("token found: ${$_[1]}");
    } else {
      $self->context("token not found");
    }
  }
  $status;
};

1;

__END__
