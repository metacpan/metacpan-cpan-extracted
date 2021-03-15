# -*- Perl -*-
#
# Counterpoint tension calculation, which here means a boolean pass or
# fail depending on the interval(s) involved

package Music::Tension::Counterpoint;

our $VERSION = '1.03';

use 5.008;
use strict;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/looks_like_number/;

use constant { DISS => 0, CONS => 1 };

use parent qw(Music::Tension);

my $DEG_IN_SCALE = 12;

########################################################################
#
# METHODS

sub new {
    my ( $class, %param ) = @_;
    my $self = $class->SUPER::new(%param);

    if ( exists $param{big_dissonance} ) {
        $self->{_big_dissonance} = $param{big_dissonance};
    } else {
        # various counterpoint texts allow for dissonant intervals
        # larger than an octave, so this is the default
        $self->{_big_dissonance} = 1;
    }

    if ( exists $param{octave_allow} ) {
        $self->{_octave_allow} = $param{octave_allow};
    } else {
        $self->{_octave_allow} = 1;
    }

    # special lookup table for the "vertical" method when considering
    # interior voices to any voices above
    if ( exists $param{interior} ) {
        croak "interior must be a hash reference"
          unless defined $param{interior} and ref $param{interior} eq 'HASH';
        for my $i ( 0 .. 11 ) {
            croak "interior must include all intervals from 0 through 11"
              if !exists $param{interior}->{$i};
            $self->{_interior}{$i} = $param{interior}->{$i} ? CONS : DISS;
        }
    } else {
        # following Norden 1969
        $self->{_interior} = {
            0  => CONS,    # unison
            1  => DISS,    # minor 2nd
            2  => DISS,    # major 2nd
            3  => CONS,    # minor 3rd
            4  => CONS,    # major 3rd
            5  => CONS,    # perfect fourth
            6  => CONS,    # augmented fourth
            7  => CONS,    # fifth
            8  => CONS,    # minor 6th
            9  => CONS,    # major 6th
            10 => DISS,    # minor 7th
            11 => DISS,    # major 7th
        };
    }
    if ( exists $param{tensions} ) {
        croak "tensions must be a hash reference"
          unless defined $param{tensions} and ref $param{tensions} eq 'HASH';
        for my $i ( -11 .. 11 ) {
            croak "tensions must include all intervals from -11 through 11"
              if !exists $param{tensions}->{$i};
            $self->{_tensions}{$i} = $param{tensions}->{$i} ? CONS : DISS;
        }
    } else {
        # these are typical values for vertical intervals. the otherwise
        # redundant negative intervals are to support melodic checks
        # that may need to know whether a leap is ascending or
        # descending
        $self->{_tensions} = {
            0   => CONS,    # unison
            1   => DISS,    # minor 2nd
            2   => DISS,    # major 2nd
            3   => CONS,    # minor 3rd
            4   => CONS,    # major 3rd
            5   => DISS,    # fourth
            6   => DISS,    # the evil, evil tritone
            7   => CONS,    # fifth
            8   => CONS,    # minor 6th
            9   => CONS,    # major 6th
            10  => DISS,    # minor 7th
            11  => DISS,    # major 7th
            -1  => DISS,    # minor 2nd
            -2  => DISS,    # major 2nd
            -3  => CONS,    # minor 3rd
            -4  => CONS,    # major 3rd
            -5  => DISS,    # fourth
            -6  => DISS,    # the evil, evil tritone
            -7  => CONS,    # fifth
            -8  => CONS,    # minor 6th
            -9  => CONS,    # major 6th
            -10 => DISS,    # minor 7th
            -11 => DISS,    # major 7th
        };
    }

    bless $self, $class;
    return $self;
}

sub pitches {
    my ( $self, $p1, $p2 ) = @_;
    croak "two pitches required" if !defined $p1 or !defined $p2;
    croak "pitches must be integers"
      if $p1 !~ m/^-?[0-9]+$/
      or $p2 !~ m/^-?[0-9]+$/;

    my $interval = $p2 - $p1;
    my $mod      = $interval % $DEG_IN_SCALE;

    if ( abs($interval) >= $DEG_IN_SCALE ) {
        if ( $mod == 0 ) {
            # exclusive test of octave intervals so that they can be
            # treated differently from the unison
            return $self->{_octave_allow} ? CONS : DISS;
        } else {
            # anything above an octave is okay by default; otherwise
            # falls through to the _tensions lookup below
            return CONS if $self->{_big_dissonance};
        }
    }

    my $neg = $interval < 0 ? $DEG_IN_SCALE : 0;
    return $self->{_tensions}->{ $mod - $neg };
}

# why not hide former synopsis code in a method?
sub usable_offsets {
    my $self = shift;
    my @ret  = $self->offset_tensions(@_);
    my @ok;
  OFFS: for my $i ( 1 .. $#ret ) {
        for my $consonant ( @{ $ret[$i] } ) {
            next OFFS unless $consonant;
        }
        push @ok, $i;
    }
    return @ok;
}

sub vertical {
    my ( $self, $pset ) = @_;
    croak "pitch set must be array ref"
      unless defined $pset and ref $pset eq 'ARRAY';
    croak "pitch set must contain multiple elements" if @$pset < 2;

    # the root (or lowest) pitch is from where special checks are done;
    # that pitch must be first in the list. also the sort simplifies the
    # interior interval checks (always non-negative intervals)
    my @pcs = sort { $a <=> $b } @$pset;

    for my $i ( 1 .. $#pcs ) {
        return DISS if $self->pitches( $pcs[0], $pcs[$i] ) == DISS;

        # interior voice interval checks may vary; Norden 1969 (p.84)
        # allows for interior perfect and augmented fourths in a 3-part
        # texture but presumably not 2nds nor 7ths. so, new lookup table
        if ( $i < $#pcs ) {
            for my $j ( $i + 1 .. $#pcs ) {
                my $interval = $pcs[$j] - $pcs[$i];
                my $mod      = $interval % $DEG_IN_SCALE;
                if ( $interval >= $DEG_IN_SCALE ) {
                    if ( $mod == 0 ) {
                        if ( $self->{_octave_allow} ) {
                            next;
                        } else {
                            return DISS;
                        }
                    } else {
                        next if $self->{_big_dissonance};
                    }
                }
                return DISS if $self->{_interior}{$mod} == DISS;
            }
        }
    }

    return CONS;
}

1;
__END__

=head1 NAME

Music::Tension::Counterpoint - interval tests for strict counterpoint

=head1 SYNOPSIS

  use Music::Tension::Counterpoint;
  my $cpt = Music::Tension::Counterpoint->new;

  # tritone, dissonant
  $cpt->pitches(0, 6);      # 0

  # perfect fifth, consonant
  $cpt->pitches(0, 7);      # 1

  # A below D, negative fourth, dissonant
  $cpt->pitches(74, 69);    # 0

  # D F E D against A C B A at each possible offset
  my @tensions = $cpt->offset_tensions(
      [qw/62 65 64 62/], [qw/69 72 71 69/]
  );

  # what offsets from offset_tensions are all consonant?
  my @consonant_offsets = $cpt->usable_offsets(
      [qw/62 65 64 62/], [qw/69 72 71 69/]
  );

  # consideration of chords (or pitch sets)
  $cpt->vertical( [qw/60 64 67 72/] );  # 1
  $cpt->vertical( [qw/60 64 66 72/] );  # 0

=head1 DESCRIPTION

Strict counterpoint rates intervals as acceptable or not acceptable
depending on the horizontal or vertical intervals involved. There may be
allowances for certain vertical dissonances that can be resolved by ties
or suspensions, and there may be allowances for dissonances that use an
interval larger than an octave, but then maybe negative points for
letting the voices wander too far apart. Anyways, rating intervals in a
boolean fashion is possible with this module.

If you need more complexity consider instead L<Music::Tension::Cope>, or
perhaps copy and modify this code to suit the rules system in question.
The allowed intervals can be customized via I<tensions> and I<interior>.

=head2 CAVEATS

No consideration of mode is made; chromatic intervals alien to a
particular mode (or scale) may be rated as consonant by this module.
L<Music::Scales> could help with modal considerations.

This module is fixed to a 12 tone system.

=head1 METHODS

Any method may B<croak> if something is awry with the input. Methods are
inherited from the parent class, L<Music::Tension>.

=over 4

=item B<new> I<optional params>

Constructor. Accepts optional parameters that specify alternate values
instead of the defaults.

=over 4

=item *

I<big_dissonance> is a boolean that controls whether dissonant intervals
greater than an octave are allowed. They are allowed by default.

=item *

I<interior> must be a hash reference that must contain all intervals
from C<0> to C<11> inclusive. This hash is used to check interior voice
intervals (if any) in the pitch set (chord) passed to the B<vertical>
method. The default values follow Norden 1969 and are more relaxed than
what I<tensions> permits.

The values for the intervals are treated as booleans where C<0>
indicates dissonance and C<1> consonance.

=item *

I<octave_allow> is a boolean that indicates whether the octave is
allowed. Octaves are allowed by default. This flag is necessary because
a rules system might disallow the unison of two notes but allow for
octaves of the same; octaves would otherwise be modulated down and
treated as a unison.

=item *

I<tensions> must be a hash reference that must contain all intervals
from C<-11> to C<11> inclusive. The default values are typical but may
need to be adjusted for melodic use or different opinions of
counterpoint, such as the style that treats the perfect fourth as
consonant.

The values for the intervals are treated as booleans where C<0>
indicates dissonance and C<1> consonance.

=back

=item B<pitches> I<pitch1>, I<pitch2>

Accepts two pitches (integers) and returns a boolean indicating whether
the interval formed is consonant or not. If I<pitch1> is higher than
I<pitch2> a negative interval will be used; this is why I<tensions>
requires negative interval values.

=item B<usable_offsets> I<phrase1>, I<phrase2>

Calls B<offset_tensions> (from L<Music::Tension>) with the given phrases
(array references of integers) and returns a list of the non-zero
offsets that have only consonant intervals between the two phrases. If
any; otherwise, the empty list is returned.

This is suitable for canon, fugue, or imitation where having a phrase
(possibly one that has been fiddled with according to various rules set
down many centuries ago) that can be used with the original phrase at
different offsets is desirable.

See C<eg/dorian-fugue-subject> in this module's distribution for an
example use of this method.

=item B<vertical> I<pset>

Accepts an array reference that should be a list of integers. Returns a
boolean indicating whether the pitches are consonant or not. The lowest
(or root) pitch will be checked for consonance (via B<pitches>, and thus
the I<tensions> table) against every higher pitch. The other pitches, if
possible, will each be checked against any higher pitches using the
I<interior> interval table.

Interior pitches will also follow the rules for I<octave_allow> and
B<big_dissonance>.

=back

=head1 MELODY

Allowed horizontal (melodic) intervals depend on the rule system; Norden
1969 allows for:

  use constant { DISS => 0, CONS => 1 };

  my $melody = Music::Tension::Counterpoint->new(
      octave_allow => 1, # octaves are okay
      tensions     => {
          0   => DISS,   # repeated notes
          1   => CONS,   # minor second
          2   => CONS,   # major second
          3   => CONS,   # minor third
          4   => CONS,   # major third
          5   => CONS,   # fourth
          6   => CONS,   # the evil, evil tritone
          7   => CONS,   # fifth
          8   => CONS,   # minor sixth
          9   => DISS,   # major sixth
          10  => DISS,   # minor seventh
          11  => DISS,   # major seventh
          -1  => CONS,
          -2  => CONS,
          -3  => CONS,
          -4  => CONS,
          -5  => CONS,
          -6  => CONS,
          -7  => CONS,
          -8  => CONS,
          -9  => DISS,
          -10 => DISS,
          -11 => DISS,
      }
  );
  
  # repeated note, not okay (okay in 1st species)
  $melody->pitches( 60, 60 );     # 0

Norden however recommends a direction change and step following a
tritone leap, various restrictions to avoid outlining certain chords
over multiple horizontal intervals, and other such complications. Those
would need more code to support. Other authors restrict the use of
tritone leaps in melody as being difficult to sing, or may allow for
upwards leaps of a minor 6th but not downwards ones, etc.

=head1 SEE ALSO

=over 4

=item *

"Fundamental Counterpoint", Hugo Norden, 1969.

=item *

"Polyphonic Dissonance", Jeremy Mates, 2019.
https://github.com/thrig/music/musicref

=item *

"The Study of Fugue", Alfred Mann, 1965.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Jeremy Mates

https://opensource.org/licenses/BSD-3-Clause

=cut
