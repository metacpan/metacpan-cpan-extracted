# -*- Perl -*-
#
# Functions for fractal noise generation functions.
#
# Run perldoc(1) on this file for additional documentation.

package Music::Voss;

use 5.010000;
use strict;
use warnings;
use Carp qw(croak);
use Exporter 'import';
use List::Util ();
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.05';

our @EXPORT_OK = qw(bitchange powers powers_stateless);

# This method derived from the "White and brown music, fractal curves
# and one-over-f fluctuations" article. Should also be possible with
# physical dice and a binary chart to show how the bits change between
# tries and thus which dice need be re-rolled for a particular try.
sub bitchange {
  my (%params) = @_;
  if ( !exists $params{rollers} ) {
    $params{rollers} = 3;
  } elsif ( !defined $params{rollers} or !looks_like_number $params{rollers} ) {
    croak "rollers must be a number";
  } else {
    $params{rollers} = int $params{rollers};
  }
  if ( !exists $params{roll} ) {
    $params{roll} = sub { int rand 6 };
  } elsif ( !defined $params{roll} or ref $params{roll} ne 'CODE' ) {
    croak "roll must be code reference";
  }
  if ( !exists $params{summer} ) {
    $params{summer} = \&List::Util::sum0;
  } elsif ( !defined $params{summer} or ref $params{summer} ne 'CODE' ) {
    croak "summer must be code reference";
  }
  my @nums = map { $params{roll}->( undef, $_ ) } 0 .. $params{rollers} - 1;
  my $prev;
  return sub {
    my ($n) = @_;
    croak "input must be number" if !defined $n or !looks_like_number $n;
    if ( defined $prev ) {
      for my $rnum ( 0 .. $params{rollers} - 1 ) {
        if ( ( $n >> $rnum & 1 ) != ( $prev >> $rnum & 1 ) ) {
          $nums[$rnum] = $params{roll}->( $n, $rnum );
        }
      }
    }
    $prev = $n;
    return $params{summer}->(@nums);
  };
}

# "Musimathics, Vol 1" p.358 based function generator based on powers of
# (by default) 2, the supplied number, and a list of subroutines to
# (perhaps) run. (Was called "voss", orginally.)
sub powers {
  my (%params) = @_;
  croak "must be given list of calls"
    if !$params{calls}
    or ref $params{calls} ne 'ARRAY';
  if ( !exists $params{summer} ) {
    $params{summer} = \&List::Util::sum0;
  } elsif ( !defined $params{summer} or ref $params{summer} ne 'CODE' ) {
    croak "summer must be code reference";
  }
  if ( !exists $params{e} ) {
    $params{e} = 2;
  } elsif ( !defined $params{e} or !looks_like_number $params{e} ) {
    croak "e must be a number";
  }
  my @nums = (0) x @{ $params{calls} };
  return sub {
    my ($n) = @_;
    croak "input must be number" if !defined $n or !looks_like_number $n;
    for my $k ( 0 .. $#{ $params{calls} } ) {
      if ( $n % $params{e}**$k == 0 ) {
        $nums[$k] = $params{calls}->[$k]->( $n, $k );
      }
    }
    return $params{summer}->(@nums);
  };
}

sub powers_stateless {
  my (%params) = @_;
  croak "must be given list of calls"
    if !$params{calls}
    or ref $params{calls} ne 'ARRAY';
  if ( !exists $params{summer} ) {
    $params{summer} = \&List::Util::sum0;
  } elsif ( !defined $params{summer} or ref $params{summer} ne 'CODE' ) {
    croak "summer must be code reference";
  }
  if ( !exists $params{e} ) {
    $params{e} = 2;
  } elsif ( !defined $params{e} or !looks_like_number $params{e} ) {
    croak "e must be a number";
  }
  return sub {
    my ($n) = @_;
    croak "input must be number" if !defined $n or !looks_like_number $n;
    my @nums;
    for my $k ( 0 .. $#{ $params{calls} } ) {
      if ( $n % $params{e}**$k == 0 ) {
        push @nums, $params{calls}->[$k]->( $n, $k );
      }
    }
    return $params{summer}->(@nums);
  };
}

1;
__END__

=head1 NAME

Music::Voss - functions for fractal noise generation functions

=head1 SYNOPSIS

  use List::Util qw(max sum0);
  use Music::Voss qw(bitchange powers);

  # roll up to 3 dice as the bits change between x values
  my $bc = bitchange(
    roll    => sub { 1 + int rand 6 },
    rollers => 3,
  );
  for my $x (0..21) {
    printf "%d %d\n", $x, $bc->($x);
  }

  # call functions when x % 2**funcnum == 0
  my $genf = powers( calls => [
    sub { int rand 2 },  # k=0, 2**k == 1 (every value)
    sub { int rand 2 },  # k=1, 2**k == 2 (every other value)
    sub { int rand 2 },  # k=2, 2**k == 4 ...
    sub { int rand 2 },  # k=3, ...
    ...
  ]);
  my $geny = powers(
    calls  => [ sub { 5 - int rand 10 }, ... ], 
    summer => sub { max 0, sum0 @_ },
  );
  for my $x (0..21) {
    printf "%d %d %d\n", $x, $genf->($x), $geny->($x);
  }
  # or to obtain a list of values (NOTE TODO FIXME the powers() generated
  # functions maintain state and there is (as yet) no way to inspect or
  # reset that state; for now generate a new function if needed.)
  my @values = map { $genf->($_) } 0..21;

Consult the C<eg/> and C<t/> directories under this module's
distribution for more example code.

=head1 DESCRIPTION

This module contains functions that generate functions that may then be
called in turn with a sequence of numbers to generate numbers. Given how
hopelessly vague this may sound, let us move on to the

=head1 FUNCTIONS

These are not exported, and must be manually imported or called with the
full module path.

=over 4

=item B<bitchange>

Returns a function that will run a C<roll> method for each changed bit
of a given number of C<rollers> between the passed value and the
previous one, then returns the sum of those numbers (via the C<summer>
function, by default C<sum0> of L<List::Util>). The default C<roll> is a
six-sided die producing integers from C<0> through C<5>, and the default
number of C<rollers> is C<3>. The C<roll> call is called with two
arguments, the given number and the index of the die being updated. The
given number will be C<undef> when there is no previous value to
calculate bit changes from; this is a concern when the C<roll> call is
concerned with the number passed to the generated function:

  my $fun = bitchange(
    roll => sub {
      my ($n, $dienum) = @_;
      if (defined $n) {
        ...
  $fun->(0); # no previous, so $n undef in roll call
  $fun->(1); # $n now available

The generated function ideally should be fed sequences of integers that
increment by one, though other sequences will produce other bit change
patterns. Too large a number of C<rollers> may run into problems,
possibly around 32 or 64, depending on how perl is compiled.

=item B<powers>

This function returns a function that in turn should be called with
(ideally successive) integers. The generated function uses powers-of-two
modulus math on the array index of the list of given C<calls> to
determine when the result from a particular call should be saved to an
array internal to the generated function. A custom C<summer> function
may be supplied to B<powers> that will sum the resulting list of numbers;
the default is to call C<sum0> of L<List::Util> and return that sum. The
C<e> parameter allows the exponent to be set; the default is C<2>.

The C<calls> functions are passed two arguments, the given number, and
the array index that triggered the call. C<calls> functions probably
should return a number. Typically, the C<calls> return random values,
though other patterns are certainly worth experimenting with, such as a
mix of random values and other values that are iterated through:

  use Music::AtonalUtil;
  my $atu = Music::AtonalUtil->new;

  my @values = qw/0 0 2 1 1 2 0/;
  my $genf = powers(
    calls => [
      sub { 1 - int rand 2 },   # 1
      sub { 0 },                # 2
      sub { 1 - int rand 2 },   # 4
      sub { 1 - int rand 2 },   # 8
      $atu->nexti( \@values )   # 16
    ]
  );

The generated function ideally should be fed sequences of integers that
increment by one. This means that the slower-changing values from higher
array indexed C<calls> will persist through subsequent calls. If this is
a problem, consider instead the

=item B<powers_stateless>

function, which is exactly like B<powers>, only it does not keep state
through repeated calls the the returned function. Likely useful for
rhythmic (or MIDI velocity) related purposes, assuming those purposes
can be shoehorned into the powers-of-two modulus model of the B<powers>
function. And they can be! A mod 12 rhythm would be possible via
something like:

  my $mod12 = powers_stateless( calls => [ sub {
    my ( $n, $k ) = @_;
    $n % 12 == 0 ? 1 : 0
  }, ] );
  for my $x (0..$whatevs) {
    my $y = $mod12->($x);
    ...

Though, any such math must bear in mind that C<calls> beyond the first
are only called on every 2nd, 4th, etc. input value (assuming as ever
that the input values are a list of integers that being on an even value
and increment by one for each successive call).

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-voss at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-Voss>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-Voss>

=head2 Known Issues

The functions returned by some functions of this module probably should
not be used in a threaded environment, on account of unknown results
should multiple threads call the same function around the same time.
This may actually be a feature for experimental musical composition.

May need multiple return values from the function returning functions,
with the remaining functions being means to reset or otherwise interact
with any state maintained by the function.

The lack of testing. (Bad input values, whether anything sketchy is
going on with the closures, etc.)

Probably should add a weierstrass method, but that's more work.

=head1 SEE ALSO

L<MIDI::Simple> or L<Music::Scala> or L<Music::LilyPondUtil> have means
to convert numbers (such as produced by the functions returned by the
functions of this module) into MIDI events, frequencies, or a form
suitable to pass to lilypond. L<Music::Canon> (or the C<canonical>
program by way of L<App::MusicTools>) may also be of interest, as well
as L<Music::AtonalUtil> for various music related functions.

=head1 REFERENCES

=over 4

=item *

Gardner M. White and brown music, fractal curves and one-over-f fluctuations. Scientific American. 1978 Apr;238(4):16-27.

=item *

Loy G. Musimathics: the mathematical foundations of music. Mit Press; 2011 Aug 19.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
