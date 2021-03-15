# -*- Perl -*-
#
# Parent class for music tension analysis modules

package Music::Tension;

our $VERSION = '1.03';

use strict;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/looks_like_number/;

########################################################################
#
# METHODS

sub new {
    my ( $class, %param ) = @_;
    my $self = {};

    # just MIDI support here, see Music::Scala for scala scale file support
    if ( exists $param{reference_frequency} ) {
        croak "reference_frequency must be a number"
          if !defined $param{reference_frequency}
          or !looks_like_number $param{reference_frequency};
        $self->{_reference_frequency} = $param{reference_frequency};
    } else {
        $self->{_reference_frequency} = 440;
    }

    bless $self, $class;
    return $self;
}

sub freq2pitch {
    my ( $self, $freq ) = @_;
    croak "frequency must be a positive number"
      if !defined $freq
      or !looks_like_number $freq
      or $freq <= 0;

    return sprintf "%.0f",
      69 + 12 * ( log( $freq / $self->{_reference_frequency} ) / log(2) );
}

# accumulate tension values for two phrases at each possible offset
sub offset_tensions {
    my ( $self, $phrase1, $phrase2 ) = @_;

    die "pitches method is unimplemented" unless $self->can('pitches');

    croak "phrase1 is too short"
      unless defined $phrase1
      and ref $phrase1 eq 'ARRAY'
      and $#{$phrase1} > 1;
    croak "phrase2 is too short"
      unless defined $phrase2
      and ref $phrase2 eq 'ARRAY'
      and @$phrase2;

    my $max = $#{$phrase1};

    my @tensions;
    for my $offset ( 0 .. $max ) {
        for my $i ( 0 .. $#{$phrase2} ) {
            my $delta = $i + $offset;
            last if $delta > $max;
            push @{ $tensions[$offset] },
              $self->pitches( $phrase1->[$delta], $phrase2->[$i] );
        }
    }
    return @tensions;
}

sub pitch2freq {
    my ( $self, $pitch ) = @_;
    croak "pitch must be MIDI number"
      if !defined $pitch
      or !looks_like_number $pitch
      or $pitch < 0;

    return $self->{_reference_frequency} * ( 2**( ( $pitch - 69 ) / 12 ) );
}

1;
__END__

=head1 NAME

Music::Tension - music tension analysis

=head1 SYNOPSIS

  use Music::Tension;
  my $t = Music::Tension;
  $t->pitch2freq(60);
  $t->freq2pitch(440);

  use Music::Tension::Cope;
  my $ct = Music::Tension::Cope;
  $ct->...  # see that module for details

  use Music::Tension::Counterpoint;
  my $cpt = Music::Tension::Counterpoint;
  $cpt->... # see that module for details

  use Music::Tension::PlompLevelt;
  my $plt = Music::Tension::PlompLevelt;
  $plt->... # see that module for details

=head1 DESCRIPTION

Music tension (dissonance) analysis. This module is the parent class and
as such does not offer much. The other modules under this distribution
provide routines that produce numbers for how consonant or dissonant a
chord or other musical events are according to some system of rules.

The numbers produced by one module can only be used in comparison
with that same module (and possibly only the same version of that
module with the same configuration parameters); no attempt has been
made to correlate the output of any overlapping methods between the
different modules.

=head2 SUB-MODULES

If you have ideas for a new tension analysis module, please let me know,
so it can be included in this distribution, or locate it outside of the
C<Music::Tension::*> space.

=over 4

=item *

L<Music::Tension::Cope> - methods outlined in "Computer Models of
Musical Creativity" by David Cope, including routines for specific
pitches, verticals (chords), metric position, and other factors.

=item *

L<Music::Tension::Counterpoint> - interval checks per the rules of
counterpoint (or hopefully some fairly common flavor thereof).

=item *

L<Music::Tension::PlompLevelt> - Plomp-Levelt consonance curve
calculations based on writings and code by William Sethares, among
others. For frequencies (and pitches) in vertical relationships.

=back

=head1 METHODS

Any method may B<croak> if something is awry with the input. These
methods are inherited by the sub-modules.

=over 4

=item B<new> I<optional params>

Constructor. Accepts an optional parameter to change the reference
frequency use by the frequency/pitch conversion calls (440 by default).

  my $t = Music::Tension->new(reference_frequency => 442);

=item B<freq2pitch> I<frequency>

Given a frequency (Hz), returns the integer pitch number (which might
also be a MIDI number). Fractional pitch results are rounded to the
nearest pitch number. (I am unsure if the standard practice is to round
or truncate the conversion, so I guessed to round.)

=item B<offset_tensions> I<phrase1>, I<phrase2>

Since version 1.03.

Accumulates the tension between the given phrases (array references of
pitch numbers) at each possible offset between the two. For example
given the phrases C<D F E D> and C<A C B A> these can be compared at the
following offsets:

  0
    A  C  B  A
    D  F  E  D
    69 72 71 69
    62 65 64 62
  
  1
       A  C  B  A
    D  F  E  D
       69 72 71
    62 65 64 62
  
  2
          A  C  B  A
    D  F  E  D
          69 72
    62 65 64 62
  
  3
             A  C  B  A
    D  F  E  D
             69
    62 65 64 62

The final three comparisons are typical for canon, fugue, or imitation.

Internally the B<pitches> method is used to compute the tension between
each pair of notes. L<Music::Tension> does not implement any such
method, so a sub-module must instead be used.

The return value is a list of array references of tensions; for the
above there would be four items in the list, and the first array
reference would have four tension values (offset 0), the second three
tension values (offset 1), etc.

=item B<pitch2freq> I<pitch>

Given a pitch number (a positive integer, perhaps from the MIDI numbers
range), returns the frequency (Hz).

=back

=head1 SEE ALSO

=over 4

=item *

L<Music::Scala> for the use of alternate tuning and temperaments.

=item *

L<http://en.wikipedia.org/wiki/Pitch_%28music%29> was the source of the
pitch/frequency conversion equations.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jeremy Mates

https://opensource.org/licenses/BSD-3-Clause

=cut
