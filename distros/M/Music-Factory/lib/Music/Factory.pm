# -*- Perl -*-
#
# some factory class for your music factory class

package Music::Factory;
our $VERSION = '0.01';
use 5.26.0;
use warnings;
use Object::Pad 0.66;

# assembly line calls a generator object to fill an array of events up
# to a particular duration (musical section)
class Music::Factory::AssemblyLine {
    field $events :param;    # MIDI events (array ref)
    field $gen :param;       # generator object
    field $maxlen :param;    # maxiumum duration to generate

    method update ( $length = $maxlen ) {
        $gen->reset;          # NOTE may be removed
        my ( $epoch, $done, $overflow ) = ( 0, 0 );
        while (1) {
            my ( $dur, $elist ) = $gen->update( $epoch, $length );
            $epoch += $dur;
            if ( $epoch > $length ) {
                # kick overflows back to the caller to figure out, if
                # they care. generators can also do calculations to
                # avoid this situation, if they care
                $epoch -= $dur;
                $overflow = [ $dur, $elist ];
                last;
            } elsif ( $epoch == $length ) {
                $done = 1;
            }
            push $events->@*, $elist->@* if defined $elist and $elist->@*;
            last if $done;
        }
        return $epoch, $events, $overflow;
    }
}

# generator objects are called by an assembly line and generate events
# (an array reference) of some length (hopefully of the same duration as
# the events generated)
class Music::Factory::Generator {
    # NOTE reset() might be gotten rid of as a generator update() can
    # probably run similar code when $epoch == 0 but that would make the
    # update function a bit more complicated. if reset is common it
    # probably should be a distinct method, otherwise not?
    method reset () { }

    method update ( $epoch, $maxlen ) {
        die "need a better implementation";
    }
}

# a note of a particular duration; the pitch and velocity are done by
# function callbacks
class Music::Factory::Note :isa(Music::Factory::Generator) {
    field $chan :param = 0;    # MIDI channel
    field $pitch :param;       # callback
    field $velo :param;        # callback
    field $duration :param = 96;

    method update ( $epoch, $length ) {
        my $dur = $duration;
        # how to truncate to teh remaining length instead of
        # overflowing. whether this makes sense depends on what a
        # generator is doing. for example, if $dur is "too small" one
        # may instead want to insert silence of that amount
        #my $when = $epoch + $dur;
        #if ( $when > $length ) {
        #    $dur -= $when - $length;
        #    return $dur, [ [ note_off => $dur, $chan, 0, 0 ] ];
        #}
        my $p = $pitch->($epoch);
        return $duration,
          [ [ note_on  => 0,    $chan, $p, $velo->($epoch) ],
            [ note_off => $dur, $chan, $p, 0 ],
          ];
    }
}

# silence to fill the maximum duration given
class Music::Factory::Rest :isa(Music::Factory::Generator) {

    method update ( $epoch, $length ) {
        return $length, [ [ marker => $length, 'silence' ] ];
    }
}

1;
__END__

=head1 Name

Music::Factory - some factory class for your music factory class

=head1 SYNOPSIS

  use Data::Dumper;
  use Music::Factory;

  # this could be put into a MIDI::Track at the end
  my $events = [];

  my $silence = Music::Factory::AssemblyLine->new(
      events => $events,
      gen    => Music::Factory::Rest->new,
      maxlen => 48,
  );

  my $short = Music::Factory::AssemblyLine->new(
      events => $events,
      gen    => Music::Factory::Note->new(
          duration => 96,
          pitch    => sub { 60 },
          velo     => sub { 96 },
      ),
      maxlen => 96,
  );

  my $long = Music::Factory::AssemblyLine->new(
      events => $events,
      gen    => Music::Factory::Note->new(
          duration => 192,
          pitch    => sub { 60 },
          velo     => sub { 96 },
      ),
      maxlen => 192,
  );

  sub dit { $_->update for $short, $silence }
  sub dah { $_->update for $long, $silence }

  dit; dit; dit;
  dah; dah; dah;
  dit; dit; dit;

  print Dumper $events;

See also the C<eg/> directory of this module's distribution, as well as
the C<t/10-factory.t> test script.

=head1 DESCRIPTION

This module offers various classes that may assist with music
composition, notably an AssemblyLine that calls various generator
classes repeatedly until a section is filled to a particular length. The
generators might return L<MIDI> events, or anything that fits into an
array reference: lilypond notation, or who knows what.

Generators are assumed to be well behaved; a misbehaved generator
could return a negative duration, or invalid MIDI events, or even MIDI
events whose durations do not match the overall duration returned.
This may be a feature in music composition, or a source of annoying
bugs. Buyer beware!

Generators need not honor the length of the section; a section could be
truncated (or overflow) the maximum duration. Whether this makes sense
or needs to be guarded against will depend on the composition.

The caller will likely need to write generators of their own: the ones
included with this module are not very interesting. How the generators
are mixed together is also left as an exercise to the reader. See again
the C<eg/> directory.

=head1 BUGS

None known.

However, the code isn't too complicated (or is complicated in a wrong
way) and may need to be redone? The shape seems mostly okay (to me).

=head1 SEE ALSO

L<MIDI>, L<Music::RhythmSet>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
