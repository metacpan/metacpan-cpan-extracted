# -*- Perl -*-
#
# Parent class for music tension analysis modules.

package Music::Tension;

use 5.010000;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '1.01';

########################################################################
#
# SUBROUTINES

sub new {
    my ( $class, %param ) = @_;
    my $self = {};

    # just MIDI support here, see Music::Scala for scala scale file support
    if ( exists $param{reference_frequency} ) {
        croak "reference_frequency must be a number"
          if !looks_like_number $param{reference_frequency};
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
      if !looks_like_number $freq
      or $freq < 0;

    return sprintf "%.0f",
      69 + 12 * ( log( $freq / $self->{_reference_frequency} ) / log(2) );
}

sub pitch2freq {
    my ( $self, $pitch ) = @_;
    croak "pitch must be MIDI number"
      if !looks_like_number $pitch
      or $pitch < 0;

    return $self->{_reference_frequency} * ( 2**( ( $pitch - 69 ) / 12 ) );
}

1;
__END__

=head1 NAME

Music::Tension - music tension analysis

=head1 SYNOPSIS

  my $t = Music::Tension ();
  $t->pitch2freq(60);
  $t->freq2pitch(440);


  my $ct = Music::Tension::Cope ();
  $ct->... # see that module for details

  my $plt = Music::Tension::PlompLevelt ();
  $plt->... # see that module for details

=head1 DESCRIPTION

Music tension (dissonance) analysis. This module merely provides pitch
and frequency conversion routines. The other modules under this
distribution provide various algorithms that produce a number for how
consonant or dissonant a chord or other musical events are, presumably
for use in musical analysis or composition.

The numbers produced by one module can only be used in comparison with
other musical events calculated by the same module; no attempt has been
made to correlate the output of any overlapping methods between the
different modules. (Though comparisons may be interesting.)

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
also be a MIDI number, unless that range is exceeded somehow).
Fractional pitch results are rounded to the nearest pitch number. (I'm
not sure if the standard practice is to round or truncate the
conversion, so I guessed to round.)

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

Copyright (C) 2012-2013,2017 by Jeremy Mates

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16 or,
at your option, any later version of Perl 5 you may have available.

=cut
