package Quantum::ClebschGordan;

use strict;
use warnings;

use base qw(Class::Accessor);

use Number::Fraction;
use Memoize;  # for factorial()
use Carp;

our $VERSION = '0.01';

our @STATE_VARS = qw/ j1 j2 m m1 m2 j /;
__PACKAGE__->mk_accessors( @STATE_VARS, '__coeff' );

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $p = { @_ };
  my $obj = bless {}, $class;
  foreach my $var ( @STATE_VARS ){
    $obj->set($var, $p->{$var} ) if exists $p->{$var};
  }
  return $obj;
}

sub set {
  my ($self, $key) = splice(@_, 0, 2);
  my @args = @_;
  my $settingStateVar = grep($key eq $_, @STATE_VARS) ? 1 : 0;
  if( $settingStateVar && scalar(@args) && defined $args[0] && ref($args[0]) ne 'Number::Fraction' ){
    my $v = Number::Fraction->new($args[0]);
    $args[0] = $v if defined $v;
  } 
  my $prev = $self->get($key);
  $self->SUPER::set($key, @args);
  if( $settingStateVar ){
    if( ! $self->__check_state ){
      $self->SUPER::set( $key, $prev );  # restore just in case this error is being trapped.
      croak "setting '$key' to " . join(",",@args) . " causes invalid state: " . join(',',@STATE_VARS) . " = " . join(',',map { defined $_ ? $_ : '' } $self->get(@STATE_VARS));
    }
    $self->__set_coeff();
  }
}

sub __check_state {
  # return undef on error
  # return 1 if all complete & valid
  # return -1 if incomplete but the parts given are valid
  my $self = shift;
  my ($j1, $j2, $m, $m1, $m2, $j) = $self->get(qw/j1 j2 m m1 m2 j/);
  carp("j1 is required") && return unless $j1;
  carp("j1 '$j1' is invalid (must be multiple of 1/2 and > 0)") && return unless $j1 > 0 && ($j1*2) == int ($j1*2);
  return -1 unless defined $j2;
  carp("j2 must be <= j1") && return unless $j2 <= $j1;
  carp("j2 '$j2' is invalid (must be multiple of 1/2 and > 0)") && return unless $j2 > 0 && $j2*2 == int $j2*2;
  return -1 unless defined $m;
  carp("m '$m' is not in range") && return unless -($j1+$j2) <= $m && $m <= ($j1+$j2);
  carp("m '$m' isn't valid in range") && return unless grep {$m == $_} map {-($j1+$j2) + $_} 0 .. 2*($j1+$j2);
  return -1 unless defined $m1;
  carp("m1 '$m1' is not in range") && return unless -$j1 <= $m1 && $m1 <= $j1;
  carp("m1 '$m1' isn't valid in range") && return unless grep {$m1 == $_} map {-$j1 + $_} 0 .. 2*$j1;
  return -1 unless defined $m2;
  carp("m2 '$m2' is not in range") && return unless -$j2 <= $m2 && $m2 <= $j2;
  carp("m2 '$m2' isn't valid in range") && return unless grep {$m2 == $_} map {-$j2 + $_} 0 .. 2*$j2;
  carp("m1+m2 != m for m=$m, m1=$m1, m2=$m2") && return unless $m == $m1 + $m2;
  return -1 unless defined $j;
  carp("j '$j' is not in range") && return unless abs($m) <= $j && $j <= $j1+$j2;
  carp("j '$j' isn't valid in range") && return unless grep {$j == $_} map {abs($m) + $_} 0 .. ($j1+$j2)-abs($m);
  return 1;
}

sub __seq {
  my ($start, $end, $iter) = @_;
  $iter = 1 if ! defined $iter;
  croak "'$iter' is not > 0" unless $iter && $iter > 0;
  $iter *= -1 if $start > $end;
  my $i = $start;
  my @list;
  push(@list, $i), $i+=$iter while ( ($iter>0) ? ($i <= $end) : ($i>= $end) );
  return @list;
}

# j1, j2
#  m = (j1+j2 down to -j1-j2)  by 1
#	2j+1 possibilities
#   m = m1 + m2
#   m1 = j1 .. -j1  by 1
#   m2 = j2 .. -j2  by 1
#  j = (j1+j2 down to abs(j1-j2) ) by 1
#  (2j1+1)(2j2+1) number of (j,m) pairs
#    j = j1+j2 down to abs(m)

sub explode {
  my $self = shift;
  croak "bad values" && return unless $self->__check_state;;
  my $j1 = $self->j1;
  my @j2 = defined $self->j2 ? ( $self->j2 ) : __seq(0.5, $j1, 0.5);
  my @coeffObjs;
  foreach my $j2 ( @j2 ){
    my @m = defined $self->m ? ( $self->m ) : __seq( $j1+$j2, -($j1+$j2) );
    my @m1 = defined $self->m1 ? ( $self->m1 ) : __seq( $j1, -$j1 );
    my @m2 = defined $self->m2 ? ( $self->m2 ) : __seq( $j2, -$j2 );
    foreach my $m ( @m ){
      my @j = defined $self->j ? ( $self->j ) : __seq( $j1+$j2, abs($m) );
      foreach my $m1 ( @m1 ){
        foreach my $m2 ( @m2 ){
          next unless $m == $m1 + $m2;
	  foreach my $j ( @j ){
#warn "j1 => $j1, j2 => $j2, m => $m, m1 => $m1, m2 => $m2, j => $j";
	    my $x = Quantum::ClebschGordan->new( j1 => $j1, j2 => $j2, m => $m, m1 => $m1, m2 => $m2, j => $j );
	    push @coeffObjs, $x;
#	    printf "%6s %6s %6s %6s %6s %6s %6s\n", $x->get(@STATE_VARS), $x->coeff;
	  }
        }
      }
    }
  }
  return @coeffObjs;
}

sub state_names {
  my $self = shift;
  return @STATE_VARS;
}

sub state_nums {
  my $self = shift;
  return $self->get(@STATE_VARS);
}

sub state_values {
  my $self = shift;
  return map { ref($_) eq 'Number::Fraction' ? $_->to_num : $_ } $self->get(@STATE_VARS);
}

memoize('factorial');
sub factorial {
  my $n = shift;
  return undef unless defined $n && $n =~ /^\d+$/; # non-negative integers only
  return 1 if $n == 0;
  return $n*factorial($n-1);
}


# From http://string.howard.edu/~tristan/QM2/QM2WE.pdf
#   "Addition of Angular Momenta, Clebsch-Gordan Coefficients and the Wigner-Eckart Theorem"
#   Section: '1.3. Clebsch-Gordan Coefficients'
#   Equations:
#     1.18a)	c(j,m, j1,j2,m1,m2) = delta(m,m1+m2) * rho(j, j1,j2) * sigma * tau
#     1.18b)	delta(m,m1+m2) =  (m==m1+m2) ? 1 : 0
#     1.18c)	rho = sqrt( (j1+j2-j)! * (j+j1-j2)! * (j2+j-j1)! * (2*j+1) / (j1+j2+j+1)! )
#     1.18d)	sigma = sqrt( (j+m)!*(j-m)!*(j1+m1)!*(j1-m1)!*(j2+m2)!*(j2-m2)! )
#     1.18e)	tau = SUM( -1^r / ( (j1-m1-r)! (j2+m2-r)! (j-j2+m1+r)! (j-j1-m2+r)! (j1+j2-j-r)! r! ) )
# 	note: 0! = 1; (-n)! = Gamma(1-n) = infinity for n = 1,2,...

sub __set_coeff {
  my $self = shift;
  $self->__coeff(undef);
  return unless $self->__check_state == 1;
  my ( $j1, $j2, $m, $m1, $m2, $j ) = $self->get( qw/ j1 j2 m m1 m2 j / );
  my $rho_squared_num = factorial($j1+$j2-$j) * factorial($j+$j1-$j2) * factorial($j2+$j-$j1) * (2*$j+1);
  my $rho_squared_den = factorial($j1+$j2+$j+1);
  my $sigma_squared = factorial($j+$m)*factorial($j-$m)*factorial($j1+$m1)*factorial($j1-$m1)*factorial($j2+$m2)*factorial($j2-$m2);

  # We'll store everything as a fraction to avoid floating point rounding errors.
  my $tau = Number::Fraction->new(0);
  # The sum over 4 is infinite, but for r's above this all the terms will be
  # zero (see note for equation 1.18e).
  my $r_max = 2*(abs($j)+abs($j1)+abs($j2)+abs($m1)+abs($m2));
  foreach my $r ( 0 .. $r_max ){
    my $denom;
    my @factorials = ( $j1-$m1-$r, $j2+$m2-$r, $j-$j2+$m1+$r, $j-$j1-$m2+$r, $j1+$j2-$j-$r, $r );
    foreach my $n ( @factorials ){
      my $n_factorial = factorial($n);
      undef $denom, last unless $n_factorial; # (-n)! is 1/0i (i.e. undef), so skip this term
      $denom = 1 unless defined $denom; # set to 1 the first time through.
      $denom *= $n_factorial;
    }
    next unless $denom;
    $tau += Number::Fraction->new( (-1)**$r , $denom );
  }
  # We want:
  # c(j,m, j1,j2,m1,m2) = delta(m,m1+m2) * rho(j, j1,j2) * sigma * tau
  #	= rho(j, j1,j2) * sigma * tau      # we've already bailed if delta=0
  #	= sign * sqrt( rho_squared * sigma_squared * tau * tau )
  #		where sign = sign(tau) ; we know rho & sigma are > 0
  #	= sign * sqrt( tau * tau * rho_squared * sigma_squared )  # flip to keep Number::Fraction objects
  #	= sign * sqrt( tau * tau * sigma_squared * rho_squared_num / rho_squared_den )
  my $sq = ($tau < 0 ? -1 : 1) * $tau * $tau * $sigma_squared * $rho_squared_num / $rho_squared_den;

  # still have a Number::Fraction object because of operator overloads.
  $self->__coeff( $sq->to_string );  # notation form
  
  return $self->coeff;
}

sub coeff {
  my $self = shift;
  return $self->__coeff;
}

sub coeff_value {
  my $self = shift;
  return notation2real( $self->__coeff );
}

sub notation2real {
  my $n = shift;
  $n or return $n; # covers 0, undef, ''
  $n = Number::Fraction->new( $n ) || $n;
  $n = $n->to_num if ref($n) eq 'Number::Fraction';
  my $sign = $n < 0 ? -1 : 1;
  return $sign * sqrt( abs($n) );
}

sub real2notation {
  my $x = shift;
  $x or return $x; # covers 0, undef, ''
  $x = $x->to_num if ref($x) eq 'Number::Fraction';
  my $sign = $x < 0 ? -1 : 1;
  my $multiplier = 10*9*8*7*6*5*4*3*2;
  $x = sprintf "%d", sprintf("%.4f",$x*$x*$multiplier);
  return $sign * Number::Fraction->new( $x, 1 ) / $multiplier;
}

sub wigner3j {
  my $self = shift;
  my $c = $self->coeff;
  return unless $self->__check_state() == 1;
  return $c unless $c;  # 0 or undef;
  $c = Number::Fraction->new($c) || $c;
  # (j1j2m1m2|j1j2m) = (-1)^(-j1+j2-m) * sqrt(2j+1) * Wigner(j1 j2 j, m1 m2 -m)
  my $power = -$self->j1 + $self->j2 - $self->m;
  $power = $power->to_num if ref($power) eq 'Number::Fraction';
  $c /= (-1)**( $power );
  my $sign = $c < 0 ? -1 : 1;
  $c /= 2*$self->j + 1;
  return $c;
}

sub wigner3j_value {
  my $self = shift;
  return notation2real( $self->wigner3j );
}

=head1 NAME

Quantum::ClebschGordan - Calculate/list Clebsch-Gordan Coefficients

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Calculate Clebsch-Gordan coefficients.

Commandline utility:

    [davidrw@devbox davidrw]$ cg-j1j2 1 1/2

From perl:

    use Quantum::ClebschGordan;

    print Quantum::ClebschGordan->new( j1=>1, j2=>'1/2', m=>'3/2', m1=>'1', m2=>'1/2', j=>'3/2' )->coeff;

    my $foo = Quantum::ClebschGordan->new();
    ...
    printf "%6s %6s %6s %6s %6s %6s %6s, %s\n", Quantum::ClebschGordan->state_names, 'N', 'c';
    printf "%6s %6s %6s %6s %6s %6s %6s, %s\n", $_->state_nums, $_->coeff, $_->coeff_value
      for Quantum::ClebschGordan->new( j1 => 1, j2 => '1/2' )->explode;

=head1 INTRODUCTION

Some references:

Calculation of the coefficients: L<http://string.howard.edu/~tristan/QM2/QM2WE.pdf>

Table of the coefficients: L<http://pdg.lbl.gov/2002/clebrpp.pdf>

Wiki Page: L<http://en.wikipedia.org/wiki/Clebsch-Gordan_coefficients>

Another table of the coefficients (warning--may be inaccurate): L<http://en.wikipedia.org/wiki/Table_of_Clebsch-Gordan_coefficients>

=head2 Wigner 3-j Symbol calculation:

L<http://wwwasdoc.web.cern.ch/wwwasdoc/shortwrupsdir/u111/top.html>

L<http://bbs.sachina.pku.edu.cn/Stat/Math_World/math/w/w120.htm>

=head1 METHODS

=head2 new

Constructor -- can take named arguments of j1, j2, m, m1, m2, j

=head2 coeff

Returns the Clebsch-Gordan coefficient for the object's (j1,j2,m,m1,m2,j) values.  undef unless all the values are set. NOTE: THIS IS NOT THE ACTUAL VALUE. It is in the notation +-N where N is non-negative integer or fraction, and the real value is +-sqrt(abs(N)).  To get this directly, use the L<coeff_value> method.

=head2 coeff_value

Returns the actual Clebsch-Gordan coefficient (as a real decimal number) for the object's (j1,j2,m,m1,m2,j) values.  undef unless all the values are set.  For an abbreviated notation, use the L<coeff> method.

=head2 wigner3j

Returns the actual Wigner 3-j symbol for the object's (j1,j2,m,m1,m2,j) values.  undef unless all the values are set. This is in the same notation as the L<coeff> method.

=head2 wigner3j_value

Returns the actual Wigner 3-j symbol (as a real decimal number) for the object's (j1,j2,m,m1,m2,j) values.  undef unless all the values are set.  For an abbreviated notation, use the L<wigner3j> method.

=head2 explode

Use this method if you only have some of the (j1,j2,m,m1,m2,j) values;

Returns a list of Quantum::ClebschGordan objects based on the given (j1,j2,m,m1,m2,j) values for the current object. If any of those values are unset, then there will be an object in the list for each of the possible combinations, given the rules governing m and j values. Each of the returned Quantum::ClebschGordan objects will have all of the (j1,j2,m,m1,m2,j) values set, and thus the L<coeff>, L<coeff_value>, L<wigner3j>, and L<wigner3j_value> will all have values.

=head2 state_names

Returns the list of names of the state variables -- based on a constant and will return ('j1', 'j2', 'm', 'm1', 'm2', 'j').

=head2 state_nums

Returns the list of the (j1,j2,m,m1,m2,j) values as L<Number::Fraction> objects.

=head2 state_values

Returns the list of the (j1,j2,m,m1,m2,j) values as real decimal values.

=head1 PRIVATE METHODS

=head2 set

Overload of Class::Accessor's set() method. Same functionality, plus the following if setting on of the 'state' variables:

=over 2

=item *

Attempts to converts the value into a Number::Fraction object. This allows for values such as '1/2' to be used.

=item *

Performs validation (via __check_state()) that this new value is consistent w/the other state values.

=item *

Attempts to auto-calculate the coefficient (only succeeds if all vars are set; otherwise coeff is cleared).

=back

=head2 __set_coeff

Attempts to calculate the Clebsch-Gordan coffectient for the object and sets the I<__coeff> attribute (which is what the L<coeff> and L<coeff_value> methods are based upon).

=head2 __check_state

Audits the (j1,j2,m,m1,m2,j) values to make sure that they are valid and consistent with each other. Returns undef (and throws a warning) if there is an error.  Returns 1 if all values are set and valid.  Returns -1 if only some of the values are set, but the ones that are set are valid.

=head1 FUNCTIONS

=head2 __seq

Quick & dirty helper function that's bascially like the unix 'seq' command.

=head2 factorial

Returns n! for a given integer n.  Uses Memoize for caching.

=head2 notation2real

Converts a value from the form returned by L<coeff> to a real number.

=head2 real2notation

Attempts to convert a real number in the form returned by L<coeff>.

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 PREREQUISITES

Quantum::ClebschGordan requires the following modules:

L<Number::Fraction>

L<Memoize>

L<Class::Accessor>

L<Carp>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-quantum-clebschgordan at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quantum-ClebschGordan>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I'm also available by email or via '/msg davidrw' on <http://perlmonks.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Quantum::ClebschGordan

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Quantum-ClebschGordan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Quantum-ClebschGordan>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Quantum-ClebschGordan>

=item * Search CPAN

L<http://search.cpan.org/dist/Quantum-ClebschGordan>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Quantum::ClebschGordan

