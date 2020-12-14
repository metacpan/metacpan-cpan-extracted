package Sub::WrapInType;
use 5.010001;
use strict;
use warnings;
use parent 'Exporter';
use Class::InsideOut qw( register readonly id );
use Carp ();
use Hash::Util ();
use Scalar::Util ();
use Types::Standard -types;
use Type::Params qw( multisig compile compile_named Invocant );
use namespace::autoclean;

our $VERSION = '0.04';
our @EXPORT  = qw( wrap_sub );

readonly params  => my %params;
readonly returns => my %returns;
readonly code    => my %code;

my $TypeConstraint = HasMethods[qw( assert_valid )];
my $ParamsTypes    = $TypeConstraint | ArrayRef[$TypeConstraint] | Map[Str, $TypeConstraint];
my $ReturnTypes    = $TypeConstraint | ArrayRef[$TypeConstraint];

sub new {
  my $class = shift;
  state $check = multisig(
    +{ message => << 'EOS' },
USAGE: wrap_sub(\@parameter_types, $return_type, $subroutine)
    or wrap_sub(params => \@params_types, returns => $return_types, code => $subroutine)
EOS
    [ $ParamsTypes, $ReturnTypes, CodeRef ],
    compile_named(
      params => $ParamsTypes,
      isa    => $ReturnTypes,
      code   => CodeRef,
    ),
  );
  my ($params_types, $return_types, $code) = do {
    my @args = $check->(@_);
    ${^TYPE_PARAMS_MULTISIG} == 0 ? @args : @{ $args[0] }{qw( params isa code )};
  };

  my $params_types_checker =
      ref $params_types eq 'ARRAY' ? compile(@$params_types)
    : ref $params_types eq 'HASH'  ? compile_named(%$params_types)
    :                                compile($params_types);
  my $return_types_checker =
    ref $return_types eq 'ARRAY' ? compile(@$return_types) : compile($return_types);

  my $typed_code = do {
    if (ref $return_types eq 'ARRAY') {
      sub {
        my @return_values = $code->( $params_types_checker->(@_) );
        $return_types_checker->(@return_values);
        @return_values;
      };
    }
    else {
      sub {
        my $return_value = $code->( $params_types_checker->(@_) );
        $return_types_checker->($return_value);
        $return_value;
      };
    }
  };

  my $self = bless $typed_code, $class;
  register($self);

  {
    my $addr = id $self;
    $params{$addr}  = $params_types;
    $returns{$addr} = $return_types;
    $code{$addr}    = $code;
  }

  $self;
}

sub wrap_sub {
  unshift @_, __PACKAGE__;
  goto &new;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sub::WrapInType - Wrap the subroutine to validate the argument type and return type.

=head1 SYNOPSIS

  use Types::Standard -types;
  use Sub::WrapInType;

  my $sum = wrap_sub [ Int, Int ], Int, sub {
    my ($x, $y) = @_;
    $x + $y;
  };
  $sum->(2, 5);  # Returns 7
  $sum->('foo'); # Throws an exception

  my $subtract = wrap_sub [ Int, Int ], Int, sub {
    my ($x, $y) = @_;
    "$x - $y";
  };
  $subtract->(5, 2); # Returns string '5 - 2', error!

=head1 DESCRIPTION

Sub::WrapInType is wrap the subroutine to validate the argument type and return type.

=head1 FUNCTIONS

=head2 wrap_sub(\@parameter_types, $return_type, $subroutine)

If you pass type constraints of parameters, a return type constraint, and a subroutine to this function,
Returns the subroutine wrapped in the process of checking the arguments given in the parameter's type constraints and checking the return value with the return value's type constraint.

  my $sum = wrap_sub [Int, Int], Int, sub {
    my ($x, $y) = @_;
    $x + $y;
  };
  $sum->(2, 5);  # Returns 7
  $sum->('foo'); # Throws an exception (Can not pass string)

  my $wrong_return_value = wrap_sub [Int, Int], Int, sub {
    my ($x, $y) = @_;
    "$x + $y";
  };
  $wrong_return_value->(2, 5); # Throws an exception (The return value isn't an Integer)
  $sum->('foo');               # Throws an exception (Can not pass string)

The type constraint expects to be passed an object of Type::Tiny.

When the subroutine returns multiple return values, it is possible to specify multiple return type constraints.

  my $multi_return_values = wrap_sub [Int, Int], [Int, Int], sub {
    my ($x, $y) = @_;
    ($x, $y);
  };
  my ($x, $y) = $multi_return_values->(0, 1);

You can pass named parameters.

  my $sub = wrap_sub(
    params => [Int, Int],
    return => Int,
    code   => sub {
      my ($x, $y) = @_;
      $x + $y;
    },
  );

If subroutine returns array or hash, Sub::WrapInType will not be able to check the type as you intended.
You should rewrite the subroutine to returns array reference or hash reference.

Sub::WrapInType does not support wantarray.

This is a wrapper for the constructor.

=head1 METHODS

=head2 new(\@parameter_types, $return_type, $subroutine)

Constract a new Sub::WrapInType object.

  use Types::Standard -types;
  use Sub::WrapInType;
  my $wraped_sub = Sub::WrapInType->new([Int, Int] => Int, sub { $_[0] + $_[1] });

=head1 LICENSE

Copyright (C) mp0liiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mp0liiu E<lt>mpoliiu@cpan.orgE<gt>

=head1 SEE ALSE

L<Type::Params> exports the function wrap_sub. It check only parameters type.

=cut

