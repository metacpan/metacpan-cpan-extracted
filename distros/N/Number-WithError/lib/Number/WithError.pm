package Number::WithError;

use 5.006;
use strict;
use warnings;
use Params::Util qw/_ARRAY _INSTANCE _ARRAY0/;
use prefork 'Math::BigFloat';

our $VERSION = '1.01';

use base 'Exporter';
our @EXPORT_OK = qw(
  witherror
  witherror_big
);
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

our $CFloat = qr/[+-]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee][+-]?\d+)?/;
our $CFloatCapture = qr/([+-]?)(?=\d|\.\d)(\d*)(\.\d*)?([Ee][+-]?\d+)?/;

# define function "tan"
#use Math::Symbolic;
#use Math::SymbolicX::Inline <<'HERE';
#HERE
#my_tan = tan(arg0)
sub _my_tan { return CORE::sin($_[0]) / CORE::cos($_[0]) }

=head1 NAME

Number::WithError - Numbers with error propagation and scientific rounding

=head1 SYNOPSIS

  use Number::WithError;
  
  my $num = Number::WithError->new(5.647, 0.31);
  print $num . "\n";
  # prints '5.65e+00 +/- 3.1e-01'
  # (I.e. it automatically does scientific rounding)
  
  my $another = $num * 3;
  print $another . "\n";
  # propagates the error assuming gaussian errors
  # prints '1.69e+01 +/- 9.3e-01'
  
  # trigonometric functions also work:
  print sin($another) . "\n";
  # prints '-9.4e-01 +/- 3.1e-01'
  
  my $third = $another ** $num;
  print $third. "\n";
  # propagates both errors into one.
  # prints '8.7e+06 +/- 8.1e+06'
  
  # shortcut for the constructor:
  use Number::WithError 'witherror';
  $num = witherror('0.00032678', ['2.5e-5', '3e-5'], 5e-6);
  # can deal with any number of errors, even with asymmetric errors
  print $num . "\n";
  # prints '3.268e-04 + 2.5e-05 - 3.00e-05 +/- 5.0e-06'
  # Note: It may be annyoing that they don't all have the same
  # exponent, but they *do* all have the sam significant digit!

=head1 DESCRIPTION

This class is a container class for numbers with a number of associated
symmetric and asymmetric errors. It overloads practically all common
arithmetic operations and trigonometric functions to propagate the
errors. It can do proper scientific rounding (as explained in more
detail below in the documentation of the C<significant_digit()> method).

You can use L<Math::BigFloat> objects as the internal representation
of numbers in order to support arbitrary precision calculations.

Errors are propagated using Gaussian error propagation.

With a notable exception, the test suite covers way over ninety percent of
the code. The remaining holes are mostly difficult-to-test corner cases and
sanity tests. The comparison routines are the exception
for which there will be more extensive tests in a future release.

=head1 OVERLOADED INTERFACE

This module uses L<overload> to enable the use of the ordinary Perl arithmetic
operators on objects. All overloaded operations are also availlable via
methods. Here is a list of overloaded operators and the equivalent methods.
The assignment forms of arithmetic operators (e.g. C<+=>) are availlable
if their normal counterpart is overloaded.

=over 2

=item *

Addition: C<$x + $y> implemented by the C<$x-E<gt>add($y)> method.

=item *

Increment: C<$x++> implemented by the C<$x-E<gt>add(1)> method.

=item *

Subtraction: C<$x - $y> implemented by the C<$x-E<gt>subtract($y)> method

=item *

Decrement: C<$x--> implemented by the C<$x-E<gt>subtract(1)> method.

=item *

Multiplication: C<$x * $y> implemented by the C<$x-E<gt>multiply($y)> method.

=item *

Division: C<$x / $y> implemented by the C<$x-E<gt>divide($y)> method.

=item *

Exponentiation: C<$x ** $y> implemented by the C<$x-E<gt>exponentiate($y)> method.

=item *

Sine: C<sin($x)> implemented by the C<$x-E<gt>sin()> method.

=item *

Cosine: C<cos($x)> implemented by the C<$x-E<gt>cos()> method.

=item *

Stringification C<"$x"> is implemented by the C<$x-E<gt>round()> method.

=item *

Cast to a number (i.e. numeric context) is implemented by the C<$x-E<gt>number()> method.

=item *

Boolean context is implemented by the C<$x-E<gt>number()> method.

=item *

Unary minus C<-$x> is implemented by the C<$x-E<gt>multiply(-1)> method.

=item *

Logical not is implemented via a boolean context.

=item *

Absolute value C<abs($x)> is implemented via C<$x-E<gt>abs()>.

=item *

Natural logarithm C<log($x)> is implemented via C<$x-E<gt>log()>.

=item *

Square Root C<sqrt($x)> is implemented via C<$x-E<gt>sqrt()>.

=item *

Numeric comparison operators C<$x == $y>, C<$x != $y>, etc. are implemented via C<$x-$<gt>numeric_cmp($y)>.

=item *

String comparison operators C<$x eq $y>, C<$x ne $y>, etc. are implemented via C<$x-$<gt>full_cmp($y)>. They might not do what you expect. Please read the documentation.

=back

Here's a list of overloadable operations that aren't overloaded in the context of
this module:

  << >> x . & ^ | atan2 int

=head1 CONSTRUCTORS

All constructors accept L<Math::BigFloat> objects in place of numbers.

=head2 new

This is the basic constructor for C<Number::WithError> objects.

New objects can be created in one of two ways:

=over 2

=item *

The first argument is expected to be the number itself. Then come
zero or more errors. Errors can either be a number, a reference to
an array of two numbers, or C<undef>. In the former case, the number
is treated as an uncertainty which has the same magnitude in both
directions. (I.e. C<+/- x>) In case of an array reference, the first
number is treated as the upper error boundary and the second as the
lower boundary. (I.e. C<+x, -y>) C<undef> is treated as zero error.

=item *

The second way to create objects is passing a single string to the
constructor which is efficiently parsed into a number and any number
of errors. I'll explain the format with an example:

  133.14e-5 +/- .1e-4 + 0.00002 - 1.0e-5 +/- .2e-4

In this example, the first number is parsed as the actual number.
The following number is treated as a symmetric error (C<.1e-4>)
The two following numbers are treated as the upper and lower
boundary for a single error. Then comes another ordinary error.
It is also legal to define the lower boundary of an error before
the upper boundary. (I.e. C<-1.0e-5 +0.00002>)

Whitespace is insignificant.

For the sake of completeness, I'll mention the regular expression
that is used to match numbers. It's taken from the official Perl
FAQ to match floating point numbers:

  [+-]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee][+-]?\d+)?

Don't worry if you don't understand it. Just run a few tests to
see if it'll accept your numbers. Or go read C<perldoc -q float>
or pick up a book on C and read up on how they define floating
point numbers.

=back

Note that trailing zeros currently have no effect. (Yes, this is
a B<BUG>!)

The constructor returns a new object of this class or undef if
something went wrong.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto)||$proto;

  # clone
  if (ref($proto) and not @_) {
    my $num = $proto->{num};
    $num = $num->copy() if ref($num);
    my $err =  [];
    foreach (@{$proto->{errors}}) {
      push @$err, ref($_) eq 'ARRAY' ? [map {ref($_) ? $_->copy() : $_} @$_] : (ref($_) ? $_->copy() : $_)
    }
    return bless {num => $num, errors => $err} => $class;
  }

  return undef if not @_;

  my $num = shift;
  return undef if not defined $num;

  if (not @_) {
    return _parse_string($num, $class);
  }

  my $errors = [];
  my $self = {
    num => $num,
    errors => $errors,
  };
  bless $self => $class;


  while (@_) {
    my $err = shift;
    if (_ARRAY($err)) {
      if (@$err == 1) {
        push @$errors, CORE::abs($err->[0] || 0);
      }
      else {
        push @$errors, [CORE::abs($err->[0] || 0), CORE::abs($err->[1] || 0)];
      }
    }
    else {
      push @$errors, CORE::abs($err || 0);
    }
  }

  return $self;
}


# This parses a string into an object
sub _parse_string {
  my $str = shift;
  my $class = shift;

  return undef unless $str =~ /\G\s*($CFloat)/cgo;
  my $num = $1;
  my $err = [];
  while (1) {
    if ($str =~ /\G \s* \+ \s* \/ \s* \- \s* ($CFloat)/cgxo) {
      push @$err, CORE::abs($1);
    }
    elsif ($str =~ / \G \s* \+ \s* ($CFloat) \s* \- \s* ($CFloat)/cgxo) {
      push @$err,  [CORE::abs($1), CORE::abs($2)];
    }
    elsif ($str =~ /\G \s* \- \s* ($CFloat) \s* \+ \s* ($CFloat)/cgxo) {
      push @$err,  [CORE::abs($2), CORE::abs($1)];
    }
    else {
      last;
    }
  }
  return bless { num => $num, errors => $err } => $class;
}

=head2 new_big

This is an alternative constructor for C<Number::WithError>
objects. It works exactly like C<new> except that it makes all
internal numbers instances of C<Math::BigFloat> for high precision
calculations.

The module does not load C<Math::BigFloat> at compile time to avoid
loading a big module that isn't needed all the time. Instead, this
module makes use of the L<prefork> pragma and loads C<Math::BigFloat>
when needed at run-time.

=cut

sub new_big {
  my $obj = shift()->new(@_);

  return undef if not defined $obj;

  require Math::BigFloat;
  $obj->{num} = Math::BigFloat->new($obj->{num});

  foreach my $e (@{$obj->{errors}}) {
    if (_ARRAY0($e)) {
      @$e = map { Math::BigFloat->new($_) } @$e;
    }
    else {
      $e = Math::BigFloat->new($e);
    }
  }
  return $obj;
}


=head2 witherror

This constructor is B<not> a method. It is a subroutine that
can be exported to your namespace on demand. It works exactly
as the C<new()> method except it's a subroutine and shorter.

I'm normally not for this kind of shortcut in object-oriented
code, but if you have to create a large number of
C<Number::WithError> numbers, you'll appreciate it. Trust
me.

Note to authors of subclasses: If you inherit from this module,
you'll need to implement your own C<witherror()> because otherwise,
it will still return objects of this class, not your subclass.

=cut

sub witherror {  Number::WithError->new(@_) }


=head2 witherror_big

This is also B<not> a method. It does the same as C<witherror()>.
It can also be optionally be exported to your namespace.

It uses the C<new_big> constructor instead of the C<new>
constructor used by C<witherror()>.

=cut

sub witherror_big { Number::WithError->new_big(@_) }


# This is a helper routine which applies the code ref it
# expects as last argument to the rest of its arguments after
# making sure the second argument is an object.
sub _apply {
  my $self = shift;
  my $sub  = pop;
  my $obj;
  if ( _INSTANCE($_[0], 'Number::WithError') ) {
    $obj = shift;
  }
  else {
    my $obj = $self->new(@_);
  }
  return undef if not defined $obj;

  return $sub->($self, $obj, 0);
}


#########################################################

=head1 ARITHMETIC METHODS

All of these methods implement an arithmetic operation on the
object and the method's first parameter.

The methods aren't mutators. That means they don't modify the
object itself, but return the result of the operation as a
new object.

All of the methods accept either a plain number,
a C<Number::WithError> object or anything that
is understood by the constructors as argument,

All errors are correctly propagated using Gaussian Error
Propagation. The formulae used for this are mentioned in the
individual methods' documentation.

=head2 add

Adds the object B<a> and the argument B<b>. Returns a new object B<c>.

Formula: C<c = a + b>

Error Propagation: C<err_c = sqrt( err_a^2 + err_b^2 )>

=cut

sub add { push @_, \&_addition; goto &_apply; }

sub _addition {
  my $o1 = shift;
  my $o2 = shift;
  my $switch = shift;
  $o2 = $o1->new($o2) if not _INSTANCE($o2, 'Number::WithError');

  my $e1 = $o1->{errors};
  my $e2 = $o2->{errors};
  my $n1 = $o1->{num};
  my $n2 = $o2->{num};

  my $errs = [];
  my $res = {errors => $errs};

  $res->{num} = $n1 + $n2;

  my $l1 = $#$e1;
  my $l2 = $#$e2;
  my $len = $l1 > $l2 ? $l1 : $l2;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $le2 = $e2->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;
    my $ary2 = _ARRAY0 $le2;

    if (!$ary1 and !$ary2) {
      push @$errs, CORE::sqrt($le1**2 + $le2**2);
    }
    elsif ($ary1) {
      if ($ary2) {
        # both
        push @$errs, [ CORE::sqrt($le1->[0]**2 + $le2->[0]**2), CORE::sqrt($le1->[1]**2 + $le2->[1]**2) ];
      }
      else {
        # 1 not 2
        push @$errs, [ CORE::sqrt($le1->[0]**2 + $le2**2), CORE::sqrt($le1->[1]**2 + $le2**2) ];
      }
    }
    else {
      # $ary2 not 1
      push @$errs, [ CORE::sqrt($le1**2 + $le2->[0]**2), CORE::sqrt($le1**2 + $le2->[1]**2) ];
    }
  }

  if (not defined $switch) {
    $o1->{errors} = $errs;
    $o1->{num} = $res->{num};
    return $o1;
  }
  else {
    bless $res => ref($o1);
    return $res;
  }
}

#########################################################

=head2 subtract

Subtracts the argument B<b> from the object B<a>. Returns a new object B<c>.

Formula: C<c = a - b>

Error Propagation: C<err_c = sqrt( err_a^2 + err_b^2 )>

=cut

sub subtract { push @_, \&_subtraction; goto &_apply; }

sub _subtraction {
  my $o1 = shift;
  my $o2 = shift;
  $o2 = $o1->new($o2) if not _INSTANCE($o2, 'Number::WithError');

  my $switch = shift;

  my $e1 = $o1->{errors};
  my $e2 = $o2->{errors};
  my $n1 = $o1->{num};
  my $n2 = $o2->{num};

  my $errs = [];
  my $res = {errors => $errs};

  if ($switch) {
    ($n1, $n2) = ($n2, $n1);
    ($e1, $e2) = ($e2, $e1);
  }
  $res->{num} = $n1 - $n2;

  my $l1 = $#$e1;
  my $l2 = $#$e2;
  my $len = $l1 > $l2 ? $l1 : $l2;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $le2 = $e2->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;
    my $ary2 = _ARRAY0 $le2;

    if (!$ary1 and !$ary2) {
      push @$errs, CORE::sqrt($le1**2 + $le2**2);
    }
    elsif ($ary1) {
      if ($ary2) {
        # both
        push @$errs, [ CORE::sqrt($le1->[0]**2 + $le2->[0]**2), CORE::sqrt($le1->[1]**2 + $le2->[1]**2) ];
      }
      else {
        # 1 not 2
        push @$errs, [ CORE::sqrt($le1->[0]**2 + $le2**2), CORE::sqrt($le1->[1]**2 + $le2**2) ];
      }
    }
    else {
      # $ary2 not 1
      push @$errs, [ CORE::sqrt($le1**2 + $le2->[0]**2), CORE::sqrt($le1**2 + $le2->[1]**2) ];
    }
  }

  if (not defined $switch) {
    $o1->{errors} = $errs;
    $o1->{num} = $res->{num};
    return $o1;
  }
  else {
    bless $res => ref($o1);
    return $res;
  }
}

#########################################################

=head2 multiply

Multiplies the object B<a> and the argument B<b>. Returns a new object B<c>.

Formula: C<c = a * b>

Error Propagation: C<err_c = sqrt( b^2 * err_a^2 + a^2 * err_b^2 )>

=cut

sub multiply { push @_, \&_multiplication; goto &_apply; }

sub _multiplication {
  my $o1 = shift;
  my $o2 = shift;
  my $switch = shift;
  $o2 = $o1->new($o2) if not _INSTANCE($o2, 'Number::WithError');

  my $e1 = $o1->{errors};
  my $e2 = $o2->{errors};
  my $n1 = $o1->{num};
  my $n2 = $o2->{num};

  my $errs = [];
  my $res = {errors => $errs};

  $res->{num} = $n1 * $n2;

  my $l1 = $#$e1;
  my $l2 = $#$e2;
  my $len = $l1 > $l2 ? $l1 : $l2;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $le2 = $e2->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;
    my $ary2 = _ARRAY0 $le2;

    if (!$ary1 and !$ary2) {
      push @$errs, CORE::sqrt( ($n2*$le1)**2 + ($n1*$le2)**2 );
    }
    elsif ($ary1) {
      if ($ary2) {
        # both
        push @$errs, [ CORE::sqrt( ($n2*$le1->[0])**2 + ($n1*$le2->[0])**2), CORE::sqrt( ($n2*$le1->[1])**2 + ($n1*$le2->[1])**2) ];
      }
      else {
        # 1 not 2
        push @$errs, [ CORE::sqrt( ($n2*$le1->[0])**2 + ($n1*$le2)**2), CORE::sqrt( ($n2*$le1->[1])**2 + ($n1*$le2)**2) ];
      }
    }
    else {
      # $ary2 not 1
      push @$errs, [ CORE::sqrt( ($n2*$le1)**2 + ($n1*$le2->[0])**2), CORE::sqrt( ($n2*$le1)**2 + ($n1*$le2->[1])**2) ];
    }
  }

  if (not defined $switch) {
    $o1->{errors} = $errs;
    $o1->{num} = $res->{num};
    return $o1;
  }
  else {
    bless $res => ref($o1);
    return $res;
  }
}

#########################################################

=head2 divide

Divides the object B<a> by the argument B<b>. Returns a new object B<c>.

Formula: C<c = a / b>

Error Propagation: C<err-c = sqrt( err_a^2 / b^2 + a^2 * err_b^2 / b^4 )>

=cut

sub divide { push @_, \&_division; goto &_apply; }

sub _division {
  my $o1 = shift;
  my $o2 = shift;
  my $switch = shift;
  $o2 = $o1->new($o2) if not _INSTANCE($o2, 'Number::WithError');

  my $e1 = $o1->{errors};
  my $e2 = $o2->{errors};
  my $n1 = $o1->{num};
  my $n2 = $o2->{num};

  my $errs = [];
  my $res = {errors => $errs};

  if ($switch) {
    ($n1, $n2) = ($n2, $n1);
    ($e1, $e2) = ($e2, $e1);
  }

  $res->{num} = $n1 / $n2;

  my $l1 = $#$e1;
  my $l2 = $#$e2;
  my $len = $l1 > $l2 ? $l1 : $l2;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $le2 = $e2->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;
    my $ary2 = _ARRAY0 $le2;

    if (!$ary1 and !$ary2) {
      push @$errs, CORE::sqrt( ($le1/$n2)**2 + ($le2*$n1/$n2**2)**2 );
    }
    elsif ($ary1) {
      if ($ary2) {
        # both
        push @$errs, [ CORE::sqrt( ($le1->[0]/$n2)**2 + ($le2->[0]*$n1/$n2**2)**2), CORE::sqrt( ($le1->[1]/$n2)**2 + ($le2->[1]*$n1/$n2**2)**2) ];
      }
      else {
        # 1 not 2
        push @$errs, [ CORE::sqrt( ($le1->[0]/$n2)**2 + ($le2*$n1/$n2**2)**2), CORE::sqrt( ($le1->[1]/$n2)**2 + ($le2*$n1/$n2**2)**2) ];
      }
    }
    else {
      # $ary2 not 1
      push @$errs, [ CORE::sqrt( ($le1/$n2)**2 + ($le2->[0]*$n1/$n2**2)**2), CORE::sqrt( ($le1/$n2)**2 + ($le2->[1]*$n1/$n2**2)**2) ];
    }
  }

  if (not defined $switch) {
    $o1->{errors} = $errs;
    $o1->{num} = $res->{num};
    return $o1;
  }
  else {
    bless $res => ref($o1);
    return $res;
  }
}

###################################

=head2 exponentiate

Raises the object B<a> to the power of the argument B<b>. Returns a new object B<c>.
Returns C<undef> if B<a> is negative because the error cannot be propagated in that
case. (Can't take log of a negative value.)

Also, please have a look at the error propagation formula below. Exponentiation and
logarithms are operations that can become numerically unstable very easily.

Formula: C<c = a ^ b>

Error Propagation: C<err-c = sqrt( b^2 * a^(b-1) * err_a^2 + ln(a)^2 * a^b * err_b^2 )>

=cut

sub exponentiate { push @_, \&_exponentiation; goto &_apply; }

sub _exponentiation {
  my $o1 = shift;
  my $o2 = shift;
  my $switch = shift;
  $o2 = $o1->new($o2) if not _INSTANCE($o2, 'Number::WithError');

  my $e1 = $o1->{errors};
  my $e2 = $o2->{errors};
  my $n1 = $o1->{num};
  my $n2 = $o2->{num};

  my $errs = [];
  my $res = {errors => $errs};

  if ($switch) {
    ($n1, $n2) = ($n2, $n1);
    ($e1, $e2) = ($e2, $e1);
  }

  return undef if $n1 < 0;

  $res->{num} = $n1 ** $n2;

  my $l1 = $#$e1;
  my $l2 = $#$e2;
  my $len = $l1 > $l2 ? $l1 : $l2;

  my $sh1 = $n2*$n1**($n2-1);
  my $sh2 = CORE::log($n1)*$n1**$n2;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $le2 = $e2->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;
    my $ary2 = _ARRAY0 $le2;

    if (!$ary1 and !$ary2) {
      push @$errs, CORE::sqrt( ($sh1*$le1)**2 + ($sh2*$le2)**2 );
    }
    elsif ($ary1) {
      if ($ary2) {
        # both
        push @$errs, [ CORE::sqrt( ($sh1*$le1->[0])**2 + ($sh2*$le2->[0])**2), CORE::sqrt( ($sh1*$le1->[1])**2 + ($sh2*$le2->[1])**2) ];
      }
      else {
        # 1 not 2
        push @$errs, [ CORE::sqrt( ($sh1*$le1->[0])**2 + ($sh2*$le2)**2), CORE::sqrt( ($sh1*$le1->[1])**2 + ($sh2*$le2)**2) ];
      }
    }
    else {
      # $ary2 not 1
      push @$errs, [ CORE::sqrt( ($sh1*$le1)**2 + ($sh2*$le2->[0])**2), CORE::sqrt( ($sh1*$le1)**2 + ($sh2*$le2->[1])**2) ];
    }
  }

  if (not defined $switch) {
    $o1->{errors} = $errs;
    $o1->{num} = $res->{num};
    return $o1;
  }
  else {
    bless $res => ref($o1);
    return $res;
  }

}

###################################

=head1 METHODS FOR BUILTIN FUNCTIONS

These methods calculate functions of the object and return the result
as a new object.

=head2 sqrt

Calculates the square root of the object B<a> and returns the result as a new object B<c>.
Returns undef if B<a> is negative.

Formula: C<c = sqrt(a)>

Error Propagation: C<err-c = sqrt( err-a^2 / (2*sqrt(a))^2 ) = abs( err-a / (2*sqrt(a)) )>

=cut

sub sqrt {
  my $o1 = shift;

  my $e1 = $o1->{errors};
  my $n1 = $o1->{num};

  return undef if $n1 < 0;

  my $errs = [];
  my $res = {errors => $errs};

  $res->{num} = CORE::sqrt($n1);

  my $l1 = $#$e1;

  my $len = $#$e1;
  my $sh1 = 2*sqrt($n1);

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;

    if (!$ary1) {
      push @$errs, CORE::abs($le1 / $sh1);
    }
    else {
      push @$errs, [ CORE::abs($le1->[0] / $sh1), CORE::abs($le1->[1] / $sh1) ];
    }
  }

  bless $res => ref($o1);
  return $res;
}

######################################

=head2 log

Calculates the natural logarithm of an object B<a>. Returns a new object B<c>.
If B<a> is negative, the function returns undef.

Formula: C<c = log(a)>

Error Propagation: C<err-c = sqrt( err-a^2 / a^2 ) = abs( err-a / a )>

=cut

sub log {
  my $o1 = shift;

  my $e1 = $o1->{errors};
  my $n1 = $o1->{num};
  return undef if $n1 < 0;

  my $errs = [];
  my $res = {errors => $errs};

  $res->{num} = CORE::log($n1);

  my $l1 = $#$e1;

  my $len = $#$e1;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;

    if (!$ary1) {
      push @$errs, CORE::abs($le1 / $n1);
    }
    else {
      push @$errs, [ CORE::abs($le1->[0] / $n1), CORE::abs($le1->[1] / $n1) ];
    }
  }

  bless $res => ref($o1);
  return $res;
}

###################################

=head2 sin

Calculates the sine of the object B<a> and returns the result as a new object B<c>.

Formula: C<c = sin(a)>

Error Propagation: C<err-c = sqrt( cos(a)^2 * err-a^2 ) = abs( cos(a) * err-a )>

=cut

sub sin {
  my $o1 = shift;

  my $e1 = $o1->{errors};
  my $n1 = $o1->{num};

  my $errs = [];
  my $res = {errors => $errs};

  $res->{num} = CORE::sin($n1);

  my $l1 = $#$e1;

  my $sh1 = CORE::cos($n1);
  my $len = $#$e1;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;

    if (!$ary1) {
      push @$errs, CORE::abs($sh1 * $le1);
    }
    else {
      push @$errs, [ CORE::abs($sh1 * $le1->[0]), CORE::abs($sh1 * $le1->[1]) ];
    }
  }

  bless $res => ref($o1);
  return $res;
}

###################################

=head2 cos

Calculates the cosine of the object B<a> and returns the result as a new object B<c>.

Formula: C<c = cos(a)>

Error Propagation: C<err-c = sqrt( sin(a)^2 * err-a^2 ) = abs( sin(a) * err-a )>

=cut

sub cos {
  my $o1 = shift;

  my $e1 = $o1->{errors};
  my $n1 = $o1->{num};

  my $errs = [];
  my $res = {errors => $errs};

  $res->{num} = CORE::cos($n1);

  my $l1 = $#$e1;

  my $sh1 = CORE::sin($n1);
  my $len = $#$e1;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;

    if (!$ary1) {
      push @$errs, CORE::abs($sh1 * $le1);
    }
    else {
      push @$errs, [ CORE::abs($sh1 * $le1->[0]), CORE::abs($sh1 * $le1->[1]) ];
    }
  }

  bless $res => ref($o1);
  return $res;
}

###################################

=head2 tan

Calculates the tangent of the object B<a> and returns the result as a new object B<c>.

Formula: C<c = tan(a)>

Error Propagation: C<err-c = sqrt( err-a^2 / cos(a)^4 ) = abs( err-a / cos(a)^2 )>

Since there is no built-in C<tan()> function, this operation is not available via
the overloaded interface.

=cut

sub tan {
  my $o1 = shift;

  my $e1 = $o1->{errors};
  my $n1 = $o1->{num};

  my $errs = [];
  my $res = {errors => $errs};

  $res->{num} = _my_tan($n1);

  my $l1 = $#$e1;

  my $sh1 = 1 / CORE::cos($n1)**2;
  my $len = $#$e1;

  foreach (0..$len) {
    my $le1 = $e1->[$_] || 0;
    my $ary1 = _ARRAY0 $le1;

    if (!$ary1) {
      push @$errs, CORE::abs($le1 * $sh1);
    }
    else {
      push @$errs, [ CORE::abs($le1->[0] * $sh1), CORE::abs($le1->[1] * $sh1) ];
    }
  }

  bless $res => ref($o1);
  return $res;
}

=head2 abs

Calculates the absolute value of an object B<a>. Leaves the errors untouched. Returns a new
object B<c>.

Formula: C<c = abs(a)>

Error Propagation: C<err-c = err-a>

=cut

sub abs {
  my $self = shift;

  my $new = $self->new();
  $new->{num} = CORE::abs($new->{num});
  return $new;
}




###################################

=head1 ROUNDING, STRINGIFICATION AND OUTPUT METHODS

This section documents methods dealing with the extraction of data from
the object. The methods implement rounding of numbers, stringification
of the object and extracting meta information like the significant
digit.

=cut

=head2 number

Determines the significant digit using the C<significant_digit()> method,
rounds the number that the object C<number()> is called on represents
to that digit and returns the rounded number.

Regardless of the internal representation of the number, this returns
an unblessed string / an unblessed floating point number.

To gain access to the raw number representation
in the object, use the C<raw_number> method.

Either way, the number will be in scientific notation. That means the first
non-zero digit comes before the decimal point and following the decimal
point and any number of digits is an exponent in C<eXXX> notation.

=cut

sub number {
  my $self = shift;
  my $sig = $self->significant_digit();
  return round_a_number($self->{num}, $sig);
}


=head2 raw_number

This method returns the internal representation of the number in
the object. It does not round as appropriate. It does not clone
C<Math::BigFloat> objects either. So make sure you do that if
necessary!

=cut

sub raw_number {
  my $self = shift;
  return $self->{num};
}


=head2 round

This method determines the significant digit using the C<significant_digit()>
method. Then, it rounds the number represented by the object and all
associated errors to that digit.

Then, the method concatenates the number with its errors and returns the
resulting string. In case of symmetric errors, the string C<+/-> will
be prepended to the error. In case of asymmetric errors, a C<+> will
be prepended to the first/upper error component and a C<-> to the
second/lower error component.

Returns the previously described string.

=cut

sub round {
  my $self = shift;
  my $sig = $self->significant_digit();

  my $str = round_a_number($self->{num}, $sig);

  foreach my $err (@{$self->{errors}}) {
    if (ref($err) eq 'ARRAY' and @$err == 2) {
      $str .= ' + ' . round_a_number($err->[0], $sig) . ' - ' . round_a_number($err->[1], $sig);
    }
    elsif (ref($err) eq 'ARRAY') {
      $str .= ' +/- ' . round_a_number($err->[0], $sig);
    }
    else {
      $str .= ' +/- ' . round_a_number($err, $sig);
    }
  }
  return $str;
}



=head2 significant_digit

This method returns the significant digit of the number it is called
on as an integer. If the number has no errors or all errors are
C<undef> or zero, this method returns C<undef>.

The return value of this method is to be interpreted as follows:
If this method returns C<-5>, the significant digit is C<1 * 10**-5>
or C<0.00001>. If it returns C<3>, the significant digit is
C<1 * 10**3> or C<1000>. If it returns C<0>, the significant digit
is C<1>.

The return value is computed by the following algorithm:
The individual significant digit of a single error is:
Take the exponent of the first non-zero digit
in the error. The digit after this first non-zero digit is the
significant one.

This method returns the minimum of the individual significant digits of
all errors.

That means:

  5 +/- 0.0132 + 0.5 - 1

Will yield a return value of C<-3> since the first error has the lowest
significant digit.

This algorithm is also used for determining the significant digit for
rounding. It is extremely important that you realize this isn't
carved in stone. B<The way the significant digit is computed in the
presence of errors is merely a convention.> In this case, it stems
from particle physics. It might well be that
in your particular scientific community, there are other conventions.
One, for example, is to use the second non-zero digit only if the first
is a 1.

=cut

# Implementation for significant digit = first non-zero unless first non-zero==1
#sub significant_digit {
#  my $self = shift;
#
#  my $significant;
#  foreach my $err (map {ref($_) eq 'ARRAY' ? @$_ : $_} @{$self->{errors}}) {
#    my $sci = sprintf('%e', $err);
#    $sci =~ /^(.+)[eE]([+-]?\d+)$/ or die;
#    my $pre = $1;
#    my $exp = $2;
#    if ($pre !~ /[1-9]/) {
#      next;
#    }
#    elsif ($pre =~ /^[^1-9]*1/) {
#      $significant = $exp-1 if not defined $significant or $exp-1 < $significant;
#    }
#    else {
#      $significant = $exp if not defined $significant or $exp < $significant;
#    }
#  }
#  return defined($significant) ? 0+$significant : undef;
#}

sub significant_digit {
  my $self = shift;

  my $significant;
  foreach my $err (map {ref($_) eq 'ARRAY' ? @$_ : $_} @{$self->{errors}}) {
    my $sci = sprintf('%e', $err);
    $sci =~ /[eE]([+-]?\d+)$/ or die;
    my $exp = $1-1;
    $significant = $exp if not defined $significant or $exp < $significant;
  }
  return defined($significant) ? 0+$significant : undef;
}



=head2 error

This method returns a reference to an array of errors of the object it is
called on.

Unlike the C<raw_error()> method, this method takes proper care to copy
all objects and references to defy action at a distance. The structure
of the returned array reference is akin to that returned by
C<raw_error()>.

Furthermore, this method rounds all errors to the significant digit as
determined by C<significant_digit()>.

=cut

sub error{
  my $self = shift;
  my $sig = $self->significant_digit();

  my $errors = [];
  foreach my $err (@{$self->{errors}}) {
    if (ref($err) eq 'ARRAY' and @$err == 2) {
      push @$errors, [ round_a_number($err->[0], $sig), round_a_number($err->[1], $sig) ];
    }
    elsif (ref($err) eq 'ARRAY') {
      push @$errors, round_a_number($err->[0], $sig);
    }
    else {
      push @$errors, round_a_number($err, $sig);
    }
  }

  return $errors;
}



=head2 raw_error

Returns the internal representation of the errors of the current object.
Note that (just like C<raw_number()>, this does not clone the data for
safe use without action at a distance. Instead, it directly returns the
internal reference to the error structure.
The structure is an array of errors. Each error may either be a
string or floating point number or a C<Math::BigFloat> object or
an array reference. In case of an array reference, it is an
asymmetric error. The inner array contains two
strings/numbers/C<Math::BigFloat>s.

Note that this practically breaks encapsulation and code relying on it
might break with future releases.

=cut

sub raw_error{
  my $self = shift;
  return $self->{errors};
}

=head2 as_array

This method returns the information stored in the object as an array
(i.e. a list in this context)
which can be passed to the C<new()> method to recreate the object.

The first element of the return list will be the number itself. If the
object uses C<Math::BigFloat> for the internal representation, this
element will be a copy of the internal object. Otherwise, it will be the
internal representation of the number with full precision.

Following the number will be all errors either as numbers, C<Math::BigFloat>
objects or arrays containing two asymmetric errors. (Either as numbers or
objects as explained above.) The data returned by this method will be
copied deeply before being returned.

=cut

sub as_array {
  my $self = shift;
  my $copy = $self->new;
  return( $copy->{num}, @{$copy->{errors}} );
}


=head2 round_a_number

This is a helper B<function> which can round a number
to the specified significant digit (defined as
the return value of the C<significant_digit> method):

  my $rounded = round_a_number(12.01234567, -3);
  # $rounded is now 1.2012e01

=cut

sub round_a_number {
  my $number = shift;
  my $digit = shift;

  my $num = ref($number) ? $number->copy() : $number;

  return "$num" if not defined $digit;
  return "$num" if $num =~ /^nan$/i;

#  if (ref($num)) {
#    my $rounded = $num->ffround($digit, 'odd')->bsstr();
#    return $rounded;
#  }
#  else {
    my $tmp = sprintf('%e', $num);
    $tmp =~ /[eE]([+-]?\d+)$/
      or die "Error rounding number '$num'. Result '$tmp' was expected to match /[eE][+-]?·\\d+/!";

    my $exp = $1 - $digit;

    my ($bef, $aft);
    if ($exp >= 0) {
      my $res = sprintf('%.'.$exp.'e', $num);
      $res =~ /^([+-]?\d+|[+-]?\d*\.\d+)[eE]([+-]?\d+)$/ or die $res;
      $bef = $1;
      $aft = $2;
    }
    elsif ($exp <= -2) {
      $bef = 0;
      $aft = $digit;
    }
    else {
      # $exp == -1
      $num =~ /([1-9])/;
      if (not defined $1) {
        $bef = 0;
      }
      elsif ($1 >= 5) {
        $bef = $num < 0 ? -1 : 1;
      }
      else {
        $bef = 0;
      }
      $aft = $digit;
    }

    return "${bef}e$aft";
#  }
}



############################################

=head1 COMPARISON

This section lists methods that implement different comparisons between
objects.

=cut

=head2 numeric_cmp

This method implements a numeric comparison of two numbers.
It compares the object it is called on to the first argument
of the method. If the first argument is omitted or undefined,
the method returns C<undef>.

I<Numeric comparison> means in this case that the represented
numbers will be rounded and then compared. If you would like
a comparison that takes care of errors, please have a look at the
C<full_cmp()> method.

The method returns C<-1> if the rounded number represented by
the object is numerically less than the rounded number represented
by the first argument. It returns C<0> if they are equal and C<1>
if the object's rounded number is more than that of the argument.

This method implements the overloaded numeric comparison
operations.

=cut


sub numeric_cmp {
  my $self = shift;
  my $arg = shift;

  $arg = Number::WithError->new($arg) if not _INSTANCE($arg, 'Number::WithError');

  return undef if not defined $arg;

  my $n1 = $self->number();
  my $n2 = $arg->number();

  return $n1 <=> $n2;
}


=head2 full_cmp

This method implements a full comparison of two objects. That means,
it takes their numeric values, rounds them and compares them just like
the C<numeric_cmp()> method.

If, however, the numbers are equal, this method iterates over the errors,
rounds them and then compares them. If all errors are equal, this method
returns C<0>. If an error is found to differ, the method returns C<1> in
case the object's error is larger and C<-1> in case the argument's error is
larger.

Comparing an asymmetric error to a symmetric error is a special case.
It can never be the same error, hence the method will not return C<0>.
Instead, it guesses which error is larger by using the upper error bound
of the asymmetric error. (Well, yes, not very useful.)

=cut

sub full_cmp {
  my $self = shift;
  my $arg = shift;

  $arg = Number::WithError->new($arg) if not _INSTANCE($arg, 'Number::WithError');

  return undef if not defined $arg;

  my $numeq = $self->numeric_cmp($arg);


  # numbers differ or undef
  if ($numeq or not defined $numeq) {
    return $numeq;
  }

  my $sig1 = $self->significant_digit();
  my $sig2 = $arg->significant_digit();

  my $max = $#{$self->{errors}} > $#{$arg->{errors}} ? $#{$self->{errors}} : $#{$arg->{errors}};
  foreach my $no (0..$max) {
    my $e1 = $self->{errors}[$no];
    my $e2 = $arg->{errors}[$no];

    if (not defined $e1) {
      return -1 if defined $e2;
      next if not defined $e2;
    }
    elsif (not defined $e2) {
      return 1;
    }
    # else

    if (ref($e1) eq 'ARRAY') {
      if (not ref($e2) eq 'ARRAY') {
        my $res = _full_cmp_err($e1->[0], $sig1, $e2, $sig2);
        return $res if $res;
        return 1;
      }
      else {
        for my $i (0..$#$e1) {
          my $res = _full_cmp_err($e1->[$i], $sig1, $e2->[$i], $sig2);
          return $res if $res;
        }
        next;
      }
    }
    elsif (ref($e2) eq 'ARRAY') {
      my $res = _full_cmp_err($e1, $sig1, $e2->[1], $sig2);
      return $res if $res;
      return 1;
    }
    else {
      my $res = _full_cmp_err($e1, $sig1, $e2, $sig2);
      return $res if $res;
      next;
    }
  }

  return 0;
}

sub _full_cmp_err {
  my $e1 = shift;
  my $sig1 = shift;
  my $e2 = shift;
  my $sig2 = shift;

  my $r1 = round_a_number($e1, $sig1);
  my $r2 = round_a_number($e2, $sig2);

  return $r1 <=> $r2;
}

#################################


sub _num_eq {
  my $self = shift;
  my $arg = shift;
  my $switch = shift;
  if ($switch) {
    $arg = Number::WithError->new($arg) if not _INSTANCE($arg, 'Number::WithError');
    return $arg->numeric_cmp($self);
  }
  else {
    return $self->numeric_cmp($arg);
  }
}


sub _full_eq {
  my $self = shift;
  my $arg = shift;
  my $switch = shift;
  if ($switch) {
    $arg = Number::WithError->new($arg) if not _INSTANCE($arg, 'Number::WithError');
    return $arg->full_cmp($self);
  }
  else {
    return $self->full_cmp($arg);
  }
}

use overload
  '+' => \&_addition,
  '-' => \&_subtraction,
  '*' => \&_multiplication,
  '/' => \&_division,
  '**' => \&_exponentiation,
  '""' => \&round,
  '0+' => \&number,
  'bool' => \&number,
  'sin' => \&sin,
  'cos' => \&cos,
  'abs' => \&abs,
  'sqrt' => \&sqrt,
  'log' => \&log,
  '<=>' => \&_num_eq,
  'cmp' => \&_full_eq,
  ;

1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-WithError>

For other issues, contact the author.

=head1 SEE ALSO

You may use L<Math::BigFloat> with this module. Also, it should be possible to
use L<Math::Symbolic> to calculate larger formulas. Just assign a
C<Number::WithError> object to the C<Math::Symbolic> variables and it should
work.

You also possibly want to have a look at the L<prefork> pragma.

The test suite is implemented using the L<Test::LectroTest> module. In order to
keep the total test time in reasonable bounds, the default number of test attempts
to falsify the test properties is kept at a low number of 100. You can
enable more rigorous testing by setting the environment variable
C<PERL_TEST_ATTEMPTS> to a higher value. A value in the range of C<1500> to
C<3000> is probably a good idea, but takes a long time to test.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>, L<http://steffen-mueller.net/>

=head1 COPYRIGHT

Copyright 2006-2010 Steffen Mueller.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
