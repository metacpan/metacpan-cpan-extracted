# -*- Perl -*-
#
# a voice (or track) that is comprised of various patterns repeated
# ttl times

package Music::RhythmSet::Voice;
our $VERSION = '0.02';

use 5.24.0;
use warnings;
use Carp qw(confess croak);
use MIDI;
use Moo;
use namespace::clean;

use constant { NOTE_ON => 1, NOTE_OFF => 0, EVENT => 0, DTIME => 1 };

has id      => ( is => 'rw' );
has next    => ( is => 'rw' );
has measure => ( is => 'rw', default => sub { 0 } );
has pattern => ( is => 'rw' );
has replay  => ( is => 'rw', default => sub { [] } );
has stash   => ( is => 'rw' );
has ttl     => ( is => 'rw', default => sub { 0 } );

# perldoc Moo
sub BUILD {
    my ( $self, $args ) = @_;
    if ( exists $args->{pattern} and exists $args->{ttl} ) {
        croak "invalid ttl" if $args->{ttl} < 1;
        croak "invalid pattern"
          unless defined $args->{pattern}
          and ref $args->{pattern} eq 'ARRAY'
          and $args->{pattern}->@*;
        push $self->replay->@*, [ $args->{pattern}, $args->{ttl} ];
    }
}

########################################################################
#
# METHODS

sub advance {
    my ( $self, $count, %param ) = @_;

    my $measure = $self->measure;

    for ( 1 .. $count // 1 ) {
        my $ttl = $self->ttl - 1;

        $param{measure} = $measure++;
        $param{pattern} = $self->pattern;

        if ( $ttl <= 0 ) {
            my $next = $self->next;

            confess "no next callback"
              unless defined $next and ref $next eq 'CODE';

            ( $param{pattern}, $ttl ) = $next->( $self, %param );

            confess "no pattern set"
              unless defined $param{pattern}
              and ref $param{pattern} eq 'ARRAY'
              and $param{pattern}->@*;
            confess "invalid ttl" if $ttl < 1;

            $self->pattern( $param{pattern} );

            push $self->replay->@*, [ $param{pattern}, $ttl ];
        }

        $self->ttl($ttl);
    }

    $self->measure($measure);

    return $self;
}

# there is no ->changes method; meanwhile, put the single voice into a
# set object and call ->changes over there if you need that for a
# single voice:
#
#   my $set = Music::RhythmSet->new;
#   $set->voices([$voice]);
#   $set->changes(...)

sub clone {
    my ( $self, %param ) = @_;

    $param{newid} //= $self->id;

    my $new = Music::RhythmSet::Voice->new(
        id => $param{newid},
        map { $_, scalar $self->$_ } qw(next measure ttl),
    );

    # these 'die' as the bad attribute values were likely not assigned
    # anywhere near the current stack. use Carp::Always or such if you
    # do need to find out where your code calls into here, but you
    # probably instead want to look at any ->pattern(...) or
    # ->replay(...) calls in your code
    my $pat = $self->pattern;
    if ( defined $pat ) {
        die "invalid pattern" unless ref $pat eq 'ARRAY' and $pat->@*;
        $new->pattern( [ $pat->@* ] );
    }

    my $ref = $self->replay;
    if ( defined $ref ) {
        die "replay must be an array reference"
          unless ref $ref eq 'ARRAY';
        die "replay array must contain array references"
          unless ref $ref->[0] eq 'ARRAY';
        $new->replay( [ map { [ [ $_->[0]->@* ], $_->[1] ] } $ref->@* ] );
    }

    return $new;
}

sub from_string {
    my ( $self, $str, %param ) = @_;
    croak "need a string" unless defined $str and length $str;

    $param{rs} //= "\n";
    if ( $param{sep} ) {
        $param{sep} = qr/\Q$param{sep}\E/;
    } else {
        $param{sep} = qr/\s+/;
    }

    my $linenum = 1;
    my @newplay;

    for my $line ( split /\Q$param{rs}/, $str ) {
        next if $line =~ m/^\s*(?:#|$)/;
        # the limits are to prevent overly long strings from being
        # parsed; if this is a problem write a modified from_string that
        # does allow such inputs, or modify the unused <beat> count
        if ($line =~ m/^
            (?<beat>\d{1,10})     $param{sep}
            (?<id>.*?)            $param{sep}
            (?<bstr>[x.]{1,256})  $param{sep}
            (?<ttl>\d{1,5})       \s*(?:[#].*)?
            $/ax
        ) {
            # NOTE <id> is unused and is assumed to be "this voice"
            # regardless of what it contains
            push @newplay, [ [ split //, $+{bstr} =~ tr/x./10/r ], $+{ttl} ];
        } else {
            croak "invalid record at line $linenum";
        }
        $linenum++;
    }

    push $self->replay->@*, @newplay;

    return $self;
}

# TODO some means of note reduction and optional note sustains
# over rests
sub to_ly {
    my ( $self, %param ) = @_;

    my $replay = $self->replay;
    croak "empty replay log"
      unless defined $replay
      and ref $replay eq 'ARRAY'
      and $replay->@*;

    $param{dur}  //= '16';
    $param{note} //= 'c';
    $param{rest} //= 'r';

    my $id   = $self->id // '';
    my $ly   = '';
    my $maxm = $param{maxm} // ~0;

    for my $ref ( $replay->@* ) {
        my ( $bpat, $ttl ) = $ref->@*;
        $ttl = $maxm if $ttl > $maxm;

        $ly .= "  % v$id " . join( '', $bpat->@* ) =~ tr/10/x./r . " $ttl\n";
        if ( $param{time} ) {
            $ly .= '  \time ' . $bpat->@* . '/' . $param{time} . "\n";
        }
        my $str = ' ';
        for my $x ( $bpat->@* ) {
            if ( $x == NOTE_ON ) {
                $str .= ' ' . $param{note} . $param{dur};
            } else {
                $str .= ' ' . $param{rest} . $param{dur};
            }
        }
        $ly .= join( "\n", ($str) x $ttl ) . "\n";

        $maxm -= $ttl;
        last if $maxm <= 0;
    }
    return $ly;
}

sub to_midi {
    my ( $self, %param ) = @_;

    my $replay = $self->replay;
    croak "empty replay log"
      unless defined $replay
      and ref $replay eq 'ARRAY'
      and $replay->@*;

    # MIDI::Event, section "EVENTS AND THEIR DATA TYPES"
    $param{chan}  //= 0;
    $param{dur}   //= 20;
    $param{note}  //= 60;
    $param{tempo} //= 500_000;
    $param{velo}  //= 90;        # "default value" per lilypond scm/midi.scm

    my $track  = MIDI::Track->new;
    my $events = $track->events_r;

    my $delay;
    my $id       = $self->id // '';
    my $leftover = 0;
    my $maxm     = $param{maxm} // ~0;

    push $events->@*, [ 'track_name', 0, 'voice' . ( length $id ? " $id" : '' ) ];
    push $events->@*, [ 'set_tempo',  0, $param{tempo} ];

    for my $ref ( $replay->@* ) {
        my ( $bpat, $ttl ) = $ref->@*;
        $ttl = $maxm if $ttl > $maxm;

        push $events->@*,
          [ 'text_event', $leftover,
            "v$id " . join( '', $bpat->@* ) =~ tr/10/x./r . " $ttl\n"
          ];

        $delay = 0;
        my ( $onsets, $open, @midi );

        for my $x ( $bpat->@* ) {
            if ( $x == NOTE_ON ) {
                $onsets++;
                if ( defined $open ) {
                    push @midi, [ 'note_off', $delay, $param{chan}, $open, 0 ];
                    $delay = 0;
                }
                push @midi, [ 'note_on', $delay, map { $param{$_} } qw(chan note velo) ];
                $delay = $param{dur};
                $open  = $param{note};
            } else {
                if ( defined $open ) {
                    push @midi, [ 'note_off', $delay, $param{chan}, $open, 0 ];
                    $delay = 0;
                    undef $open;
                }
                $delay += $param{dur};
            }
        }
        if ( defined $open ) {
            push @midi, [ 'note_off', $delay, $param{chan}, $open, 0 ];
            $delay = 0;
        }

        # trailing rests (e.g. in a [1000] pattern) create a delay that
        # must be applied to the start of subsequent repeats of this
        # measure (if there is an onset that makes this possible) and
        # then must be passed on as leftovers for the next text_event
        if ( $delay and $onsets and $ttl > 1 ) {
            push $events->@*, @midi;
            $midi[0] = [ $midi[0]->@* ];
            $midi[0][1] += $delay;
            push $events->@*, (@midi) x ( $ttl - 1 );
        } else {
            push $events->@*, (@midi) x $ttl;
        }

        # delay from trailing rests *or* a full measure of rest
        $leftover = $delay;

        # remainder of full measures of rest, if any
        $leftover += $bpat->@* * $param{dur} * ( $ttl - 1 ) unless $onsets;

        $maxm -= $ttl;
        last if $maxm <= 0;
    }

    # end of track event for sustain to have something to extend out to,
    # and so that different trailing rests between different voices are
    # less likely to exhibit ragged track ends. it also simplifies the
    # handling of the last event in the stream, below
    push $events->@*, [ 'text_event', $leftover, "v$id EOT\n" ];

    # and here the MIDI is modified if need be -- the above is already
    # complicated, and it's (somewhat) easier to cut events out and
    # fiddle with delays on the completed stream
    if ( $param{sustain} or $param{notext} ) {
        my $i = 0;
        while ( $i < $events->$#* ) {
            if ( $param{sustain} and $events->[$i][0] eq 'note_off' ) {
                # extend delay on the note_off to the next note_on;
                # there might be a text_event between
                my $delay = 0;
                my $j     = $i + 1;
                while (1) {
                    if ( $events->[$j][EVENT] eq 'text_event' and $events->[$j][DTIME] > 0 ) {
                        $delay += $events->[$j][DTIME];
                        $events->[$j][DTIME] = 0;
                    } elsif ( $events->[$j][EVENT] eq 'note_on' ) {
                        if ( $events->[$j][DTIME] > 0 ) {
                            $delay += $events->[$j][DTIME];
                            $events->[$j] = [ $events->[$j]->@* ];
                            $events->[$j][DTIME] = 0;
                        }
                        last;
                    }
                    last if ++$j > $events->$#*;
                }
                $events->[$i] = [ $events->[$i]->@* ];
                $events->[$i][DTIME] += $delay;

            } elsif ( $param{notext} and $events->[$i][EVENT] eq 'text_event' ) {
                my $delay = $events->[$i][DTIME];
                splice $events->@*, $i, 1;
                $events->[$i] = [ $events->[$i]->@* ];
                $events->[$i][DTIME] += $delay;
                next;    # examine the new event at the current index
            }
            $i++;
        }

        # assume the final event is the EOT text_event
        pop $events->@* if $param{notext};
    }

    return $track;
}

sub to_string {
    my ( $self, %param ) = @_;

    my $replay = $self->replay;
    croak "empty replay log"
      unless defined $replay
      and ref $replay eq 'ARRAY'
      and $replay->@*;

    $param{divisor} //= 1;
    $param{rs}      //= "\n";
    $param{sep}     //= "\t";

    my $beat = 0;
    my $id   = $self->id    // '';
    my $maxm = $param{maxm} // ~0;
    my $str  = '';

    for my $ref ( $replay->@* ) {
        my ( $bpat, $ttl ) = $ref->@*;
        my $bstr = join( '', $bpat->@* ) =~ tr/10/x./r;
        $ttl = $maxm if $ttl > $maxm;

        $str .=
          join( $param{sep}, $beat / $param{divisor}, $id, $bstr, $ttl ) . $param{rs};

        $beat += $ttl * $bpat->@*;
        $maxm -= $ttl;
        last if $maxm <= 0;
    }

    return $str;
}

1;
__END__

=head1 NAME

Music::RhythmSet::Voice - a rhythmic line

=head1 SYNOPSIS

  use Math::Random::Discrete;
  use Music::RhythmSet::Util qw(write_midi);
  use Music::RhythmSet::Voice;
  
  # different selection odds for three patterns
  my $pat = Math::Random::Discrete->new(
      [ 15,
        30,
        20, ],
      [ [qw/1 0 1 0 0 1/],
        [qw/1 0 1 0 0 0/],
        [qw/1 0 0 0 1 0/] ]);
  # and three ttl
  my $ttl = Math::Random::Discrete->new(
      [ 25, 45, 15, ],
      [ 1,  2,  4 ]);

  # callback: pick a random pattern and ttl
  sub newpat { $pat->rand, $ttl->rand }
  
  my $voice = Music::RhythmSet::Voice->new(
      next => \&newpat
  );
  
  # generate 32 measures of (probably) noise
  $voice->advance(32);

  # export
  my $track = $voice->to_midi(sustain => 1);
  write_midi('noise.midi', $track);

=head1 DESCRIPTION

This module encapsulates a single rhythmic voice (or track) and has
various methods to advance and change the rhythm over time. Rhythms can
be exported in various formats. L<Music::RhythmSet> can store multiple
voices, but most of the work is done by this module for each voice.

See C<eg/beatinator> and C<eg/texty> in the distribution for this module
for various ways to generate MIDI, import from string form, etc.

Various calls will throw exceptions if something goes awry.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</ATTRIBUTES>. If both a
I<pattern> and a I<ttl> are given they will be automatically added to
the I<replay> log. Another option is to only build out the I<replay> log
via I<next> callback through the B<advance> method, or to set the
I<replay> log manually. B<measure> may need to be set manually if the
I<replay> log is changed manually.

=head2 BUILD

Constructor helper subroutine. See L<Moo>.

=head1 ATTRIBUTES

=over 4

=item B<id>

An ID for the voice. This is set automatically by L<Music::RhythmSet>
but could be set manually. Must not be changed when the voice belongs to
a L<Music::RhythmSet> object. Otherwise it should ideally be a small
non-negative integer.

=item B<next> I<code-reference>

A callback that runs when the I<ttl> expires. This routine must return
a new pattern and TTL. The callback is passed a reference to the
L<Music::RhythmSet::Voice> object, and a set of parameters with
various metadata. It may help to log what is going on:

  use Data::Dumper;
  use Music::RhythmSet::Voice;

  my $voice = Music::RhythmSet::Voice->new(
      next => sub {
          my ( $self, %param ) = @_;
          warn "CALLBACK\n", Dumper \%param;
          return [ 1, 0, 0 ], 8;
      }
  );

  $voice->advance( 16, _foo => 'bar' );

  warn "REPLAY\n", Dumper $voice->replay;

If no callback function is set B<advance> calls may throw an error.

The parameters may optionally be passed in through B<advance> by the
caller; certain parameters are set by code in this module. In particular
the I<measure> number (counting from 0, not 1) and the current
I<pattern> are set by B<advance>.

The B<advance> method of L<Music::RhythmSet> will add a I<set>
parameter so that callback code can access the set object that contains
the voices.

Callers may want to prefix any custom parameters with C<_> to minimize
potential conflicts with future versions of this module.

=item B<measure>

The current measure number of the voice. The first measure is C<0>, not
C<1>, though B<measure> will be C<1> following the first C<advance(1)>
call. The B<next> callback can make use of this to make decisions based
on the measure number, as B<measure> is passed in as a parameter:

  ... = Music::RhythmSet::Voice->new(
      next => sub {
          my ($self, %param) = @_;
          if ($param{measure} == 0) {   # first measure
              ...

The length of a measure will change if the length of the I<pattern> used
varies. This may complicate various things that rely on measure numbers,
especially if there are multiple voices that use different pattern
lengths. See B<changes> in the code for L<Music::RhythmSet> for one way
to handle such a case. Another approach would be to resize all the
patterns to be the "least common multiple" length so that the pattern
length does not vary; see B<upsize> in L<Music::RhythmSet::Util>.

=item B<pattern>

The current rhythmic pattern, an array reference of zeros and ones;
these might be called "beats" where a C<1> represents an onset, and C<0>
silence. A B<pattern> may be considered as a single measure of music (of
some number of beats which is the length of the B<pattern>), though
B<measure> is used for something else in this code.

=item B<replay>

An array reference of I<pattern> and I<ttl> pairs, usually created by
calling B<advance> for some number of measures with a suitable B<next>
callback set.

=item B<stash>

A place for the caller to store whatever. For example, a voice could
vary between a rhythm for seven measures and silence for one using
the stash:

  sub silence {
      my ( $self, %param ) = @_;
      $self->next( $self->stash );  # restore previous
      return [ (0) x 16 ], 1;
  }

  sub voice {
      my ( $self, %param ) = @_;
      $self->stash( $self->next );  # save current method
      $self->next( \&silence );     # go quiet
      return [qw/1 0 0 0 1 0 0 0 1 0 0 0 1 0 1 0/], 7;
  }

  Music::RhythmSet::Voice->new( next => \&voice );

The above code uses the stash as a scalar; a hash reference would make
more sense if multiple values need be passed around. The above could
also be done in a single function that keeps track of how many times it
has been called

  sub voice {
      state $yesno = 0;
      $yesno ^= 1;

      if ($yesno) {
          return [qw/1 0 0 0 1 0 0 0 1 0 0 0 1 0 1 0/], 7;
      } else {
          return [ (0) x 16 ], 1;
      }
  }

though changing the callback function may suit more complicated
arrangements.

The B<stash> attribute is not used by code in this distribution.

=item B<ttl>

Time-to-live of the current B<pattern>. Probably should not be
changed manually.

=back

=head1 METHODS

=over 4

=item B<advance> I<count> [ I<param> ]

Step the voice forward by I<count> measures. This may trigger the
B<next> attribute callback code and may result in new entries in the
replay log.

The various B<to_*> methods will fail if there is nothing in the replay
log; this can happen when the replay log is generated only from B<next>
calls and you forget to call B<advance> to make those calls happen.

=item B<clone> [ newid => I<new-id> ]

Clones the object with a I<new-id> that if unset will be the same B<id>
as the current object. The ID is optional because the
L<Music::RhythmSet> B<clone> method must preserve the ID as that value
must track the array index in the I<voices> list; other uses may need
different ID values.

=item B<from_string> I<string> [ I<param> ]

Attempts to parse and push the I<string> (presumably from B<to_string>
or of compatible form) onto the replay log. The ID parameter is
ignored; all events are assumed to belong to this voice. The events are
assumed to be in sequential order; the I<beat-count> field is ignored.
Same parameters as B<to_string>. A default split on whitespace delimits
the fields.

Lines that only contain whitespace, are empty, or start with a C<#> that
may have whitespace before it will be skipped. Trailing whitespace and
C<#> comments on lines are ignored.

=item B<to_ly> [ I<param> ]

Returns the replay log formatted for LilyPond (a text string).
Parameters include I<dur> for the note duration (C<16> or C<4> or such),
the I<note> (C<a>, C<b>, etc), and I<rest> (probably should be C<r> or
C<s>). I<time> can be specified to add C<\time ...> statements to the
LilyPond output; assuming the patterns represent 16th notes

  $voice->to_ly(time => 16);

will for a I<pattern> 12 beats in length prefix those notes with C<\time
12/16>. This is limited: there is no way to turn C<12/16> into the more
common C<6/8> or C<3/4> forms.

I<maxm> will limit the number of measures produced from the replay log.

The LilyPond "Notation Reference" documentation may be helpful.

=item B<to_midi> [ I<param> ]

Encodes the replay log as a L<MIDI::Track> object and returns that.
Parameters include I<chan>, I<dur>, I<note>, I<tempo>, I<velo> (see
L<MIDI::Event>) as well as the I<sustain> and I<notext> booleans.

I<sustain> holds notes open until the next onset while I<notext> removes
the C<text_event> that document where each new C<pattern,ttl> pair
begins. I<sustain> may result in the final note of the track having a
different duration than in other repeats of the same measure.

Enabling I<notext> will increase the end-of-track raggedness; a MIDI
C<text_event> is used to demark where the track ends that I<notext>
will remove.

I<maxm> will limit the number of measures produced from the replay log.

=item B<to_string> [ I<param> ]

Converts the replay log of the voice (if any) into a custom text format
with the fields:

  beat-count voice-id beatstring ttl

This allows a numeric sort on the first column to order the records for
multiple voices together in a timeline view. The I<voice-id> must be
kept sorted in ascending order if B<from_string> will be used.

C<eg/texty> in the distribution for this module uses this method.

Parameters:

=over 4

=item I<divisor>

will divide the I<beat-count> by that value.

=item I<maxm>

will limit the number of measures produced from the replay log.

=item I<rs>

record separator, default C<\n>.

=item I<sep>

field separator, default C<\t>.

=back

=back

=head1 BUGS

None known.

=head1 SEE ALSO

L<MIDI>, L<Music::AtonalUtil>, L<Music::RecRhythm>

"The Geometry of Musical Rhythm" by Godfried T. Toussaint.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
