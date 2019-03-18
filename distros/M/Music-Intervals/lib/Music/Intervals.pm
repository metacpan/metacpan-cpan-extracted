package Music::Intervals;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Mathematical breakdown of musical intervals

use strict;
use warnings;

our $VERSION = '0.0507';

use Moo;
use Algorithm::Combinatorics qw( combinations );
use Math::Factor::XS qw( prime_factors );
use Music::Chord::Namer qw( chordname );
use MIDI::Pitch qw( name2freq );
use Number::Fraction;
use Music::Scales;
use Music::Intervals::Ratios;


has cents     => ( is => 'ro', default => sub { 0 } );
has chords    => ( is => 'ro', default => sub { 0 } );
has equalt    => ( is => 'ro', default => sub { 0 } );
has freqs     => ( is => 'ro', default => sub { 0 } );
has interval  => ( is => 'ro', default => sub { 0 } );
has integer   => ( is => 'ro', default => sub { 0 } );
has justin    => ( is => 'ro', default => sub { 0 } );
has prime     => ( is => 'ro', default => sub { 0 } );
has rootless  => ( is => 'ro', default => sub { 0 } );
has octave    => ( is => 'ro', default => sub { 4 } );
has midikey   => ( is => 'ro', default => sub { 69 } );
has concert   => ( is => 'ro', default => sub { 440 } );
has size      => ( is => 'ro', default => sub { 3 } );
has tonic     => ( is => 'ro', default => sub { 'C' } );
has semitones => ( is => 'ro', default => sub { 12 } );

has temper => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->semitones * 100 / log(2);
    },
);
has notes => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return [ get_scale_notes( $self->tonic ) ]
    },
);
has scale => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return [ map { eval "$Music::Intervals::Ratios::ratio->{$_}{ratio}" } @{ $self->notes } ]
    },
);
has _note_index => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return { map { $_ => eval "$Music::Intervals::Ratios::ratio->{$_}{ratio}" } @{ $self->notes } }
    },
);
has _ratio_index => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return { map { $_ => $Music::Intervals::Ratios::ratio->{$_}{ratio} } @{ $self->notes } }
    },
);
has _ratio_name_index => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            map { $Music::Intervals::Ratios::ratio->{$_}{ratio} => {
                symbol => $_,
                name   => $Music::Intervals::Ratios::ratio->{$_}{name} }
            } keys %$Music::Intervals::Ratios::ratio
        }
    },
);
has tonic_frequency => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->concert * (2 ** (1 / $self->semitones)) ** (-9) # XXX Hardcoding: 9th key above middle-C
    },
);

has chord_names             => ( is => 'rw', default => sub { {} } );
has natural_frequencies     => ( is => 'rw', default => sub { {} } );
has natural_intervals       => ( is => 'rw', default => sub { {} } );
has natural_cents           => ( is => 'rw', default => sub { {} } );
has natural_prime_factors   => ( is => 'rw', default => sub { {} } );
has eq_tempered_frequencies => ( is => 'rw', default => sub { {} } );
has eq_tempered_intervals   => ( is => 'rw', default => sub { {} } );
has eq_tempered_cents       => ( is => 'rw', default => sub { {} } );
has integer_notation        => ( is => 'rw', default => sub { {} } );


sub process
{
    my $self = shift;

    my $iter = combinations( $self->notes, $self->size );
    while (my $c = $iter->next)
    {
        my %dyads = $self->dyads($c);

        if ( $self->chords )
        {
            # Do we know any named chords?
            my @chordname = eval { chordname(@$c) };

            # Exclude "rootless" chords unless requested.
            @chordname = grep { !/no-root/ } @chordname unless $self->rootless;

            # Set the names of this chord combination.
            $self->chord_names->{"@$c chord_names"} = \@chordname if @chordname;
        }

        if ( $self->integer )
        {
            $self->integer_notation->{"@$c integer_notation"} = {
                map { $_ => sprintf '%.0f',
                    $self->midikey + $self->semitones * log( ($self->tonic_frequency * (eval $self->_ratio_index->{$_})) / $self->concert ) / log(2)
                } @$c
            };
        }

        if ( $self->justin )
        {
            if ( $self->freqs )
            {
                $self->natural_frequencies->{"@$c natural_frequencies"} = {
                    map { $_ => {
                        sprintf('%.3f', $self->tonic_frequency * eval $self->_ratio_index->{$_})
                            => { $self->_ratio_index->{$_} => $Music::Intervals::Ratios::ratio->{$_}{name} }
                        }
                    } @$c
                };
            }
            if ( $self->interval )
            {
                $self->natural_intervals->{"@$c natural_intervals"} = {
                    map {
                        $_ => {
                            $dyads{$_}->{natural} => $self->_ratio_name_index->{ $dyads{$_}->{natural} }{name}
                        }
                    } keys %dyads
                };

            }
            if ( $self->cents )
            {
                $self->natural_cents->{"@$c natural_cents"} = {
                    map {
                        $_ => log( eval $dyads{$_}->{natural} ) * $self->temper
                    } keys %dyads };

            }
            if ( $self->prime )
            {
                $self->natural_prime_factors->{"@$c natural_prime_factors"} = {
                    map {
                        $_ => {
                            $dyads{$_}->{natural} => ratio_factorize( $dyads{$_}->{natural} )
                        }
                    } keys %dyads
                };
            }
        }

        if ( $self->equalt )
        {
            if ( $self->freqs )
            {
                $self->eq_tempered_frequencies->{"@$c eq_tempered_frequencies"} = {
                    map {
                        $_ => name2freq( $_ . $self->octave ) || $self->concert * $self->_note_index->{$_}
                    } @$c
                };
            }
            if ( $self->interval )
            {
                $self->eq_tempered_intervals->{"@$c eq_tempered_intervals"} = {
                    map {
                        $_ => $dyads{$_}->{eq_tempered}
                    } keys %dyads
                };
            }
            if ( $self->cents )
            {
                $self->eq_tempered_cents->{"@$c eq_tempered_cents"} = {
                    map {
                        $_ => log( $dyads{$_}->{eq_tempered} ) * $self->temper
                    } keys %dyads
                };
            }
        }
    }
}


sub dyads
{
    my $self = shift;
    my ($c) = @_;

    my @pairs = combinations( $c, 2 );

    my %dyads;
    for my $i (@pairs) {
        # Construct our "dyadic" fraction.
        my $numerator   = Number::Fraction->new( $self->_ratio_index->{ $i->[1] } );
        my $denominator = Number::Fraction->new( $self->_ratio_index->{ $i->[0] } );
        my $fraction = $numerator / $denominator;

        my $str = $fraction->to_string();
        # Handle the octave.
        $str .= '/1' if $fraction->to_string() eq 2;

        # Calculate both natural and equal temperament values for our ratio.
        $dyads{"@$i"} = {
            natural => $str,
            # The value is either the known pitch ratio or ...
            eq_tempered =>
              ( name2freq( $i->[1] . $self->octave ) || ( $self->concert * $self->_note_index->{ $i->[1] } ) )
                /
              ( name2freq( $i->[0] . $self->octave ) || ( $self->concert * $self->_note_index->{ $i->[0] } ) ),
        };
    }

    return %dyads;
}


sub ratio_factorize {
    my $dyad = shift;

    my ( $numerator, $denominator ) = split /\//, $dyad;
    $numerator   = [ prime_factors($numerator) ];
    $denominator = [ prime_factors($denominator) ];

    return sprintf( '(%s) / (%s)',
        join( '*', @$numerator ),
        join( '*', @$denominator )
    );
}


sub by_name
{
    my ( $self, $name ) = @_;
    return $Music::Intervals::Ratios::ratio->{$name};
}


sub by_ratio
{
    my ( $self, $ratio ) = @_;
    return $self->_ratio_name_index->{$ratio};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Intervals - Mathematical breakdown of musical intervals

=head1 VERSION

version 0.0507

=head1 SYNOPSIS

  use Music::Intervals;

  my $m = Music::Intervals->new(
    notes    => [qw/C E G B/], # Default: C major scale
    size     => 3,             # Must be <= the notes
    chords   => 1,             # Required for chord names
    justin   => 1,             # Required for natural_*
    equalt   => 1,             # Required for eq_tempered_*
    freqs    => 1,             # Required for *_frequencies
    interval => 1,             # Required for *_intervals
    cents    => 1,             # Required for *_cents
    prime    => 1,             # Required for prime factors
    integer  => 1,             # Required for integer notation
  );

  $m->process;

  # Then
  print Dumper # any of:
    $m->chord_names,
    $m->natural_frequencies,
    $m->natural_intervals,
    $m->natural_cents,
    $m->natural_prime_factors,
    $m->eq_tempered_frequencies,
    $m->eq_tempered_intervals,
    $m->eq_tempered_cents,
    $m->integer_notation,
  ;

  # Find known intervals
  $name  = $m->by_ratio($ratio);
  $ratio = $m->by_name($interval_name);

  # Show all the known intervals:
  perl -MData::Dumper -MMusic::Intervals::Ratios -e'print Dumper $Music::Intervals::Ratios::ratio'

=head1 DESCRIPTION

A C<Music::Intervals> object shows the mathematical break-down of musical notes,
intervals and chords.

This module reveals the "guts" within a given tonality.  And by guts I mean, the
measurements of the notes and the intervals between them.

=head1 ATTRIBUTES

=head2 chords

Show chord names.

Default: 0

=head2 rootless

Show chord names with no root.

Default: 0

=head2 equalt

Show equal temperament.

Default: 0

=head2 justin

Show just intonation.

Default: 0

=head2 integer

Show integer notation.

Default: 0

=head2 cents

Show the logarithmic units of measure.

Default: 0

=head2 freqs

Show frequencies.

Default: 0

=head2 interval

Show note intervals.

Default: 0

=head2 prime

Show prime factorization.

Default: 0

=head2 octave

The octave to use.

Default: 4

=head2 concert

Concert pitch.

Default: 440

=head2 size

Chord size

Default: 3

=head2 tonic

The root of the computations.

Default: C

* Currently (and for the foreseeable future) this will remain the only value
that produces sane results.

=head2 semitones

Number of notes in the scale.

Default: 12

=head2 temper

Physical distance between notes.

Default: semitones * 100 / log(2)

=head2 notes

The actual notes to use in the computation.

Default: [ C D E F G A B ]

The list of notes may be any of the keys in the L<Music::Intervals::Ratios>
C<ratio> hashref.  This is very very long and contains useful intervals such as
those of the common scale and even the Pythagorean intervals, too.

A few examples:

 * [qw( C E G )]
 * [qw( C D D# )]
 * [qw( C D Eb )]
 * [qw( C D D# Eb E E# Fb F )]
 * [qw( C 11h 7h )]
 * [qw( C pM3 pM7 )]

For B<natural_intervals> this last example produces the following:

 'C pM3 pM7' => {
   'C pM3' => { '81/64' => 'Pythagorean major third' },
   'C pM7' => { '243/128' => 'Pythagorean major seventh' },
   'pM3 pM7' => { '3/2' => 'perfect fifth' }
 }

Note that case matters for interval names.  For example, "M" means major and "m"
means minor.

=head2 midikey

Default: 69

=head2 chord_names

Computed hashref

=head2 eq_tempered_cents

Computed hashref

=head2 eq_tempered_frequencies

Computed hashref

=head2 eq_tempered_intervals

Computed hashref

=head2 integer_notation

Computed hashref

=head2 natural_cents

Computed hashref

=head2 natural_frequencies

Computed hashref

=head2 natural_intervals

Computed hashref

=head2 natural_prime_factors

Computed hashref

=head1 METHODS

=head2 new()

  $x = Music::Intervals->new(%arguments);

Create a new C<Music::Intervals> object.

=head2 process()

Do the actual computations!

=head2 dyads()

Return pairs of the given combinations with fractional and pitch ratio parts.

=head2 ratio_factorize()

Return the dyadic fraction as a prime factored expression.

=head2 by_name()

 $ratio = $m->by_name('C');
 # { ratio => '1/1', name => 'unison, perfect prime, tonic' }

Return a known ratio or undef.

=head2 by_ratio()

 $name = $m->by_ratio('1/1');
 # { 'symbol' => 'C', 'name' => 'unison, perfect prime, tonic' }

Return a known ratio name or undef.

=head1 SEE ALSO

The F<t/> tests and F<eg/> example in this distribution

For the time being, you will need to look at the source of
L<Music::Intervals::Ratios> for the note and interval names.

L<Music::Intervals::Numeric> for numeric-only note-intervals

L<https://github.com/ology/Music/blob/master/intervals> - The predecessor to this module

L<http://en.wikipedia.org/wiki/List_of_musical_intervals>

L<http://en.wikipedia.org/wiki/Equal_temperament>

L<http://en.wikipedia.org/wiki/Just_intonation>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
