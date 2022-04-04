package Music::Intervals;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Breakdown of musical intervals

use strict;
use warnings;

our $VERSION = '0.0905';

use Algorithm::Combinatorics qw( combinations );
use Math::Factor::XS qw( prime_factors );
use MIDI::Pitch qw( name2freq );
use Moo;
use Music::Intervals::Ratios;
use Number::Fraction ();
use strictures 2;
use namespace::clean;


has notes => (
    is      => 'ro',
    default => sub { [qw( C E G )] },
);

has _dyads => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);
sub _build__dyads {
    my $self = shift;
    my %dyads = $self->dyads($self->notes);
    return \%dyads;
}

has _octave => ( is => 'ro', default => sub { 4 } );
has _concert => ( is => 'ro', default => sub { 440 } );
has _tonic => ( is => 'ro', default => sub { 'C' } );
has _semitones => ( is => 'ro', default => sub { 12 } );
has _midikey => ( is => 'ro', default => sub { 69 } );

has _temper => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);
sub _build__temper {
    my $self = shift;
    $self->_semitones * 100 / log(2);
}

has _tonic_frequency => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);
sub _build__tonic_frequency {
    my $self = shift;
    return name2freq($self->_tonic . $self->_octave);
}

has _note_index => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);
sub _build__note_index {
    my $self = shift;
    return { map { $_ => eval "$Music::Intervals::Ratios::ratio->{$_}{ratio}" } @{ $self->notes } };
}

has _ratio_index => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);
sub _build__ratio_index {
    my $self = shift;
    return { map { $_ => $Music::Intervals::Ratios::ratio->{$_}{ratio} } @{ $self->notes } };
}

has _ratio_name_index => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);
sub _build__ratio_name_index {
    my $self = shift;
    return {
        map { $Music::Intervals::Ratios::ratio->{$_}{ratio} => {
            symbol => $_,
            name   => $Music::Intervals::Ratios::ratio->{$_}{name} }
        } keys %$Music::Intervals::Ratios::ratio
    }
}


sub integer_notation {
    my ($self) = @_;

    my %integer_notation = map { $_ => sprintf '%.0f',
        $self->_midikey + $self->_semitones
        * log( ($self->_tonic_frequency * (eval $self->_ratio_index->{$_})) / $self->_concert ) / log(2)
    } @{ $self->notes };

    return \%integer_notation;
}


sub eq_tempered_cents {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %eq_tempered_cents = map {
        $_ => log( $dyads{$_}->{eq_tempered} ) * $self->_temper
    } keys %dyads;

    return \%eq_tempered_cents;
}


sub eq_tempered_frequencies {
    my ($self) = @_;

    my %eq_tempered_frequencies = map {
        $_ => name2freq( $_ . $self->_octave ) || $self->_concert * $self->_note_index->{$_}
    } @{ $self->notes };

    return \%eq_tempered_frequencies;
}


sub eq_tempered_intervals {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %eq_tempered_intervals = map {
        $_ => $dyads{$_}->{eq_tempered}
    } keys %dyads;

    return \%eq_tempered_intervals;
}


sub natural_cents {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %natural_cents = map {
        $_ => log( eval $dyads{$_}->{natural} ) * $self->_temper
    } keys %dyads;

    return \%natural_cents;
}


sub natural_frequencies {
    my ($self) = @_;

    my %natural_frequencies = map {
        $_ => {
            $self->_tonic_frequency * eval $self->_ratio_index->{$_} . ''
                => { $self->_ratio_index->{$_} => $Music::Intervals::Ratios::ratio->{$_}{name} }
        }
    } @{ $self->notes };

    return \%natural_frequencies;
}


sub natural_intervals {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %natural_intervals = map {
        $_ => {
            $dyads{$_}->{natural} => $self->_ratio_name_index->{ $dyads{$_}->{natural} }{name}
        }
    } keys %dyads;

    return \%natural_intervals;
}


sub natural_prime_factors {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %natural_prime_factors = map {
        $_ => {
            $dyads{$_}->{natural} => $self->ratio_factorize( $dyads{$_}->{natural} )
        }
    } keys %dyads;

    return \%natural_prime_factors;
}


sub dyads {
    my $self = shift;
    my ($c) = @_;

    return () if @$c <= 1;

    my @pairs = combinations( $c, 2 );

    my %dyads;
    for my $i (@pairs) {
        # Construct our "dyadic" fraction.
        my $numerator   = Number::Fraction->new( $self->_ratio_index->{ $i->[1] } );
        my $denominator = Number::Fraction->new( $self->_ratio_index->{ $i->[0] } );
        my $fraction = $numerator / $denominator;

        my $str = $fraction->to_string;
        # Handle the octave.
        $str .= '/1' if $fraction->to_string eq 2;

        # Calculate both natural and equal temperament values for our ratio.
        $dyads{"@$i"} = {
            natural => $str,
            # The value is either the known pitch ratio or ...
            eq_tempered =>
              ( name2freq( $i->[1] . $self->_octave ) || ( $self->_concert * $self->_note_index->{ $i->[1] } ) )
                /
              ( name2freq( $i->[0] . $self->_octave ) || ( $self->_concert * $self->_note_index->{ $i->[0] } ) ),
        };
    }

    return %dyads;
}


sub ratio_factorize {
    my ($self, $dyad) = @_;

    my ( $numerator, $denominator ) = split /\//, $dyad;
    $numerator   = [ prime_factors($numerator) ];
    $denominator = [ prime_factors($denominator) ];

    return sprintf( '(%s) / (%s)',
        join( '*', @$numerator ),
        join( '*', @$denominator )
    );
}


sub by_name {
    my ( $self, $name ) = @_;
    return $Music::Intervals::Ratios::ratio->{$name};
}


sub by_ratio {
    my ( $self, $ratio ) = @_;
    return $self->_ratio_name_index->{$ratio};
}


sub by_description {
    my ( $self, $string ) = @_;
    $string = lc $string;
    my %matches;
    for my $ratio (keys %$Music::Intervals::Ratios::ratio) {
        my $found = $Music::Intervals::Ratios::ratio->{$ratio};
        $matches{$ratio} = $found
            if lc($found->{name}) =~ /$string/;
    }
    return \%matches;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Intervals - Breakdown of musical intervals

=head1 VERSION

version 0.0905

=head1 SYNOPSIS

  use Music::Intervals;

  my $m = Music::Intervals->new(notes => [qw/C Eb G B/]);

  # Then any of:
  print Dumper(
    $m->natural_frequencies,
    $m->natural_intervals,
    $m->natural_cents,
    $m->natural_prime_factors,
    $m->eq_tempered_frequencies,
    $m->eq_tempered_intervals,
    $m->eq_tempered_cents,
    $m->integer_notation,
  );

  # Find known intervals
  my $name = $m->by_ratio('6/5');
  my $ratio = $m->by_name('Eb');
  my $intervals = $m->by_description('pythagorean');

  perl -MMusic::Intervals::Ratios -E'say $Music::Intervals::Ratios::ratio->{C}{name}'
  # unison, perfect prime, tonic

  # Show all the 400+ known intervals:
  perl -MData::Dumper -MMusic::Intervals::Ratios -e'print Dumper $Music::Intervals::Ratios::ratio'

=head1 DESCRIPTION

A C<Music::Intervals> object shows the breakdown of musical notes and
intervals.  (See L<Music::Intervals::Numeric> to use integer ratios
instead of named notes.)

This module reveals the "guts" within a given tonality.  And by guts I
mean, the measurements of the notes and the intervals between them.

For Western notes and intervals, this tonality begins with the C<C>
note.  That is, all intervals are calculated from C<C>.  So, if you
want to analyze a minor chord, either make it start on C<C> (like
C<[C Eb G]>) or somewhere between C<C> and C<B> (like C<[D F A]>).

=head1 ATTRIBUTES

=head2 notes

The actual notes to use in the computation.

Default: C<[ C E G ]>

The list of notes may be any of the keys in the L<Music::Intervals::Ratios>
C<ratio> hashref.  This is very very long and contains useful intervals such as
those of the common scale and even the Pythagorean intervals, too.

A few examples:

 [qw( C E G )]
 [qw( C D D# )]
 [qw( C D Eb )]
 [qw( C D D# Eb E E# Fb F )]
 [qw( C 11h 7h )]
 [qw( C pM3 pM7 )]

For B<natural_intervals> this last example produces the following:

 {
   'C pM3' => { '81/64' => 'Pythagorean major third' },
   'C pM7' => { '243/128' => 'Pythagorean major seventh' },
   'pM3 pM7' => { '3/2' => 'perfect fifth' }
 }

Note that case matters for interval names.  For example, "M" means
major and "m" means minor.

=head1 METHODS

=head2 new

  $x = Music::Intervals->new(%arguments);

Create a new C<Music::Intervals> object.

=head2 integer_notation

Math!  See source...

=head2 eq_tempered_cents

The Equal tempered cents.

=head2 eq_tempered_frequencies

The Equal tempered frequencies.

=head2 eq_tempered_intervals

The Equal tempered intervals.

=head2 natural_cents

Just intonation cents.

=head2 natural_frequencies

Just intonation frequencies.

=head2 natural_intervals

Just intonation intervals.

=head2 natural_prime_factors

Just intonation prime factors.

=head2 dyads

Return pairs of the given notes with fractional and pitch ratio parts.

=head2 ratio_factorize

Return the dyadic fraction as a prime factored expression.

=head2 by_name

 $ratio = $m->by_name('C');
 # { ratio => '1/1', name => 'unison, perfect prime, tonic' }

Return a known ratio or undef.

=head2 by_ratio

 $name = $m->by_ratio('1/1');
 # { 'symbol' => 'C', 'name' => 'unison, perfect prime, tonic' }

Return a known ratio name or undef.

=head2 by_description

  $intervals = $m->by_description('pythagorean');

Search the description of every ratio for the given string.

=head1 SEE ALSO

The F<t/*> tests and F<eg/*> examples in this distribution

For the time being, you will need to look at the source of
L<Music::Intervals::Ratios> for the note and interval names.

L<Music::Intervals::Numeric> for numeric-only note-intervals

L<https://en.wikipedia.org/wiki/Interval_(music)#Main_intervals>

L<https://en.wikipedia.org/wiki/List_of_pitch_intervals>

L<http://en.wikipedia.org/wiki/Equal_temperament>

L<http://en.wikipedia.org/wiki/Just_intonation>

=head2 DEPENDENCIES

L<Algorithm::Combinatorics>

L<Math::Factor::XS>

L<MIDI::Pitch>

L<Moo>

L<Music::Scales>

L<Number::Fraction>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
