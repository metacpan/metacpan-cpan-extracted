# -*- Perl -*-
#
# Musical voice generation.
#
# Run perldoc(1) on this file for additional documentation.

package Music::VoiceGen;

use 5.10.0;
use strict;
use warnings;

use Carp qw(croak);
use List::Util qw(min);
use Math::Random::Discrete;
use Moo;
use namespace::clean;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.02';

has _choices => ( is => 'rwp', );
has _context => (
    is      => 'rwp',
    clearer => 'clear_context',
    coerce  => sub { ref $_[0] eq 'ARRAY' ? $_[0] : \@_ },
    default => sub { [] },
);
has contextfn => (
    is  => 'rw',
    isa => sub {
        die "context function must be a code ref"
          unless defined $_[0] and ref $_[0] eq 'CODE';
    },
    default => sub {
        sub { $_[1]->rand, 1 }
    },
);
has intervals => ( is => 'rwp', );
has MAX_CONTEXT => (
    is     => 'rw',
    coerce => sub {
        croak "MAX_CONTEXT must be positive integer"
          if !defined $_[0]
          or !looks_like_number $_[0]
          or $_[0] < 1;
        int $_[0];
    },
    default => sub {
        1;
    },
);
has pitches   => ( is => 'rwp', );
# NOTE use the ->update method to set these after ->new
has possibles => ( is => 'rwp', );
has startfn   => (
    is  => 'rw',
    isa => sub {
        die "start function must be a code ref"
          unless defined $_[0] and ref $_[0] eq 'CODE';
    },
    default => sub {
        sub {
            $_[0]->[ CORE::rand @{ $_[0] } ];
        };
    },
);

sub BUILD {
    my ( $self, $param ) = @_;

    if ( exists $param->{pitches} and exists $param->{intervals} ) {
        croak "have no pitches to work with"
          if !defined $param->{pitches}
          or ref $param->{pitches} ne 'ARRAY'
          or !@{ $param->{pitches} };
        croak "have no intervals to work with"
          if !defined $param->{intervals}
          or ref $param->{intervals} ne 'ARRAY'
          or !@{ $param->{intervals} };

        my $weightfn = $param->{weightfn} // sub { 1 };

        my ( %allowed_pitches, %allowed_intervals );
        @allowed_pitches{ map int,   @{ $param->{pitches} } }   = ();
        @allowed_intervals{ map int, @{ $param->{intervals} } } = ();

        for my $pitch ( keys %allowed_pitches ) {
            for my $interval ( keys %allowed_intervals ) {
                my $newpitch = $pitch + $interval;
                if ( exists $allowed_pitches{$newpitch} ) {
                    $param->{possibles}{$pitch}{$newpitch} =
                      $weightfn->( $pitch, $newpitch, $interval );
                }
            }
        }
        $self->_set_intervals( $param->{intervals} );
        $self->_set_pitches( $param->{pitches} );

    } elsif ( exists $param->{possibles} ) {
        croak "possibles must be hash reference"
          if !defined $param->{possibles}
          or ref $param->{possibles} ne 'HASH';
        $self->_set_intervals( [] );
        $self->_set_pitches(   [] );
    } else {
        croak "need 'pitches' and 'intervals' or 'possibles'";
    }

    $self->update( $param->{possibles}, preserve_pitches => 1 );
}

sub context {
    my ( $self, $context ) = @_;
    return $self->_context if !defined $context;
    $context = [ @_[ 1 .. $#_ ] ] if ref $context ne 'ARRAY';
    my $mc = $self->MAX_CONTEXT;
    if ( @$context > $mc ) {
        @$context = @$context[ -$mc .. -1 ];
    }
    $self->_set__context($context);
    return $self;
}

sub rand {
    my ($self) = @_;
    my $choices = $self->_choices;
    my $choice;
    my $context = $self->context;
    if ( !@$context ) {
        my @possibles = keys %{ $self->possibles };
        croak "no keys in possibles" if !@possibles;
        $choice = $self->startfn->( \@possibles );
    } else {
        my $count = 1;
        for my $i ( 0 .. $#$context ) {
            my $key = join ".", @$context[ $i .. $#$context ];
            if ( exists $choices->{$key} ) {
                ( $choice, my $abort ) =
                  $self->contextfn->( $choice, $choices->{$key}, $count );
                last if $abort;
                $count++;
            }
        }
    }

    # see "Known Issues" in docs for ideas on how to workaround
    croak "could not find a choice" if !defined $choice;

    push @$context, $choice;
    $self->context($context);

    return $choice;
}

sub subsets {
    my ( $self, $min, $max, $fn, $list ) = @_;
    croak "subsets needs min,max,coderef,list" if @_ < 5;
    $list = [ @_[ 4 .. $#_ ] ] if ref $list ne 'ARRAY';
    for my $lo ( 0 .. @$list - $min ) {
        for my $hi ( $lo + $min - 1 .. min( $lo + $max - 1, $#$list ) ) {
            $fn->( @$list[ $lo .. $hi ] );
        }
    }
    return $self;
}

sub update {
    my ( $self, $possibles, %param ) = @_;

    croak "possibles must be hash reference"
      if !defined $possibles
      or ref $possibles ne 'HASH';

    $self->_set_possibles($possibles);

    my %choices;
    for my $fromval ( keys %$possibles ) {
        my ( @choices, @weights );
        for my $toval ( keys %{ $possibles->{$fromval} } ) {
            push @choices, $toval;
            push @weights, $possibles->{$fromval}{$toval};
        }
        $choices{$fromval} = Math::Random::Discrete->new( \@weights, \@choices );
    }
    $self->_set__choices( \%choices );

    unless ( $param{preserve_pitches} ) {
        $self->_set_intervals( [] );
        $self->_set_pitches(   [] );
    }

    return $self;
}

1;
__END__

=head1 NAME

Music::VoiceGen - musical voice generation

=head1 SYNOPSIS

  use Music::VoiceGen;

  # C4 to A4 in the C-Major scale, allowing major and minor
  # seconds and thirds ascending and descending, equal odds
  # of (allowed) intervals
  my $voice = Music::VoiceGen->new(
      pitches   => [qw/60 62 64 65 67 69/],
      intervals => [qw/1 2 3 4 -1 -2 -3 -4/],
  );
  # get eight random notes into a string
  join ' ', map { $voice->rand } 1..8

  # see what the possibilities are
  use Data::Dumper;
  print Dumper $voice->possibles;

  # force a start from a particular note (use before ->rand
  # is called)
  $voice->context(60);

  # set custom possibilities
  $voice->update(
    { 60 => { 62 => 8, 64 => 4, 65 => 1 },
      62 => { 60 => 1, ... },
      ...
    }
  );
  # or the same thing via new (instead of pitches & intervals)
  Music::VoiceGen->new( possibles => { ... } );

  # pitches and intervals can be weighted via a custom function;
  # this one makes descending intervals more likely
  my $voice = Music::VoiceGen->new(
      pitches   => [qw/60 62 64 65 67 69/],
      intervals => [qw/1 2 3 4 -1 -2 -3 -4/],
      weightfn  => sub {
          my ($from, $to, $interval) = @_;
          $interval < 0 ? 3 : 1
      },
  );

=head1 DESCRIPTION

This module offers the ability to generate a voice (a series of notes or
melody) using only certain pitches and intervals, or otherwise a custom
set of possible choices (via a hash of hashes) that a given pitch (an
integer) will move to some other pitch. The design suits choral work,
where leaps of a tritone or similar must be forbidden, and the range of
pitches confined to a certain ambitus. With suitable input this module
could be made to produce more chromatic lines over larger ranges.

Walker's alias method (via L<Math::Random::Discrete>) is used to
efficiently select weighted random values. The L<Moo> documentation may
be helpful to understand the source and some of the terminology used in
this documentation.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</ATTRIBUTES>. The B<pitches> and
B<intervals> attributes must be set, or otherwise custom B<possibles>
must be supplied.

An additional B<weightfn> parameter may be supplied to B<new> when using
B<pitches> and B<intervals>; this parameter must be a code reference
that will be called with the starting pitch, destination pitch, and
interval, and should return a numeric weight (the default is to evenly
weight available possibilities). The B<weightfn> is not relevant if
B<possibles> is used; that data structure manually includes the weights.

=head1 ATTRIBUTES

=over 4

=item B<_choices>

Where the L<Math::Random::Discrete> lookup tables are stored. This is an
internal detail that may change in future releases.

=item B<_context>

The previous notes used by B<rand>, if any. Limited by the
B<MAX_CONTEXT> attribute, and only relevant if the B<possibles> take
context into account. Use instead the B<context> or B<clear_context>
methods to interact with the contents of this attribute.

=item B<contextfn>

A code reference that is called by B<rand> when B<_context> is
available, arguments being the previous choice (which will be B<undef>
on the first call), a L<Math::Random::Discrete> object, and a counter
that indicates how many times the B<contextfn> has been called inside
this B<rand> call. Return values should be the choice, and a boolean
that if true will stop the loop through available B<_context>. The
following example shows a weighted sampling algorithm (see the "random
line" entry in L<perlfaq5> for background) that prefers to use a
selection from the longest context, but may sometimes instead use a
choice from a shorter context chain.

  $voice->contextfn(
      sub {
          my ( $choice, $mrd, $count ) = @_;
          if ( CORE::rand( $count + ( $count - 1 ) / 2 ) < 1 ) {
              $choice = $mrd->rand;
          }
          return $choice, 0;
      }
  );

=item B<intervals>

A list of allowed intervals a voice is allowed to make, by positive and
negative semitones for ascending and descending melodic motion. A common
set would allow oblique motion (C<0>), intervals up to a minor sixth in
both directions (C<-8>, C<8>), the octave, but not the tritone:

  qw/0 1 2 3 4 5 7 8 12 -1 -2 -3 -4 -5 -7 -8 -12/

Only unique intervals are used. That is, specifying C<0 1 2 3 3 3 ...>
to B<intervals> will not increase the odds that an ascending minor third
is used. Intervals can be weighted differently via the B<weightfn>
attribute, or by supplying custom B<possibles>.

Intervals are only allowed where the resulting pitch exists in the
B<pitches> attribute, so the number of possible pitches from a given
pitch will be limited, especially if the pitch is near an extreme of the
pitch range, or if the ambitus is limited, or if the intervals are a
poor fit for the allowed pitches.

Setting this attribute outside of B<new> will have no effect (use the
B<update> method instead to change the odds).

The intervals are otherwise only for reference, and will be wiped out
should an B<update> call be made without the preserve option.
B<intervals> will not be set if custom B<possibles> are passed to
B<new>.

=item B<MAX_CONTEXT>

How many B<context> notes to retain (1 by default). Higher values will
have no effect (save for burning needless CPU cycles) unless appropriate
B<possibles> have been supplied.

=item B<startfn>

A code reference called by B<rand> when there is no available
B<_context>. This call is passed a list of possible starting items as a
list reference, and should return a value in that list to be used as the
starting point.

=item B<pitches>

What pitches are allowed for the voice, in semitones as integers. The
C<ly2pitch> mode of C<atonal-util> (via L<App::MusicTools>) may be handy
to convert lilypond note names into appropriate pitch numbers, as well
as the C<interval_class_content> calculation (see docs in
L<Music::AtonalUtil>) that details what intervals (up to and including
the tritone) are present in a set of pitches:

  $ atonal-util ly2pitch --relative=c\' c d e f g a bes c d e
  60 62 64 65 67 69 70 72 74 76
  $ atonal-util interval_class_content c d e f g a bes c d e
  254361

Setting this attribute outside of B<new> will have no effect (use the
B<update> method instead to change the odds).

The pitches are otherwise only for reference, and will be wiped out
should an B<update> call be made without the preserve option. B<pitches>
will not be set if custom B<possibles> are passed to B<new>.

=item B<possibles>

The possible choices for what pitches can be reached from a given pitch,
with weights. Consider it read-only once the object has been created;
changes to B<possibles> should be made via the B<update> method.

  my $p = $voice->possibles;
  # ... alter $p as necessary ...
  $voice->update($p);

B<possibles> may make use of B<context> by providing choices for dot-
joined strings of other possibilities:

  my $voice = Music::VoiceGen->new(
      MAX_CONTEXT => 3,
      possibles   => {
          60         => { 65 => 1 },
          "60.65"    => { 67 => 1 },
          65         => { -1 => 1 },
          "60.65.67" => { 65 => 1 },
      },
  );
  $voice->context(60);

In this case, C<60.65> and not C<65> would be used by the next call to
B<rand>, as that is a more specific choice. If a more specific choice is
not available, then B<rand> will fall back to using shorter and shorter
chains. This behavior can be changed via the B<contextfn> attribute.

If there is B<context>, and no pitch can be used, then B<rand> will die
with an exception. This is a known issue.

=back

=head1 METHODS

=over 4

=item B<clear_context>

Empties the current context, if any. The next call to B<rand> will pick a
starting possibility from an equal weighting of all available
possibilities.

=item B<context>

With no arguments, returns the current context, an array reference that
records previous results from B<rand> up to the B<MAX_CONTEXT>
attribute. With an argument, sets the context to the provided list or
array references.

Returns the object, so can be chained with other method calls.

=item B<rand>

Takes no arguments. Returns a random pitch, perhaps adjusted by any
B<context>, otherwise when lacking B<context> picking with an equal
chance from any of the B<pitches> or top-level B<possibles> supplied,
unless the default B<startfn> or B<contextfn> attributes have be
overridden and instructed to behave otherwise.

=item B<subsets> I<min> I<max> I<coderef> I<list>

Utility method, calls the given I<coderef> with each of the I<min> to
I<max> element subsets of the given I<list>. In particular, this can be
used to generate B<possibles> from a given musical voice. For example,
assuming a B<MAX_CONTEXT> of 3, all possibles from one to three notes
plus the destination pitch could be tallied via:

  my %poss;
  $voice->subsets(
      2, 4, sub { $poss{ join ".", @_[0..$#_-1] }{ $_[-1] }++ },
      [qw/65 67 69 60 62/]
  );
  use Data::Dumper; print Dumper \%poss;

Returns the object, so can be chained with other method calls.

=item B<update> I<possibles> [ preserve_pitches => 1 ]

Offers the ability to update the B<possibles> attribute (and also
B<_choices>) with the supplied reference to a hash of hash references.
Unless the I<preserve_pitches> parameter is supplied, the B<pitches> and
B<intervals>, if any, will be wiped out by this call.

Returns the object, so can be chained with other method calls.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-voicegen at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-VoiceGen>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-VoiceGen>

=head2 Known Issues

It is fairly easy to trigger the "could not find a choice" error should
a particular pitch be a dead end (when there are no allowed intervals
leading from a pitch to any other allowed pitch), or if C<undef> has
gotten into the B<possibles> attribute. As a workaround, inspect the
contents of the relevant attributes and remove or fix any such problems,
e.g. for any dead-end pitches return a "stop" value that causes the
calling code to not make additional calls to B<rand>.

  $voice->update( { 66 => { -1 => 1 }, ... } );

  # and elsewhere...
  while ($something) {
      my $pitch = $voice->rand;
      last if $pitch == -1;
  }

Also, if there are possibilities at depth, these will always be used,
unless a custom B<contextfn> is supplied to sometimes not always select
from the chain of most context.

=head1 SEE ALSO

L<MIDI::Simple> or L<Music::Scala> or L<Music::PitchNum> have means to
convert numbers into MIDI events, frequencies, or various forms of note
names. L<Music::Tension::Cope> is one method to score the consonance of
resulting pitch sets, perhaps against the output of multiple voice
generators each with their own set of allowed pitches.

Consult the C<eg/> and C<t/> directories under this module's
distribution for more example code.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
