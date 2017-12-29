# -*- Perl -*-
#
# "Plomp-Levelt consonance curve" implementation

package Music::Tension::PlompLevelt;

use 5.010000;
use strict;
use warnings;

use Carp qw/croak/;
use List::Util qw/sum/;
use Music::Tension ();
use Scalar::Util qw/looks_like_number/;

our @ISA     = qw(Music::Tension);
our $VERSION = '1.01';

# pianowire* are from [Helmholtz 1877 p.79] relative intensity of first
# six harmonics of piano wire, struck at 1/7th its length, for various
# hammer types. Via http://jjensen.org/DissonanceCurve.html
my %AMPLITUDES = (
    'ones' => [ (1) x 6 ],
    'pianowire-plucked' => [ 1, 0.8, 0.6, 0.3, 0.1, 0.03 ],
    'pianowire-soft'    => [ 1, 1.9, 1.1, 0.2, 0,   0.05 ],
    'pianowire-medium'  => [ 1, 2.9, 3.6, 2.6, 1.1, 0.2 ],
    'pianowire-hard'    => [ 1, 3.2, 5,   5,   3.2, 1 ],
);

########################################################################
#
# SUBROUTINES

sub new {
    my ( $class, %param ) = @_;
    my $self = $class->SUPER::new(%param);

    $self->{_amplitudes} = {%AMPLITUDES};

    if ( exists $param{amplitudes} ) {
        for my $name ( keys %{ $param{amplitudes} } ) {
            croak "amplitude profile '$name' must be array reference"
              unless ref $param{amplitudes}->{$name} eq 'ARRAY';
            $self->{_amplitudes}->{$name} = $param{amplitudes}->{$name};
        }
    }

    if ( exists $param{default_amp_profile} ) {
        croak "no such profile '$param{default_amp_profile}'"
          unless exists $self->{_amplitudes}->{ $param{default_amp_profile} };
        $self->{_amp_profile} = $param{default_amp_profile};
    } else {
        $self->{_amp_profile} = 'pianowire-medium';
    }

    # NOTE will also need normalize if add setter method to update _amplitudes
    $self->{_normalize_amps} = exists $param{normalize_amps} ? 1 : 0;
    if ( $self->{_normalize_amps} ) {
        for my $amps ( values %{ $self->{_amplitudes} } ) {
            my $sum = sum @$amps;
            for my $amp (@$amps) {
                $amp /= $sum;
            }
        }
    }

    bless $self, $class;
    return $self;
}

# Not sure if I've followed the papers correctly; they all operate on a
# single frequency with overtones above that, while for tension I'm
# interested in "given these two frequencies or pitches (with their own
# sets of overtones), how dissonant are they to one another" so
# hopefully I can just tally up the harmonics between the two different
# sets of harmonics?
#
# Also, vertical scaling might take more looking at, perhaps arrange so
# with normalize_amps the maximum dissonance has the value of 1? (or
# that the most dissonant interval of the scale, e.g. minor 2nd in equal
# temperament has the value of one?)
sub frequencies {
    my ( $self, $f1, $f2 ) = @_;
    my @harmonics;

    if ( looks_like_number $f1) {
        for my $i ( 0 .. $#{ $self->{_amplitudes}->{ $self->{_amp_profile} } } ) {
            push @{ $harmonics[0] },
              { amp => $self->{_amplitudes}->{ $self->{_amp_profile} }->[$i] || 0,
                freq => $f1 * ( $i + 1 ),
              };
        }
    } elsif ( ref $f1 eq 'ARRAY' and @$f1 and ref $f1->[0] eq 'HASH' ) {
        $harmonics[0] = $f1;
    } else {
        croak "unknown input for frequency1";
    }
    if ( looks_like_number $f2) {
        for my $j ( 0 .. $#{ $self->{_amplitudes}->{ $self->{_amp_profile} } } ) {
            push @{ $harmonics[1] },
              { amp => $self->{_amplitudes}->{ $self->{_amp_profile} }->[$j] || 0,
                freq => $f2 * ( $j + 1 ),
              };
        }
    } elsif ( ref $f2 eq 'ARRAY' and @$f2 and ref $f2->[0] eq 'HASH' ) {
        $harmonics[1] = $f2;
    } else {
        croak "unknown input for frequency2";
    }

    # code ported from equation at http://jjensen.org/DissonanceCurve.html
    my $tension;
    for my $i ( 0 .. $#{ $harmonics[0] } ) {
        for my $j ( 0 .. $#{ $harmonics[1] } ) {
            my @freqs = sort { $a <=> $b } $harmonics[0]->[$i]{freq},
              $harmonics[1]->[$j]{freq};
            my $q = ( $freqs[1] - $freqs[0] ) / ( 0.021 * $freqs[0] + 19 );
            $tension +=
              $harmonics[0]->[$i]{amp} *
              $harmonics[1]->[$j]{amp} *
              ( exp( -0.84 * $q ) - exp( -1.38 * $q ) );
        }
    }

    return $tension;
}

sub pitches {
    my ( $self, $p1, $p2, $freq_harmonics ) = @_;
    croak "two pitches required" if !defined $p1 or !defined $p2;
    croak "pitches must be positive integers"
      if $p1 !~ m/^\d+$/
      or $p2 !~ m/^\d+$/;

    return $self->frequencies( map( $self->pitch2freq($_), $p1, $p2 ),
        $freq_harmonics );
}

sub vertical {
    my ( $self, $pset ) = @_;
    croak "pitch set must be array ref" unless ref $pset eq 'ARRAY';
    croak "pitch set must contain multiple elements" if @$pset < 2;

    my @freqs = map $self->pitch2freq($_), @$pset;

    my $min = ~0;
    my $max = 0;
    my ( @tensions, $sum );
    for my $i ( 1 .. $#freqs ) {
        my $t = $self->frequencies( $freqs[0], $freqs[$i] );
        $sum += $t;
        $min = $t
          if $t < $min;
        $max = $t
          if $t > $max;
        push @tensions, $t;
    }

    return wantarray ? ( $sum, $min, $max, \@tensions ) : $sum;
}

1;
__END__

=head1 NAME

Music::Tension::PlompLevelt - Plomp-Levelt consonance curve calculations

=head1 SYNOPSIS

  use Music::Tension::PlompLevelt;
  my $tension = Music::Tension::PlompLevelt->new;

  $tension->frequencies(440, 880);

  $tension->pitches(69, 81);

  $tension->vertical([qw/60 64 67/]);

=head1 DESCRIPTION

Plomp-Levelt consonance curve calculations based on work by William
Sethares and others (L</"SEE ALSO"> for links). None of this will make
sense without some grounding in music theory and the referenced papers.

Parsing music into a form suitable for use by this module and practical
uses of the results are left as an exercise to the reader. Consult the
C<eg/> directory of this module's distribution for example programs.

=head2 TERMINOLOGY

      Fundamental        Overtones
  Harmonic      1        2       3       4       5       6       7
    partials
      odds      o                o               o               o
      evens              e               e               e

  ly pitch      c,       c       g       c'      e'      g'      bes'
  MIDI number   36       48      55      60      64      67      70

  frequency     65.41    130.82  196.23  261.64  327.05  392.46  457.87
   equal temp.  65.41    130.81  196.00  261.63  329.63  392.00  466.16
  error         0        -0.01   -0.23   -0.01   +2.58   -0.46   +8.29

The calculations use some number of harmonics, depending on the
amplitude profile used, or frequency information supplied. Finding
details on the harmonics for a particular instrument may require
consulting a book, or performing spectral analysis on recordings of a
particular instrument (e.g. via Audacity), or fiddling around with a
synthesizer, and likely making simplifying assumptions on what gets fed
into this module.

=head1 CAVEATS

Other music writers indicate that the partials should be ignored, for
example Harry Partch: "Long experience... convinces me that it is
preferable to ignore partials as a source of musical materials. The ear
is not impressed by partials as such. The faculty--the prime faculty--of
the ear is the perception of small-numbered intervals, 2/1, 3/2, 4/3,
etc. and the ear cares not a whit whether these intervals are in or out
of the overtone series." (Genesis of a Music, 1947). (However, note that
this declamation predates the work by Sethares and others.)

On the plus side, this method does rate an augmented triad as more
dissonant than a diminished triad (though that test was with distortions
from equal temperament), which agrees with a study mentioned over in
L<Music::Tension::Cope> that the Cope method finds the opposite of.

See also "Harmony Perception: Harmoniousness is more than the sum of
interval consonance" by Norman Cook (2009) though that method should
probably be in a different module than this one.

=head1 METHODS

Any method may B<croak> if something is awry with the input. Methods are
inherited from the parent class, L<Music::Tension>. Unlike
L<Music::Tension::Cope>, this module is very sensitive to the register
of the pitches involved, so input pitches should ideally be from the
MIDI note numbers and in the proper register. Or instead use frequencies
via methods that accept those (especially to avoid the distortions of
equal temperament tuning).

The tension number depends heavily on the equation (and constants to
said equation), and should not be considered comparable to any other
tension modules in this distribution, and only to other tension values
from this module if the same harmonics were used in all calculations.
Also, the tension numbers could very easily change between releases of
this module.

=over 4

=item B<new> I<optional params>

Constructor. Accepts various optional parameters.

  my $tension = Music::Tension::PlompLevelt->new(
    amplitudes => {
      made_up_numbers => [ 42, 42, ... ],
      ...
    },
    default_amp_profile => 'made_up_numbers',
    normalize_amps      => 1,
    reference_frequency => 442,
  );

=over 4

=item *

I<amplitudes> specifies a hash reference that should contain
named amplitude sets and an array reference of amplitude values
for each harmonic.

=item *

I<default_amp_profile> what amplitude profile to use by default.
Available options pre-coded into the module include:

  ones
  pianowire-plucked
  pianowire-soft
  pianowire-medium    * the default
  pianowire-hard

These all have amplitude values for six harmonics.

=item *

I<normalize_amps> if true, normalizes the amplitude values such that
they sum up to one.

=item *

I<reference_frequency> sets the MIDI reference frequency, by default 440
(Hz). Used by B<pitch2freq> conversion called by the B<pitches> and
B<vertical> methods.

=back

=item B<frequencies> I<freq_or_ref1>, I<freq_or_ref2>

Method that accepts two frequencies, or two array references containing
the harmonics and amplitudes of such. Returns tension as a number.

  # default harmonics will be filled in
  $tension->frequencies(440, 880);

  # custom harmonics
  $tension->frequencies(
    [ {amp=>1,    freq=>440}, {amp=>0.5,  freq=>880},  ... ],
    [ {amp=>0.88, freq=>880}, ... ],
    ...
  );

The harmonics need not be the same number, nor use the same frequencies
nor amplitudes. This allows comparison of different frequencies bearing
different harmonic profiles. The resulting tension numbers are not
normalized to anything; making them range from zero to one can be solved
something like:

  use List::Util qw/max/;

  my @results;
  for my $f ( 440 .. 880 ) {
    push @results, [ $f, $tension->frequencies( 440, $f ) ];
  }
  my $max = max map $_->[1], @results;
  for my $r (@results) {
    printf "%.1f %.3f\n", $r->[0], $r->[1] / $max;
  }

See the C<eg/> directory under this module's distribution for
example code containing the above.

=item B<pitches> I<pitch1>, I<pitch2>

Accepts two integers (ideally MIDI note numbers) and converts those to
frequencies via B<pitch2freq> (which does the MIDI number to frequency
conversion equation) and then calls B<frequencies> with those values.
Use B<frequencies> with the proper Hz if a non-equal temperament tuning
is involved. Returns tension as a number.

=item B<vertical> I<pitch_set>

Given a pitch set (an array reference of integer pitch numbers that are
ideally MIDI numbers), converts those pitches to frequencies via
B<pitch2freq>, then calls B<frequencies> for the first pitch compared in
turn with each subsequent in the set. In scalar context, returns the
total tension, while in list context returns the total, min, max, and an
array reference of individual tensions of the various intervals present.

=back

=head1 SEE ALSO

=over 4

=item *

L<http://jjensen.org/DissonanceCurve.html> - Java applet, discussion.

=item *

L<http://sethares.engr.wisc.edu/consemi.html> - "Relating Tuning and
Timbre" by William Sethares. Also
L<http://sethares.engr.wisc.edu/comprog.html>

=item *

"Music: A Mathematical Offering", David Benson, 2008. (Chapter 4)
L<http://homepages.abdn.ac.uk/mth192/pages/html/maths-music.html>

=item *

L<Music::Chord::Note> - obtain pitch sets for common chord names.

=item *

L<Music::Scala> - Scala scale file support for alternate tuning and
temperament calculations.

=item *

L<Music::Tension::Cope> - alternative tension algorithm based on
work of David Cope.

=item *

R. Plomp and W. J. M. Levelt, Tonal consonance and critical bandwidth,
J. Acoust. Soc. Amer. 38 (4) (1965), 548-560.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013,2017 by Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.16 or, at
your option, any later version of Perl 5 you may have available.

=cut
