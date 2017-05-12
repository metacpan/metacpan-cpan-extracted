package Spreadsheet::Engine::Fn::base;

use strict;
use warnings;

use Carp;
use Class::Struct;
use Encode;

use Spreadsheet::Engine::Value;
use Spreadsheet::Engine::Error;
use Spreadsheet::Engine::Fn::Operand;
use Spreadsheet::Engine::Sheet qw/ copy_function_args lookup_result_type
  operand_value_and_type operand_as_number operand_as_text
  top_of_stack_value_and_type /;

struct(__PACKAGE__,
  {
    fname      => '$',
    operand    => '$',
    errortext  => '$',
    typelookup => '$',
    sheetdata  => '$',
    _opstore   => '@',
  }
);

sub execute {
  my $self = shift;

  my $result = eval {

    # make sure we check args even for functions that don't need any
    # TODO rearrange this logic
    my @foperand = $self->foperand;
    $self->result;
  };

  if ($@) {
    die $@ unless ref $@;
    $result = $@;
    $result = $@;
  }

  push @{ $self->operand }, { type => $result->type, value => $result->value }
    if $result;
  return;
}

sub foperand {
  my $self = shift;
  return $self->{_foperand} if defined $self->{_foperand};

  copy_function_args($self->operand, \my @foperand);

  if ($self->can('argument_count') or $self->can('signature')) {
    my ($min_args, $max_args) =
      $self->can('argument_count')
      ? ($self->argument_count)
      : (0 + @{ [ $self->signature ] });
    my $have_args = scalar @foperand;

    if ( ($min_args < 0 and $have_args < -$min_args)
      or ($min_args >= 0 and $have_args != $min_args)
      or (defined $max_args and $have_args > $max_args)) {
      die Spreadsheet::Engine::Error->val(
        sprintf('Incorrect arguments to function "%s". ', $self->fname),
      );
    }
  }

  return ($self->{_foperand} = \@foperand);
}

sub _opvals { map $_->value, shift->_ops }

sub _ops {
  my $self = shift;
  if (@{ $self->_opstore } == 0) {
    my $numargs = scalar @{ $self->foperand };
    my @argdef  = $self->signature;

    my @operands = ();

    # Loop over args, not defs, so that optional args don't fail
    for my $sig (@argdef[ 0 .. $numargs - 1 ]) {
      my $op;

      if ($sig eq 'n') {    # any number - was 0
        $op = $self->next_operand_as_number;
      } elsif ($sig eq 't') {    # any string - was 1
        $op = $self->next_operand_as_text;
      } elsif ($sig eq '*') {    # anything at all
        $op = $self->next_operand;
      } elsif ($sig eq 'r') {    # range
                                 # TODO refactor this into Range object
                                 # For now we'll just hijack an op
        $op = Spreadsheet::Engine::Fn::Operand->new(
          type  => 'r',
          value => pop @{ $self->foperand },
        );
        die Spreadsheet::Engine::Error->val('Incorrect arguments')
          unless $op->value->{type} eq 'range';
      } else {
        croak 'Missing signature value in ' . $self->fname unless $sig;
        $op = $self->next_operand_as_number;
        my @tests = (ref $sig eq 'ARRAY') ? @{$sig} : $sig;
        foreach my $check (@tests) {
          if (ref $check eq 'CODE') {
            die Spreadsheet::Engine::Error->val('Invalid arguments')
              unless $check->($op->value);
          } elsif ($check =~ /^([!<>]=?)(-?\d+)/) {    # >=0 <1 etc.
            my ($test, $num) = ($1, $2);
            my $val = $op->value;
            die Spreadsheet::Engine::Error->val('Invalid arguments')
              unless eval "$val $test $num";
          } else {
            croak "Error in signature ($check) of " . $self->fname;
          }
        }
      }

      die $op if $op->is_error and not $self->_error_ops_ok;
      push @operands, $op;
    }
    $self->_opstore(\@operands);
  }
  return @{ $self->_opstore };
}

# Usually, when extracting the operands based on the signature, any
# operand that is of type 'error' will cause the entire function to die
# with that error. Subclassing this method to return a true value will
# allow that error to be passed through as-is.

sub _error_ops_ok { 0 }

sub next_operand {
  my $self  = shift;
  my $value =
    operand_value_and_type($self->sheetdata, $self->foperand,
    $self->errortext, \my $tostype);
  return Spreadsheet::Engine::Fn::Operand->new(
    value => $value,
    type  => $tostype
  );
}

sub next_operand_as_number {
  my $self  = shift;
  my $value =
    operand_as_number($self->sheetdata, $self->foperand, $self->errortext,
    \my $tostype);
  return Spreadsheet::Engine::Fn::Operand->new(
    value => $value,
    type  => $tostype
  );
}

sub next_operand_as_text {
  my $self  = shift;
  my $value =
    operand_as_text($self->sheetdata, $self->foperand, $self->errortext,
    \my $tostype);
  return Spreadsheet::Engine::Fn::Operand->new(
    value => decode(utf8 => $value),
    type  => $tostype
  );
}

sub top_of_stack {
  my $self = shift;
  my ($value, $type) =
    top_of_stack_value_and_type($self->sheetdata, $self->foperand,
    $self->errortext);
  return unless $type;
  return Spreadsheet::Engine::Fn::Operand->new(
    value => $value,
    type  => $type
  );
}

sub optype {
  my ($self, $operation, @op) = @_;

  my $tl = $self->typelookup->{$operation};

  my $first = shift @op;
  my $type  = $first->type;

  # Check against self if no others supplied
  push @op, $first if $operation eq 'oneargnumeric' and not @op;

  while (my $next = shift @op) {
    $type = lookup_result_type($type, (ref $next ? $next->type : $next), $tl);
  }
  return Spreadsheet::Engine::Value->new(type => $type, value => 0);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::base - base class for spreadsheet functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::text';

=head1 DESCRIPTION

This provides a base class for spreadsheet functions.

Each function will generally have an intermediate base class that
extends this with methods specific to the type of function that it is
providing.

=head1 CONSTRUCTOR

=head2 new

Instantiates with the given variables.

=head1 INSTANCE VARIABLES

=head2 fname / operand / foperand / errortext / typelookup / sheetdata 

As per SocialCalc (to document fully later)

=head1 METHODS TO SUBCLASS

=head2 argument_count

Each function should declare how many arguments it expects. This should
be 0 for no arguments, a positive integer for exactly that many
arguments, or a negative integer for at least that many arguments (based
on the absolute value). 

In the latter case, an optional second value will declare a maximum
number of arguments (e.g. return (-2, 4) = between 2 and 4 arguments)

If this method is not provided no checking of arguments is performed.

=head2 signature (EXPERIMENTAL)

Functions may also declare a signature function that declares, for each
operand that the function can receive, whether it must be 't' (text),
'n' (numeric), or in the case of a number, a test ('>0', '<=1') that it
must pass. The entire operand stack can then be popped as
$self->_ops, throwing an "Invalid arguments" error if required.

=head2 result

Functions should provide a result() method that will return a value/type
hash containing the calculated response.

=head2 result_type

This will normally be calculated based on a lookup of the types of
operands provided, but subclasses can override this.

=head1 METHODS

=head2 execute

This delegates to the response() method in the subclass, and pushes the
response onto the stack. 

=head2 next_operand / next_operand_as_text / next_operand_as_number

	my $op = $self->next_operand
	print $op->{value} => $op->{type};

Pops the top of the operand stack and returns a hash containing the
value and type. (This is currently a simple delegation to
Sheet::operand_value_and_type/operand_as_text/operand_as_number

next_operand_as_text also encodes its return value as utf8.

=head2 top_of_stack

Fetch the next operand using top_of_stack_value_and_type(). (This deals
differently with ranges and co-ordinates.)

=head2 optype

	my $type = $self->optype('twoargnumeric', $op1, $op2);

Returns the resulting value type when doing an operation.

=cut

=head1 HISTORY

This is a Modified Version of code extracted from SocialCalc::Functions
in SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2007, 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0


