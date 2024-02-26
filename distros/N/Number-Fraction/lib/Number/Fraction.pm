=encoding utf8

=head1 NAME

Number::Fraction - Perl extension to model fractions

=head1 SYNOPSIS

  use Number::Fraction;

  my $f1 = Number::Fraction->new(1, 2);
  my $f2 = Number::Fraction->new('1/2');
  my $f3 = Number::Fraction->new($f1); # clone
  my $f4 = Number::Fraction->new; # 0/1

or

  use Number::Fraction ':constants';

  my $f1 = '1/2';
  my $f2 = $f1;

  my $one = $f1 + $f2;
  my $half = $one - $f1;
  print $half; # prints '1/2'

or some famous examples from Ovid or the perldoc

  use Number::Fraction ':constants';

  print '0.1' + '0.2' - '0.3';
  # except for perl6, this is the usual suspect 5.55111512312578e-17
  # times the mass of the sun, this would be the size of Mount Everest
  # just a small rounding difference

  my $f1 = Number::Fraction->new(-6.725);
  my $f2 = Number::Fraction->new( 0.025);
  print int $f1/$f2;
  # the correct -269, no internal  -268.99999999999994315658

and as of the latest release with unicode support

  my $f1 = Number::Fraction->new('3½');
  my $f2 = Number::Fraction->new(4.33);

  my $f0 = $f1 * $f2;

  print $f0->to_simple; # 15⅙

and for those who love pie

  print '3.14159265359'->nearest(1 ..   10)->to_unicode_mixed  # 3¹⁄₇

  print '3.14159265359'->nearest(1 .. 1000)->to_unicode_string # ³⁵⁵⁄₁₁₃

=head1 ABSTRACT

Number::Fraction is a Perl module which allows you to work with fractions
in your Perl programs.

=head1 DESCRIPTION

Number::Fraction allows you to work with fractions (i.e. rational
numbers) in your Perl programs in a very natural way.

It was originally written as a demonstration of the techniques of
overloading.

If you use the module in your program in the usual way

  use Number::Fraction;

you can then create fraction objects using C<Number::Fraction->new> in
a number of ways.

  my $f1 = Number::Fraction->new(1, 2);

creates a fraction with a numerator of 1 and a denominator of 2.

  my $fm = Number::Fraction->new(1, 2, 3);

creates a fraction from an integer of 1, a numerator of 2 and a denominator
of 3; which results in a fraction of 5/3 since fractions are normalised.

  my $f2 = Number::Fraction->new('1/2');

does the same thing but from a string constant.

  my $f3 = Number::Fraction->new($f1);

makes C<$f3> a copy of C<$f1>

  my $f4 = Number::Fraction->new; # 0/1

creates a fraction with a denominator of 0 and a numerator of 1.

If you use the alternative syntax of

  use Number::Fraction ':constants';

then Number::Fraction will automatically create fraction objects from
string constants in your program. Any time your program contains a
string constant of the form C<\d+/\d+> then that will be automatically
replaced with the equivalent fraction object. For example

  my $f1 = '1/2';

Having created fraction objects you can manipulate them using most of the
normal mathematical operations.

  my $one = $f1 + $f2;
  my $half = $one - $f1;

Additionally, whenever a fraction object is evaluated in a string
context, it will return a string in the format x/y. When a fraction
object is evaluated in a numerical context, it will return a floating
point representation of its value.

Fraction objects will always "normalise" themselves. That is, if you
create a fraction of '2/4', it will silently be converted to '1/2'.

=head2 Mixed Fractions and Unicode Support

Since version 3.0 the interpretation of strings and constants has been
enriched with a few features for mixed fractions and Unicode characters.

Number::Fraction now recognises a more Perlish way of entering mixed
fractions which consist of an integer-part and a fraction in the form of
C<\d+_\d+/\d+>. For example

  my $mixed = '2_3/4'; # two and three fourths, stored as 11/4

or

  my $simple = '2½'; # two and a half, stored as 5/2

Mixed fractions, either in Perl notation or with Unicode fractions can
be negative, prepending it with a minus-sign.

  my $negative = '-⅛'; # minus one eighth

=head2 Experimental Support for Exponentiation

Version 1.13 of Number::Fraction adds experimental support for exponentiation
operations. Version 3 has extended support and returns a Number::Fraction.

It does a lot of cheating, but can give very useful results. And for now will
try to make a real number into a Number::Fraction if that real does not have a
power of ten component (like 1.234e45, thes numbers will simply fail). Such that

  ('5⅞' ** '1¼') ** '⅘'

will produce still the right fraction!

In a future version, I might use automatic rounding to a optional accuracy, so
that it also works for less forced examples as the above. One could still use
C<nearest> to find the nearest fraction to the result of the previous
computation.

For example:

  '1/2' ** 2 #   Returns a Number::Fraction ('1/4')
  '2/1' ** '2/1' Returns a Number::Fraction ('4/1')
  '2/1' ** '1/2' Returns a real number (1.414213)
   0.5  ** '2/1' Returns a Number::Fraction ('1/4')
   0.25 ** '1/2' Returns a Number::Fraction ('1/2')

=head2 Version 3: Now With Added Moo

Version 3 of Number::Fraction has been reimplemented using Moo. You should
see very little difference in the way that the class works. The only difference
I can see is that C<new> used to return C<undef> if it couldn't create a valid
object from its arguments, it now dies. If you aren't sure of the values that
are being passed into the constructor, then you'll want to call it within an
C<eval { ... }> block (or using something equivalent like L<Try::Tiny>).

=head1 METHODS

=cut

package Number::Fraction;

use 5.010;
use strict;
use warnings;

use Carp;
use Moo;
use Types::Standard qw/Int/;

our $VERSION = '3.1.0';

my $_mixed = 0;

our $MIXED_SEP = "\N{U+00A0}"; # NO-BREAK SPACE

use overload
  q("")    => 'to_string',
  '0+'     => 'to_num',
  '+'      => 'add',
  '*'      => 'mult',
  '-'      => 'subtract',
  '/'      => 'div',
  '**'     => 'exp',
  'abs'    => 'abs',
  '<'      => '_frac_lt',
  '>'      => '_frac_gt',
  '<=>'    => '_frac_cmp',
  fallback => 1;

my %_const_handlers = (
  q => sub {
    my $f = eval { __PACKAGE__->new($_[0]) };
    return $_[1] if $@;
    return $f;
  }
);

=head2 import

Called when module is C<use>d. Use to optionally install constant
handler.

=cut

sub import {
    my %args = map { $_ => 1 } @_;
    $_mixed = exists $args{':mixed'};
    overload::constant %_const_handlers if $args{':constants'};
}

=head2 unimport

Be a good citizen and uninstall constant handler when caller uses
C<no Number::Fraction>.

=cut

sub unimport {
  overload::remove_constant(q => undef);
  $_mixed = undef;
}

has num => (
  is  => 'rw',
  isa => Int,
);

has den => (
  is  => 'rw',
  isa => Int,
);

=head2 BUILDARGS

Parameter massager for Number::Fraction object. Takes the following kinds of
parameters:

=over 4

=item *

A single Number::Fraction object which is cloned.

=item *

A string in the form 'x/y' where x and y are integers. x is used as the
numerator and y is used as the denominator of the new object.

A string in the form 'a_b/c' where a,b and c are integers.
The numerator will be equal to a*c+b!
and c is used as the denominator of the new object.

=item *

Three integers which are used as the integer, numerator and denominator of the
new object.

In order for this to work in version 2.x,
one needs to enable 'mixed' fractions:

  use Number::Fractions ':mixed';

This will be the default behaviour in version 3.x;
when not enabled in version 2.x it will omit a warning to revise your code.

=item *

Two integers which are used as the numerator and denominator of the
new object.

=item *

A single integer which is used as the numerator of the the new object.
The denominator is set to 1.

=item *

No arguments, in which case a numerator of 0 and a denominator of 1
are used.

=item *

Note

As of version 2.1 it no longer allows for an array of four or more integer.
Before then, it would simply pass in the first two integers. Version 2.1 allows
for three integers (when using C<:mixed>) and issues a warning when more then
two parameters are passed.
Starting with version 3, it will die as it is seen as an error to pass invalid
input.

=back

Dies if a Number::Fraction object can't be created.

=cut

our @_vulgar_fractions = (
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+00BC}\z|, num=>1, den=>4},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+00BD}\z|, num=>1, den=>2},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+00BE}\z|, num=>3, den=>4},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+2153}\z|, num=>1, den=>3},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+2154}\z|, num=>2, den=>3},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+2155}\z|, num=>1, den=>5},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+2156}\z|, num=>2, den=>5},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+2157}\z|, num=>3, den=>5},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+2158}\z|, num=>4, den=>5},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+2159}\z|, num=>1, den=>6},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+215A}\z|, num=>5, den=>6},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+215B}\z|, num=>1, den=>8},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+215C}\z|, num=>3, den=>8},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+215D}\z|, num=>5, den=>8},
  {regexp=> qr|^(?<sign>-?)(?<int>[0-9]+)?\N{U+215E}\z|, num=>7, den=>8},
);

our %_vulgar_codepoints = (
    '1/4'   => "\N{U+00BC}",
    '1/2'   => "\N{U+00BD}",
    '3/4'   => "\N{U+00BE}",
    '1/3'   => "\N{U+2153}",
    '2/3'   => "\N{U+2154}",
    '1/5'   => "\N{U+2155}",
    '2/5'   => "\N{U+2156}",
    '3/5'   => "\N{U+2157}",
    '4/5'   => "\N{U+2158}",
    '1/6'   => "\N{U+2159}",
    '5/6'   => "\N{U+215A}",
    '1/8'   => "\N{U+215B}",
    '3/8'   => "\N{U+215C}",
    '5/8'   => "\N{U+215D}",
    '7/8'   => "\N{U+215E}",
);

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  if (@_ > 3) {
    croak "Revise your code: too many arguments will raise an exception";
  }
  if (@_ == 3) {
    if ( $_mixed ) {
      croak "integer, numerator and denominator need to be integers"
        unless $_[0] =~ /^-?[0-9]+\z/
           and $_[1] =~ /^-?[0-9]+\z/
           and $_[2] =~ /^-?[0-9]+\z/;

      return $class->$orig({ num => $_[0] * $_[2] + $_[1], den => $_[2] });
    }
    else {
      croak "Revise your code: 3 arguments is a mixed-fraction feature!";
    }
  }
  if (@_ >= 2) {
    croak "numerator and denominator both need to be integers"
      unless $_[0] =~ /^-?[0-9]+\z/ and $_[1] =~ /^-?[0-9]+\z/;
    # fix: regex string representation and the real number can be different
    my $num = sprintf( "%.0f", $_[0]);
    my $den = sprintf( "%.0f", $_[1]);
    return $class->$orig({ num => $num, den => $den });
  } elsif (@_ == 1) {
    if (ref $_[0]) {
      if (UNIVERSAL::isa($_[0], $class)) {
        return $class->$orig({ num => $_[0]->{num}, den => $_[0]->{den} });
      } else {
        croak "Can't make a $class from a ", ref $_[0];
      }
    }

    for (@_vulgar_fractions) { # provides $_->{num} and $_->{den}
      if ($_[0] =~ m/$_->{regexp}/ ) {
        return $class->$orig({
            num => (defined $+{int} ? $+{int} : 0) * $_->{den} + $_->{num},
            den => ($+{sign} eq '-') ? $_->{den} * -1 : $_->{den},
            }
        );
      }
    }

    # check for unicode mixed super/sub scripted strings
    if ($_[0] =~ m|
         ^
         (?<sign>-?)
         (?<int>[0-9]+)?
         (?<num>[\N{U+2070}\N{U+00B9}\N{U+00B2}\N{U+00B3}\N{U+2074}-\N{U+207B}]+)
         \N{U+2044} # FRACTION SLASH
         (?<den>[\N{U+2080}-\N{U+208B}]+)
         \z
         |x ) {
      my $num = _sup_to_basic($+{num});
      my $den = _sub_to_basic($+{den});
      return $class->$orig({
        num => (defined $+{int} ? $+{int} : 0) * $den + $num,
        den => ($+{sign} eq '-') ? $den * -1 : $den,
        }
      );
    }

    # check for floating point
    elsif ($_[0] =~ m|
        ^
        (?<sign>-?)
        (?<int>[0-9]+)?
        [.,] # yep, lets do bdecimal point or comma
        (?<num>[0-9]+)
        \z
        |x ) {
      my $num = $+{num};
      my $den = 10 ** length($+{num});
      return $class->$orig({
        num => (defined $+{int} ? $+{int} : 0) * $den + $num,
        den => ($+{sign} eq '-') ? $den * -1 : $den,
        }
      );
    }

    if ($_[0] =~ m|^(-?)([0-9]+)[_ \N{U+00A0}]([0-9]+)/([0-9]+)\z|) {
        return $class->$orig({
          num => $2 * $4 + $3,
          den=> ($1 eq '-') ? $4 * -1 : $4}
        );
    } elsif ($_[0] =~ m|^(-?[0-9]+)(?:/(-?[0-9]+))?\z|) {
        return $class->$orig({ num => $1, den => ( defined $2 ? $2 : 1) });
    } else {
        croak "Can't make fraction out of $_[0]\n";
    }
  } else {
    return $class->$orig({ num => 0, den => 1 });
  }
};

=head2 BUILD

Object initialiser for Number::Fraction. Ensures that fractions are in a
normalised format.

=cut

sub BUILD {
  my $self = shift;
  croak "Denominator can't be equal to zero" if $self->{den} == 0;
  $self->_normalise;
}

sub _normalise {
  my $self = shift;

  my $hcf = _hcf($self->{num}, $self->{den});

  for (qw/num den/) {
    $self->{$_} /= $hcf;
  }

  if ($self->{den} < 0) {
    for (qw/num den/) {
      $self->{$_} *= -1;
    }
  }
}

=head2 to_string

Returns a string representation of the fraction in the form
"numerator/denominator".

=cut

sub to_string {
  my $self = shift;

  return $self->{num} if $self->{den} == 1;
  return $self->{num} . '/' . $self->{den};
}


=head2 to_mixed

Returns a string representation of the fraction in the form
"integer numerator/denominator".

=cut

sub to_mixed {
  my $self = shift;

  return $self->{num} if $self->{den} == 1;

  my $sgn = $self->{num} * $self->{den} < 0 ? '-' : '';
  my $abs = $self->abs;
  my $int = int($abs->{num} / $abs->{den});
  $int = $int ? $int . $MIXED_SEP : '';

  return $sgn . $int . $abs->fract->to_string;
}


=head2 to_unicode_string

Returns a string representation of the fraction in the form
"superscript numerator / subscript denominator".
A Unicode 'FRACTION SLASH' is used instead of a normal slash.

=cut

sub to_unicode_string {
  return _to_unicode(shift->to_string);
}


=head2 to_unicode_mixed

Returns a string representation of the fraction in the form
"integer superscript numerator / subscript denominator".
A Unicode 'FRACTION SLASH' is used instead of a normal slash.

=cut

sub to_unicode_mixed {
  return _to_unicode(shift->to_mixed);
}


=head2 to_halfs

=head2 to_quarters

=head2 to_eighths

=head2 to_thirds

=head2 to_sixths

=head2 to_fifths

Returns a string representation as a mixed fraction, rounded to the nearest
possible 'half', 'quarter' ... and so on.

=cut

sub to_halfs    { return shift->to_simple(2) }

sub to_thirds   { return shift->to_simple(3) }

sub to_quarters { return shift->to_simple(4) }

sub to_fifths   { return shift->to_simple(5) }

sub to_sixths   { return shift->to_simple(6) }

sub to_eighths  { return shift->to_simple(8) }

# Typo retained for backwards compatibility
sub to_eights   { return shift->to_eighths }

=head2 to_simple

Returns a string representation as a mixed fraction, rounded to the nearest
possible to any of the above mentioned standard fractions. NB ⅐, ⅑ or ⅒ are not
being used.

Optionally, one can pass in a list of well-known denominators (2, 3, 4, 5, 6, 8)
to choose which fractions can be used.

=cut

sub to_simple {
  my $self = shift;
  my @denominators = @_;

  @denominators = ( 2, 3, 4, 5, 6, 8) unless @denominators;

  my $near = $self->nearest(@denominators);

  return $near->{num} if $near->{den} == 1;

  my $sgn = $near->{num} * $near->{den} < 0 ? '-' : '';
  my $abs = $near->abs;
  my $key = $abs->fract->to_string;
  my $frc = $_vulgar_codepoints{$key};
  unless ( $frc ) {
    carp "not a recognised unicode fraction symbol [$key]\n";
    return $near->to_unicode_mixed;
  }
  my $int = int($abs->{num} / $abs->{den}) || '';

  return $sgn . $int . $frc;
}

=head2 to_num

Returns a numeric representation of the fraction by calculating the sum
numerator/denominator. Normal caveats about the precision of floating
point numbers apply.

=cut

sub to_num {
  my $self = shift;

  return $self->{num} / $self->{den};
}

=head2 add

Add a value to a fraction object and return a new object representing the
result of the calculation.

The first parameter is a fraction object. The second parameter is either
another fraction object or a number.

=cut

sub add {
  my ($l, $r, $rev) = @_;

  if (ref $r) {
    if (UNIVERSAL::isa($r, ref $l)) {
      return (ref $l)->new($l->{num} * $r->{den} + $r->{num} * $l->{den},
                           $r->{den} * $l->{den});
    } else {
      croak "Can't add a ", ref $l, " to a ", ref $l;
    }
  } else {
    if ($r =~ /^[-+]?\d+$/) {
      return $l + (ref $l)->new($r, 1);
    } else {
      return $l->to_num + $r;
    }
  }
}

=head2 mult

Multiply a fraction object by a value and return a new object representing
the result of the calculation.

The first parameter is a fraction object. The second parameter is either
another fraction object or a number.

=cut

sub mult {
  my ($l, $r, $rev) = @_;

  if (ref $r) {
    if (UNIVERSAL::isa($r, ref $l)) {
      return (ref $l)->new($l->{num} * $r->{num},
                           $l->{den} * $r->{den});
    } else {
      croak "Can't multiply a ", ref $l, " by a ", ref $l;
    }
  } else {
    if ($r =~ /^[-+]?\d+$/) {
      return $l * (ref $l)->new($r, 1);
    } else {
      return $l->to_num * $r;
    }
  }
}

=head2 subtract

Subtract a value from a fraction object and return a new object representing
the result of the calculation.

The first parameter is a fraction object. The second parameter is either
another fraction object or a number.

=cut

sub subtract {
  my ($l, $r, $rev) = @_;

  if (ref $r) {
    if (UNIVERSAL::isa($r, ref $l)) {
      return (ref $l)->new($l->{num} * $r->{den} - $r->{num} * $l->{den},
                           $r->{den} * $l->{den});
    } else {
      croak "Can't subtract a ", ref $l, " from a ", ref $l;
    }
  } else {
    if ($r =~ /^[-+]?\d+$/) {
      $r = (ref $l)->new($r, 1);
      return $rev ? $r - $l : $l - $r;
    } else {
      return $rev ? $r - $l->to_num : $l->to_num - $r;
    }
  }
}

=head2 div

Divide a fraction object by a value and return a new object representing
the result of the calculation.

The first parameter is a fraction object. The second parameter is either
another fraction object or a number.

=cut

sub div {
  my ($l, $r, $rev) = @_;

  if (ref $r) {
    if (UNIVERSAL::isa($r, ref $l)) {
      die "FATAL ERROR: Division by zero" if $r->{num} == 0;
      return (ref $l)->new($l->{num} * $r->{den},
                           $l->{den} * $r->{num});
    } else {
      croak "Can't divide a ", ref $l, " by a ", ref $l;
    }
  } else {
    if ($r =~ /^[-+]?\d+$/) {
      $r = (ref $l)->new($r, 1);
      return $rev ? $r / $l : $l / $r;
    } else {
      return $rev ? $r / $l->to_num : $l->to_num / $r;
    }
  }
}

=head2 exp

Raise a Number::Fraction object to a power.

The first argument is a number fraction object. The second argument is
another Number::Fraction object or a number. It will try to compute another new
Number::Fraction object. This may fail if either numerator or denominator of the
new one are getting too big. In such case the value returned is a real number.

=cut

sub exp {
  my ($l, $r, $rev) = @_;

  if ($rev) {
    my $f = eval {
      (ref $l)->new($r)
    };
    return $f ** $l unless $@;
    return $r ** $l->to_num;
  }

  if (UNIVERSAL::isa($r, ref $l)) {
    if ($r->{den} == 1) {
      return $l ** $r->to_num;
    } else {
      return $l->to_num ** $r->to_num;
    }
  } elsif ($r =~ /^[-+]?\d+$/) {
    return (ref $l)->new($l->{num} ** $r, $l->{den} ** $r);
  } else {
    croak "Can't raise $l to the power $r\n";
  }

  my $expn = UNIVERSAL::isa($r, ref $l) ? $r->to_num : $r;
  my $pure = eval {
    # this is cheating, works when numerator and denominator look like integers
    (ref $l)->new( $l->{num} ** $expn, $l->{den} ** $expn )
  };
  return $pure unless $@;
  my $real = eval { $l->to_num ** $expn }; # real errors, like $expn is NaN
  croak "Can't raise $l to the power $r\n" if $@;
  my $fake = eval { (ref $l)->new($real) }; # overflow from int to float
  return $fake unless $@;
  return $real;
}

=head2 abs

Returns a copy of the given object with both the numerator and
denominator changed to positive values.

=cut

sub abs {
  my $self = shift;

  return (ref $self)->new(abs($self->{num}), abs($self->{den}));
}

=head2 fract

Returns the fraction part of a Number::Fraction object as a new
Number::Fraction object.

=cut

sub fract {
  my $self = shift;

  my $num = ($self->{num} <=> 0) * (CORE::abs($self->{num}) % $self->{den});
  return (ref $self)->new($num, $self->{den});
}


=head2 int

Returns the integer part of a Number::Fraction object as a new
Number::Fraction object.

=cut

sub int {
  my $self = shift;

  return (ref $self)->new(CORE::int($self->{num}/$self->{den}), 1);
}

# _frac_lt does the 'right thing' instead of numifying the fraction, it does
# what basic arithmetic dictates, make the denominators the same!
#
# one could forge fractions that would lead to bad floating points

sub _frac_lt {
  my ($l, $r, $rev ) = @_;
  my ($l_cnt, $r_cnt);
  if (UNIVERSAL::isa($r, ref $l)) {
    $l_cnt = $l->{num} * CORE::abs $r->{den} * ($l->{den} <=> 0);
    $r_cnt = $r->{num} * CORE::abs $l->{den} * ($r->{den} <=> 0);
  } else {
    $l_cnt = $l->{num} *         1           * ($l->{den} <=> 0);
    $r_cnt = $r        * CORE::abs $l->{den} * ($r        <=> 0);
  }
  return ( $l_cnt <  $r_cnt ) unless $rev;
  return ( $l_cnt >= $r_cnt );
}

sub _frac_gt {
  my ($l, $r, $rev ) = @_;
  my ($l_cnt, $r_cnt);
  if (UNIVERSAL::isa($r, ref $l)) {
    $l_cnt = $l->{num} * CORE::abs $r->{den} * ($l->{den} <=> 0);
    $r_cnt = $r->{num} * CORE::abs $l->{den} * ($r->{den} <=> 0);
  } else {
    $l_cnt = $l->{num} *         1           * ($l->{den} <=> 0);
    $r_cnt = $r        * CORE::abs $l->{den} * ($r        <=> 0);
  }
  return ( $l_cnt >  $r_cnt ) unless $rev;
  return ( $l_cnt <= $r_cnt );
}

sub _frac_cmp {
  return -1 if _frac_lt(@_);
  return +1 if _frac_gt(@_);
  return  0;
} # _frac_cmp

=head2 nearest

Takes a list of integers and creates a new Number::Fraction object nearest to
a fraction with a deniminator from that list.

=cut

sub nearest {
  my $self = shift;
  return $self if $self->{den} ==1;
  my @denominators = @_;
  die "Missing list of denominators" if not @denominators;

  my $frc = (ref $self)->new;
  foreach my $den ( @denominators ) {
    my $num = sprintf( "%.0f", $self->mult($den) );
    if ( (
      CORE::abs( $self->{num}*$frc->{den} - $frc->{num}*$self->{den} ) * $den
      -
      CORE::abs( $self->{num}*$den - $num*$self->{den} ) * $frc->{den}
      ) > 0 ) {
        $frc->{num} = $num;
        $frc->{den} = $den;
    }
  }
  return $frc;
}

sub _hcf {
  my ($x, $y) = @_;

  ($x, $y) = ($y, $x) if $y > $x;

  return $x if $x == $y;

  while ($y) {
    ($x, $y) = ($y, $x % $y);
  }

  return $x;
}

# translating back and forth between basic digits and sup- or sub-script

sub _sup_to_basic {
  $_ = shift;
  tr/\N{U+2070}\N{U+00B9}\N{U+00B2}\N{U+00B3}\N{U+2074}-\N{U+207E}/0-9+\-=()/;
  return $_;
}

sub _sub_to_basic {
  $_ = shift;
  tr/\N{U+2080}-\N{U+208E}/0-9+\-=()/;
  return $_;
}

sub _basic_to_sup {
  $_ = shift;
  tr/0123456789+\-=()/\N{U+2070}\N{U+00B9}\N{U+00B2}\N{U+00B3}\N{U+2074}\N{U+2075}\N{U+2076}\N{U+2077}\N{U+2078}\N{U+2079}\N{U+207A}\N{U+207B}\N{U+207C}\N{U+207D}\N{U+207E}/;
  return $_;
}

sub _basic_to_sub {
  $_ = shift;
  tr/0123456789+\-=()/\N{U+2080}\N{U+2081}\N{U+2082}\N{U+2083}\N{U+2084}\N{U+2085}\N{U+2086}\N{U+2087}\N{U+2088}\N{U+2089}\N{U+208A}\N{U+208B}\N{U+208C}\N{U+208D}\N{U+208E}/;
  return $_;
}

# turn a basic string into one using sup- and sub-script characters
sub _to_unicode {
  if ($_[0] =~ m|^(?<sign>-?)(?<num>\d+)/(?<den>\d+)$|) {
    my $num = _basic_to_sup($+{num});
    my $den = _basic_to_sub($+{den});
    return ($+{sign} ? "\N{U+207B}" : '') . $num . "\N{U+2044}" . $den;
  }
  if ($_[0] =~ m|^(?<sign>-?)(?<int>\d+)$MIXED_SEP(?<num>\d+)/(?<den>\d+)$|) {
    my $num = _basic_to_sup($+{num});
    my $den = _basic_to_sub($+{den});
    return $+{sign} . $+{int} . $num . "\N{U+2044}" . $den;
  }
  if ($_[0] =~ m|^(?<sign>-?)(?<int>\d+)$|) {
    return $+{sign} . $+{int}; # Darn, this is just what we got!
  }
  return;
}

1;
__END__

=head2 EXPORT

None by default.

=head1 SEE ALSO

perldoc overload

L<Lingua::EN::Fractions>

=head1 AUTHOR

Dave Cross, E<lt>dave@mag-sol.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-20 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

