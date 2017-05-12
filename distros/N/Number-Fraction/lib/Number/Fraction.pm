
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

  my $f2 = Number::Fraction->new('1/2');

does the same thing but from a string constant.

  my $f3 = Number::Fraction->new($f1);

makes C<$f3> a copy of C<$f1>

  my $f4 = Number::Fraction->new; # 0/1

creates a fraction with a denominator of 0 and a numerator of 1.

If you use the alterative syntax of

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

=head2 Experimental Support for Exponentiation

Version 1.13 of Number::Fraction adds experimental support for exponentiation
operations. If a Number::Fraction object is used as the left hand operand of
an exponentiation expression then the value returned will be another
Number::Fraction object - if that makes sense. In all other cases, the
expression returns a real number.

Currently this only works if the right hand operand is an integer (or
a Number::Fraction object that has a denominator of 1). Later I hope to
extend this so support so that a Number::Fraction object is returned
whenever the result of the expression is a rational number.

For example:

  '1/2' ** 2 #   Returns a Number::Fraction ('1/4')
  '2/1' ** '2/1' Returns a Number::Fraction ('4/1')
  '2/1' ** '1/2' Returns a real number (1.414213)
   0.5  ** '2/1' Returns a real number (0.25)

=head2 Version 2: Now With Added Moose

Version 2 of Number::Fraction has been reimplemented using Moose. You should
see very little difference in the way that the class works. The only difference
I can see is that C<new> used to return C<undef> if it couldn't create a valid
object from its arguments, it now dies. If you aren't sure of the values that
are being passed into the constructor, then you'll want to call it within an
C<eval { ... }> block (or using something equivalent like L<Try::Tiny>).

=head1 METHODS

=cut

package Number::Fraction;

use 5.006;
use strict;
use warnings;

use Carp;
use Moose;

our $VERSION = '2.00';

use overload
  q("")    => 'to_string',
  '0+'     => 'to_num',
  '+'      => 'add',
  '*'      => 'mult',
  '-'      => 'subtract',
  '/'      => 'div',
  '**'     => 'exp',
  'abs'    => 'abs',
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
  overload::constant %_const_handlers if $_[1] and $_[1] eq ':constants';
}

=head2 unimport

Be a good citizen and uninstall constant handler when caller uses
C<no Number::Fraction>.

=cut

sub unimport {
  overload::remove_constant(q => undef);
}

has num => (
  is  => 'rw',
  isa => 'Int',
);

has den => (
  is  => 'rw',
  isa => 'Int',
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

=item *

Two integers which are used as the numerator and denominator of the
new object.

=item *

A single integer which is used as the numerator of the the new object.
The denominator is set to 1.

=item *

No arguments, in which case a numerator of 0 and a denominator of 1
are used.

=back

Dies if a Number::Fraction object can't be created.

=cut 

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;

  if (@_ >= 2) {
    die unless $_[0] =~ /^-?[0-9]+\z/ and $_[1] =~ /^-?[0-9]+\z/;

    return $class->$orig({ num => $_[0], den => $_[1] });
  } elsif (@_ == 1) {
    if (ref $_[0]) {
      if (UNIVERSAL::isa($_[0], $class)) {
        return $class->$orig({ num => $_[0]->{num}, den => $_[0]->{den} });
      } else {
        die "Can't make a $class from a ", ref $_[0];
      }
    } else {
      die unless $_[0] =~ m|^(-?[0-9]+)(?:/(-?[0-9]+))?\z|;

      return $class->$orig({ num => $1, den => ( defined $2 ? $2 : 1) });
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

  if ($self->{den} == 1) {
    return $self->{num};
  } else {
    return "$self->{num}/$self->{den}";
  }
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
another Number::Fraction object or a number. If the second argument is
an integer or a Number::Fraction object containing an integer then the
value returned is a Number::Fraction object, otherwise the value returned
is a real number.

=cut

sub exp {
  my ($l, $r, $rev) = @_;

  if ($rev) {
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
}

=head2 abs

Returns a copy of the given object with both the numerator and
denominator changed to positive values.

=cut

sub abs {
  my $self = shift;

  return (ref $self)->new(abs($self->{num}), abs($self->{den}));
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

1;
__END__

=head2 EXPORT

None by default.

=head1 SEE ALSO

perldoc overload

=head1 AUTHOR

Dave Cross, E<lt>dave@mag-sol.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-8 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
