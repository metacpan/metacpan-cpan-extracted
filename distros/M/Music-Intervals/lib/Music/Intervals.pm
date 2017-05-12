package Music::Intervals;
BEGIN {
  $Music::Intervals::AUTHORITY = 'cpan:GENE';
}
# ABSTRACT: Mathematical breakdown of musical intervals
use strict;
use warnings;
our $VERSION = '0.0502';

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
has temper    => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    $self->semitones * 100 / log(2) },
);
has notes => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    return [ get_scale_notes( $self->tonic ) ] },
);
has scale => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    return [ map { eval "$Music::Intervals::Ratios::ratio->{$_}{ratio}" } @{ $self->notes } ] },
);
has _note_index => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    return { map { $_ => eval "$Music::Intervals::Ratios::ratio->{$_}{ratio}" } @{ $self->notes } } },
);
has _ratio_index => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    return { map { $_ => $Music::Intervals::Ratios::ratio->{$_}{ratio} } @{ $self->notes } } },
);
has _ratio_name_index => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    return {
        map { $Music::Intervals::Ratios::ratio->{$_}{ratio} => {
            symbol => $_,
            name   => $Music::Intervals::Ratios::ratio->{$_}{name} }
        } keys %$Music::Intervals::Ratios::ratio } },
);
has tonic_frequency => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
        return $self->concert * (2 ** (1 / $self->semitones)) ** (-9) # XXX Hardcoding: 9th key above middle-C
    },
);

has chord_names => ( is => 'rw', default => sub { {} } );
has natural_frequencies => ( is => 'rw', default => sub { {} } );
has natural_intervals => ( is => 'rw', default => sub { {} } );
has natural_cents => ( is => 'rw', default => sub { {} } );
has natural_prime_factors => ( is => 'rw', default => sub { {} } );
has eq_tempered_frequencies => ( is => 'rw', default => sub { {} } );
has eq_tempered_intervals => ( is => 'rw', default => sub { {} } );
has eq_tempered_cents => ( is => 'rw', default => sub { {} } );
has integer_notation => ( is => 'rw', default => sub { {} } );

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
                map { $_ => 
                    sprintf '%.0f', $self->midikey + $self->semitones * log( ($self->tonic_frequency * (eval $self->_ratio_index->{$_})) / $self->concert ) / log(2)
                } @$c
            };
        }

        if ( $self->justin )
        {
            if ( $self->freqs )
            {
                $self->natural_frequencies->{"@$c natural_frequencies"} = {
                    map {
                        $_ => {
                             sprintf('%.3f', $self->tonic_frequency * eval $self->_ratio_index->{$_}) => { $self->_ratio_index->{$_} => $Music::Intervals::Ratios::ratio->{$_}{name} }
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

        # Calculate both natural and equal temperament values for our ratio.
        $dyads{"@$i"} = {
            natural => $fraction->to_string(),
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

version 0.0502

=head1 SYNOPSIS

  use Music::Intervals;
  $m = Music::Intervals->new(
    notes => [qw( C E G B )],
    size => 3,
    chords => 1,
    justin => 1,
    equalt => 1,
    freqs => 1,
    interval => 1,
    cents => 1,
    prime => 1,
    integer => 1,
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
  $name = $m->by_ratio($ratio);
  $ratio = $m->by_name($interval_name);

  # Show all the known intervals (the "notes" attribute above):
  perl -MData::Dumper -MMusic::Intervals::Ratios -e'print Dumper $Music::Intervals::Ratios::ratio'

=head1 DESCRIPTION

A C<Music::Intervals> object shows the mathematical break-down of musical
intervals and chords.

This module reveals the "guts" of chords within a given tonality.  By guts I
mean, the measurements of the notes and the intervals between them.

* This module only handles equal temperament for the 12-tone scale only. *

=head1 METHODS

=head2 new()

  $x = Music::Intervals->new(%arguments);

=head2 Attributes and defaults

=over 4

=item cents: 0 - divisions of the octave

=item chords: 0 - chord names

=item equalt: 0 - equal temperament

=item justin: 0 - just intonation

=item integer: 0 - integer notation

=item freqs: 0 - frequencies

=item interval: 0 - note intervals

=item prime: 0 - prime factorization

=item rootless: 0 - show chord names with no root

=item octave: 4 - use the fourth octave

=item concert: 440 - concert pitch

=item size: 3 - chord size

=item tonic: C - root of the computations

* Currently (and for the foreseeable future) this will remain the only value
that produces sane results.

=item semitones: 12 - number of notes in the scale

=item temper: semitones * 100 / log(2) - physical distance between notes

=item notes: [ C D E F G A B ] - actual notes to use in the computation

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

For natural_intervals() this example produces the following:

 'C pM3 pM7' => {
   'C pM3' => { '81/64' => 'Pythagorean major third' },
   'C pM7' => { '243/128' => 'Pythagorean major seventh' },
   'pM3 pM7' => { '3/2' => 'perfect fifth' }
 }

Note that case matters for interval names.  For example, "M" means major and "m"
means minor.

=back

=head2 by_name()

 $ratio = $m->by_name('C');
 # { ratio => '1/1', name => 'unison, perfect prime, tonic' }

Return a known ratio or undef.

=head2 by_ratio()

 $name = $m->by_ratio($ratio);

Return a known ratio name or undef.

=head1 SEE ALSO

For the time being, you will need to look at the source of
C<Music::Intervals::Ratios> for the note and interval names.

L<Music::Intervals::Numeric> for numeric-only note-intervals

L<https://github.com/ology/Music/blob/master/intervals>

L<http://en.wikipedia.org/wiki/List_of_musical_intervals>

L<http://en.wikipedia.org/wiki/Equal_temperament>

L<http://en.wikipedia.org/wiki/Just_intonation>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
