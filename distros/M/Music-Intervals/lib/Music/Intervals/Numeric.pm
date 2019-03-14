package Music::Intervals::Numeric;
our $AUTHORITY = 'cpan:GENE';
# ABSTRACT: Mathematical breakdown of musical intervals
use strict;
use warnings;
our $VERSION = '0.0101';

use Moo;
use Algorithm::Combinatorics qw( combinations );
use Math::Factor::XS qw( prime_factors );
use Number::Fraction;
use Music::Intervals::Ratio;


has notes     => ( is => 'ro', default => sub { [] } );
has cent     => ( is => 'ro', default => sub { 0 } );
has freq     => ( is => 'ro', default => sub { 0 } );
has interval  => ( is => 'ro', default => sub { 0 } );
has prime     => ( is => 'ro', default => sub { 0 } );
has size      => ( is => 'ro', default => sub { 3 } );
has semitones => ( is => 'ro', default => sub { 12 } );
has temper    => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    $self->semitones * 100 / log(2) },
);

has frequencies => ( is => 'rw', default => sub { {} } );
has intervals => ( is => 'rw', default => sub { {} } );
has cent_vals => ( is => 'rw', default => sub { {} } );
has prime_factor => ( is => 'rw', default => sub { {} } );


sub process
{
    my $self = shift;

    my %x;

    my $iter = combinations( $self->notes, $self->size );
    while (my $c = $iter->next)
    {
        my %dyads = $self->dyads($c);

        if ( $self->freq )
        {
            $self->frequencies->{"@$c"} =
                { map { $_ => $Music::Intervals::Ratio::ratio->{$_} } @$c };
        }
        if ( $self->interval )
        {
            $self->intervals->{"@$c"} = {
                map {
                    $_ => {
                        $dyads{$_} => $Music::Intervals::Ratio::ratio->{ $dyads{$_} }
                    }
                } keys %dyads
            };

        }
        if ( $self->cent )
        {
            $self->cent_vals->{"@$c"} = {
                map {
                    $_ => log( eval $dyads{$_} ) * $self->temper
                } keys %dyads };

        }
        if ( $self->prime )
        {
            $self->prime_factor->{"@$c"} = {
                map {
                    $_ => {
                        $dyads{$_} => scalar ratio_factorize( $dyads{$_} )
                    }
                } keys %dyads
            };
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
        my $numerator   = Number::Fraction->new( $i->[1] );
        my $denominator = Number::Fraction->new( $i->[0] );
        my $fraction = $numerator / $denominator;

        $dyads{"@$i"} = $fraction->to_string();
    }

    return %dyads;
}


sub ratio_factorize {
    my $dyad = shift;

    my ( $numerator, $denominator ) = split /\//, $dyad;
    $numerator   = [ prime_factors($numerator) ];
    $denominator = [ prime_factors($denominator) ];

    return wantarray
        ? ( $numerator, $denominator )
        : sprintf( '(%s) / (%s)',
            join( '*', @$numerator ),
            join( '*', @$denominator )
        );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Intervals::Numeric - Mathematical breakdown of musical intervals

=head1 VERSION

version 0.0503

=head1 SYNOPSIS

  use Music::Intervals::Numeric;
  $m = Music::Intervals::Numeric->new(
    notes => [qw( 1/1 5/4 3/2 15/8 )],
    size => 3,
    freq => 1,
    interval => 1,
    cent => 1,
    prime => 1,
  );
  $m->process;
  # Then print Dumper any of:
  $m->frequencies;
  $m->intervals;
  $m->cent_vals;
  $m->prime_factor;

  # Show all the known intervals:
  perl -MData::Dumper -MMusic::Intervals::Ratio -e'print Dumper $Music::Intervals::Ratio::ratio'

=head1 DESCRIPTION

A C<Music::Intervals> object shows the mathematical break-down of musical
intervals and chords.

This module reveals the "guts" of chords within a given tonality.  By guts I
mean, the measurements of the notes and the intervals between them, in just
intonation.

=head1 ATTRIBUTES

=head2 cent

Show divisions of the octave

Default: 0

=head2 freq

Show frequencies

Default: 0

=head2 interval

Show note intervals

Default: 0

=head2 prime

Show prime factorization

Default: 0

=head2 size

Chord size

Default: 3

=head2 semitones

Number of notes in the scale

Default: 12

=head2 temper

Physical distance between notes

Default: semitones * 100 / log(2)

=head2 notes

The actual notes to use in the computation

Default: [ 1/1 5/4 3/2 ]  (C E G)

The list of notes may be any of the keys in the L<Music::Intervals::Ratio>
C<ratio> hashref.  This is very very long and contains useful intervals such as
those of the common scale and even the Pythagorean intervals, too.

=head2 cent_vals

Computed hashref

=head2 frequencies

Computed hashref

=head2 intervals

Computed hashref

=head2 prime_factor

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

=head1 SEE ALSO

For the time being, you will need to look at the source of
C<Music::Intervals::Ratio> for the note and interval names.

L<https://github.com/ology/Music/blob/master/intervals>

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
