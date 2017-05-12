package Music::Intervals::Numeric;
BEGIN {
  $Music::Intervals::Numeric::AUTHORITY = 'cpan:GENE';
}
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

version 0.0502

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

  # Show all the known intervals (the "notes" attribute above):
  perl -MData::Dumper -MMusic::Intervals::Ratio -e'print Dumper $Music::Intervals::Ratio::ratio'

=head1 DESCRIPTION

A C<Music::Intervals> object shows the mathematical break-down of musical
intervals and chords.

This module reveals the "guts" of chords within a given tonality.  By guts I
mean, the measurements of the notes and the intervals between them, in just
intonation.

=head1 METHODS

=head2 new()

  $x = Music::Intervals->new(%arguments);

=head2 Attributes and defaults

=over

=item cent: 0 - divisions of the octave

=item freq: 0 - frequencies

=item interval: 0 - note intervals

=item prime: 0 - prime factorization

=item size: 3 - chord size

=item semitones: 12 - number of notes in the scale

=item temper: semitones * 100 / log(2) - physical distance between notes

=item notes: [ 1/1 5/4 3/2 ] - C E G - actual notes to use in the computation

The list of notes may be any of the keys in the L<Music::Intervals::Ratio>
C<ratio> hashref.  This is very very long and contains useful intervals such as
those of the common scale and even the Pythagorean intervals, too.

=back

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

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
