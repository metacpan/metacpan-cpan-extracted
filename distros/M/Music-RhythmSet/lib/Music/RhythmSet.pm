# -*- Perl -*-
#
# sets of rhythms, comprised of one or more voices (or tracks) and
# various utility functions

package Music::RhythmSet;
our $VERSION = '0.01';

use 5.24.0;
use warnings;
use Carp qw(croak);
use List::GroupingPriorityQueue qw(grpriq_add);
use MIDI;
use Moo;
use namespace::clean;

use Music::RhythmSet::Voice;

has stash  => ( is => 'rw' );
has voices => ( is => 'rw', default => sub { [] } );

# perldoc Moo
sub BUILD {
    my ( $self, $args ) = @_;
    # so ->new->add(...) can instead be written ->new(voicel => [...])
    if ( exists $args->{voicel} ) {
        croak "invalid voicel"
          unless defined $args->{voicel}
          and ref $args->{voicel} eq 'ARRAY';
        $self->add( $args->{voicel}->@* );
        delete $args->{voicel};
    }
}

########################################################################
#
# METHODS

sub add {
    my ( $self, @rest ) = @_;
    croak "nothing to add" unless @rest;

    my $maxid = $self->voices->$#*;

    for my $ref (@rest) {
        croak "invalid voice parameters"
          unless defined $ref and ref $ref eq 'HASH';
        $ref->{id} = ++$maxid;
        push $self->voices->@*, Music::RhythmSet::Voice->new( $ref->%* );
    }

    return $self;
}

sub advance {
    my ( $self, $count, %param ) = @_;
    # this is done stepwise for each voice so that TTL expirations and
    # thus potential new patterns are more likely to be visible to other
    # voices. voices that depend on other voices should therefore be
    # added after those other voices (or there could be a two- or N-pass
    # system to resolve any inter-voice pattern generation difficulties,
    # but that's not supported here)
    for ( 1 .. $count // 1 ) {
        for my $voice ( $self->voices->@* ) {
            $param{set} = $self;
            $voice->advance( 1, %param );
        }
    }
    return $self;
}

sub changes {
    my ( $self, %param ) = @_;

    for my $cb (qw{header voice}) {
        croak "need $cb callback"
          unless defined $param{$cb}
          and ref $param{$cb} eq 'CODE';
    }

    # patterns can be of different lengths between voices (or can vary
    # over time inside a voice), though may be the same in which case
    # the caller can divide the beat count by however many beats there
    # are in a measure to obtain the measure number. otherwise, the
    # "measure" is the number of beats since the start of the replay log
    $param{divisor} //= 1;
    $param{max}     //= ~0;

    my $queue = [];

    for my $voice ( $self->voices->@* ) {
        my $beat = 0;
        for my $ref ( $voice->replay->@* ) {
            my ( $bpat, $ttl ) = $ref->@*;
            # build a priority queue of when voices change their pattern
            grpriq_add( $queue, $beat, [ $voice->id, $bpat ] );
            $beat += $ttl * $bpat->@*;
        }
    }

    my ( @curpat, @curpat_str );

    # parse the queue for pattern changes and let the caller decide how
    # to act on the results (see eg/beatinator for one way)
    for my $entry ( $queue->@* ) {    # [[id,[bp]],...],beats
        my $measure = $entry->[1] / $param{divisor};
        last if $measure >= $param{max};

        my ( @changed, @repeat );

        for my $ref ( $entry->[0]->@* ) {
            my ( $id, $bpat ) = $ref->@*;
            $changed[$id] = 1;
            $curpat[$id]  = $bpat;
            my $bstr = join( '', $bpat->@* ) =~ tr/10/x./r;
            if ( $bstr eq ( $curpat_str[$id] // '' ) ) {
                $repeat[$id] = 1;
            }
            $curpat_str[$id] = $bstr;
        }

        $param{header}->($measure);

        for my $id ( 0 .. $#curpat ) {
            $param{voice}->(
                $measure, $id, $curpat[$id], $curpat_str[$id], $changed[$id], $repeat[$id]
            );
        }
    }

    return $self;
}

sub clone {
    my ($self) = @_;

    my $new = Music::RhythmSet->new;
    my @voices;

    for my $voice ( $self->voices->@* ) {
        push @voices, $voice->clone;
    }

    $new->voices( \@voices );

    return $new;
}

sub from_string {
    my ( $self, $str, %param ) = @_;
    croak "need a string" unless defined $str and length $str;

    $param{rs} //= "\n";
    if ($param{sep}) {
        $param{sep} = qr/\Q$param{sep}\E/;
    } else {
        $param{sep} = qr/\s+/;
    }

    my $linenum = 1;
    my @newplay;
    my $voices = $self->voices;

    for my $line ( split /\Q$param{rs}/, $str ) {
        next if $line =~ m/^\s*(?:#|$)/;
        # the limits are to prevent overly long strings from being
        # parsed; if this is a problem write a modified from_string that
        # does allow such inputs, or modify the unused <beat> count
        if ($line =~ m/^
            (?<beat>\d{1,10})     $param{sep}
            (?<id>\d{1,3})        $param{sep}
            (?<bstr>[x.]{1,256})  $param{sep}
            (?<ttl>\d{1,5})       \s*(?:[#].*)?
            $/ax
        ) {
            # only +1 ID over max is allowed to avoid creating a sparse
            # voices list; this means that input that starts with voice
            # 1 (or higher) will be rejected, or if voice 4 is seen
            # before the first entry for voice 3 that too will be
            # rejected. this might happen if a sort reordered the events
            # and there was not a sub-sort to keep the voice IDs in
            # ascending order
            if ( $voices->$#* == 0 or $+{id} == $voices->$#* + 1 ) {
                $self->add( {} );
            } elsif ( $+{id} > $voices->$#* ) {
                croak "ID out of range '$+{id}' at line $linenum";
            }
            push $newplay[ $+{id} ]->@*, [ [ split //, $+{bstr} =~ tr/x./10/r ], $+{ttl} ];
        } else {
            croak "invalid record at line $linenum";
        }
        $linenum++;
    }

    # this complication is to make changes to the replay log more atomic
    # given that the above can die mid-parse. this array can be sparse
    # (e.g. if four voices already exist and the input only has records
    # for voices 0 and 2)
    for my $id ( 0 .. $#newplay ) {
        push $voices->[$id]->replay->@*, $newplay[$id]->@* if defined $newplay[$id];
    }

    return $self;
}

sub measure {
    my ( $self, $num ) = @_;
    for my $voice ( $self->voices->@* ) {
        $voice->measure($num);
    }
    return $self;
}

sub to_ly {
    my ( $self, %param ) = @_;

    for my $id ( 0 .. $self->voices->$#* ) {
        for my $pram (qw/dur maxm note rest time/) {
            $param{voice}[$id]{$pram} = $param{$pram}
              if exists $param{$pram} and not exists $param{voice}[$id]{$pram};
        }
    }

    my $id = 0;
    return [ map { $_->to_ly( $param{voice}->[ $id++ ]->%* ) } $self->voices->@* ];
}

sub to_midi {
    my ( $self, %param ) = @_;

    $param{format} //= 1;
    $param{ticks}  //= 96;

    for my $id ( 0 .. $self->voices->$#* ) {
        for my $pram (qw/chan dur maxm note notext tempo sustain velo/) {
            $param{track}[$id]{$pram} = $param{$pram}
              if exists $param{$pram} and not exists $param{track}[$id]{$pram};
        }
    }

    my $id = 0;
    return MIDI::Opus->new(
        {   format => $param{format},
            ticks  => $param{ticks},
            tracks =>
              [ map { $_->to_midi( $param{track}->[ $id++ ]->%* ) } $self->voices->@* ]
        }
    );
}

sub to_string {
    my ( $self, @rest ) = @_;

    my $str = '';

    for my $voice ( $self->voices->@* ) {
        $str .= $voice->to_string(@rest);
    }

    return $str;
}

1;
__END__

=head1 NAME

Music::RhythmSet - sets of rhythms and various generation functions

=head1 SYNOPSIS

  use 5.24.0;
  use Music::RhythmSet;
  use Music::RhythmSet::Util qw(rand_onsets);
  
  my $rest = [ (0) x 16 ];
  
  # randomly select a rhythm with five onsets in 16 beats
  # that will live for eight measures
  sub newpat { rand_onsets(5, 16), 8 }
  
  # three voices, with a delayed entrance on two of them
  my $set = Music::RhythmSet->new->add(
      { pattern => rand_onsets(5, 16), ttl => 16 },
      { next => \&newpat, pattern => $rest, ttl => 2 },
      { next => \&newpat, pattern => $rest, ttl => 4 },
  );
  
  # generate 8 measures of (probably) noise
  $set->advance(8);
  
  # export with different notes for each track
  $set->to_midi(
      track => [ {}, { note => 67 }, { note => 72 } ]
  )->write_to_file("noise.midi");

=head1 DESCRIPTION

This module supports sets of rhythms, each being a
L<Music::RhythmSet::Voice> object, which is where most of the action
happens. L<Music::RhythmSet::Util> offers various rhythm generation and
classification functions. Rhythms have a lifetime (ttl), and can have a
callback function that can set a new rhythm and time-to-live when the
ttl expires. Rhythms can be exported in various formats.

See C<eg/beatinator> and C<eg/texty> in the distribution for this module
for various ways to generate MIDI, import from string form, etc.

Various calls will throw exceptions if something goes awry.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</ATTRIBUTES>; the B<add> method
or special I<voicel> argument would be the most typical means of adding
voices, though.

  # new object, add two empty voices
  $set = Music::RhythmSet->new->add({},{});

  # same as the above
  $set = Music::RhythmSet->new(voicel => [{},{}]);

  # same as the above
  $set = Music::RhythmSet->new;
  $set->voices([
    Music::RhythmSet::Voice->new(id => 0),
    Music::RhythmSet::Voice->new(id => 1)
  ]);

However, voices probably need at least a B<pattern> and B<ttl> set, and
even then probably also a B<next> callback function. Or a B<replay> log
could be manually supplied...

=head2 BUILD

Constructor helper subroutine. See L<Moo>.

=head1 ATTRIBUTES

=over 4

=item B<stash>

A place for the caller to store whatever. The B<advance> method passes
the current set object down to B<next> callback code as the I<set>
parameter; individual voices could use the set object stash as a shared
variable store.

This attribute is not used by code in this distribution.

=item B<voices>

Array reference of voices. These are L<Music::RhythmSet::Voice> objects.
Probably should not be manually edited, unless you know what you are
doing. Use the B<add> method to add more voices to a set.

=back

=head1 METHODS

=over 4

=item B<add> I<voice> [ I<voice> ... ]

Each I<voice> must be a hash reference that is fed to the constructor of
L<Music::RhythmSet::Voice>. Any caller-supplied I<id> attribute will
however be ignored as this module manages those values itself.

=item B<advance> I<count> [ I<param> ]

This call steps each of the voices forward by I<count> measures, which
may result in new entries into the replay log for each voice, as well as
B<next> callbacks being run to set new rhythms. Voices are advanced in
turn from first to last in the voices list.

I<param> is used to pass settings down to the B<advance> method of
L<Music::RhythmSet::Voice> and from there into the B<next> callback. In
particular the I<set> attribute will contain a reference to the C<$set>
object involved should the voices need to query other voices during a
B<next> callback, or access the set B<stash>.

=item B<changes> I<param>

Utility method that shows when voices change their patterns in their
replay logs, and what other patterns are active at those points. Voices
must have something in their replay log before this method is called.

The C<eg/beatinator> script in this module's distribution shows one way
to use this call.

There are two mandatory parameters:

=over 4

=item I<header>

Callback; it is passed the current "measure" number of the change. This
happens before the I<voice> callback works through each voice.

=item I<voice>

Callback; called for each voice in turn. It is passed the "measure"
number, voice ID, the current pattern as an array reference, the current
pattern as a beatstring, a boolean for whether the pattern might have
changed, and another boolean that indicates whether the pattern was a
repeat of the previous.

Two booleans are used because a B<next> callback could return the same
pattern as before; this will create a new entry in the replay log
(what the first boolean indicates) that may be the same as before (the
second boolean).

=back

And two optional parameters:

=over 4

=item I<divisor>

A positive integer that indicates how many beats there are in a measure.
C<1> by default, which means a "measure" is the number of beats since
the beginning of the replay log (counting from 0, not 1). A divisor of
C<16> (and assuming the I<pattern> used are all of length 16) would mean
that the term "measure" no longer needs scare quotes, as it would
represent a measure number as they are more typically known (except for
the counting from zero thing, which musicians usually do not do).

=item I<max>

A positive integer for when to stop working through the "measures" of
the replay log. Influenced by the I<divisor>.

=back

=item B<clone>

Clones each of the voices and returns a new L<Music::RhythmSet> object
with those cloned voices.

=item B<from_string> I<string> [ I<param> ]

Attempts to parse the I<string> (presumably from B<to_string> or of
compatible form) and adds any C<pattern,ttl> parsed to the replay log of
each voice. The events are assumed to be in sequential order for each
voice; the I<beat-count> field is ignored. The ID values must be in
ascending order (at least when first encountered). Same parameters as
B<to_string>. A default split on whitespace delimits the fields.

C<eg/texty> in the distribution for this module uses this method.

Lines that only contain whitespace, are empty, or start with a C<#> that
may have whitespace before it will be skipped. Trailing whitespace and
C<#> comments on lines are ignored.

=item B<measure> I<count>

Sets the B<measure> attribute of each voice to the given I<count>.
Possibly useful when reloading from a replay file or under similar
manual edits to the voices so that any subsequent B<advance> calls use
the correct measure number in any relevant B<next> callback
calculations.

This assumes the measures (patterns) of the voices are all the same
size, which may not be true. To make your life easier, you probably do
want the patterns to be all of the same length, which for 16-beat
against 12-beat would require first converting everything into

  $ perl -MMath::BigInt -E 'say Math::BigInt->new(16)->blcm(12)'
  48

beat length patterns. See also the B<upsize> function in
L<Music::RhythmSet::Util>.

=item B<to_ly> [ I<param> ]

Returns an array reference of strings that contain the replay log of
each voice formatted for LilyPond.

  use File::Slurper 'write_text';
  my $i = 0;
  for my $str ($set->to_ly->@*) {
      write_text("noise.$i.ly", $str);
      $i++;
  }

These files can then be included from another LilyPond file:

  \version "2.18.2"
  lino = \relative c' { \include "noise.0.ly" }
  lipa = \relative c' { \include "noise.1.ly" }
  lire = \relative c' { \include "noise.2.ly" }
  zgike = {
    \new StaffGroup <<
      \new Staff \lino
      \new Staff \lipa
      \new Staff \lire
    >>
  }
  \score { \zgike \layout { } \midi { } }

The LilyPond "Notation Reference" documentation may be helpful.

The I<param> can include a I<voice> element; this allows the I<dur>,
I<note>, and I<rest> parameters of the individual voices to be
customized. I<dur>, I<note>, and I<rest> can also be set at the top
level to change the defaults for all the voices, unless there is a more
specific setting for a voice. I<maxm> limits the output to a particular
measure number.

  my $ret = $set->to_ly(
      # quarter notes for all voices
      dur => 4,
      # voice specifics
      voice => [
          { note => 'b' },
          { note => 'a', rest => 's' },
          { note => 'c' }
      ]
  );

=item B<to_midi> [ I<param> ]

Returns a I<MIDI::Opus> object containing tracks for each of the voices.
Use the B<write_to_file> call of that object to produce a MIDI file.

Parameters accepted include I<format> (probably should be C<1>),
I<ticks>, and I<track>. I<track> allows parameters for the
L<Music::RhythmSet::Voice> B<to_midi> call to be passed to a specific
voice. These can also be specified in this B<to_midi> call to apply to
all the tracks:

  my $opus = $set->to_midi(
      chan  => 9,
      tempo => 640_000,
      track => [ {}, { note => 67 }, { note => 72 } ]
  );
  $opus->write_to_file("noise.midi");

L<MIDI::Event> documents most of the values the I<track> parameters can
take. I<maxm> will limit the output to the given number of measures.

=item B<to_string> [ I<param> ]

Converts the replay logs of the voices (if any) into a custom text
format. See the B<to_string> method of L<Music::RhythmSet::Voice>
for details.

=back

=head1 BUGS

<https://github.com/thrig/Music-RhythmSet>

=head1 SEE ALSO

L<MIDI>, L<Music::AtonalUtil>, L<Music::RecRhythm>

"The Geometry of Musical Rhythm" by Godfried T. Toussaint.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
