package Music::Intervals::Numeric;
$Music::Intervals::Numeric::VERSION = '0.0905';
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Breakdown of numeric musical intervals

use strict;
use warnings;

use Algorithm::Combinatorics qw( combinations );
use Math::Factor::XS qw( prime_factors );
use Number::Fraction ();
use Music::Intervals::Ratios;
use Moo;
use strictures 2;
use namespace::clean;


has notes => (
    is => 'ro',
    default => sub { [qw( 1/1 5/4 3/2 )] },
);


has ratios => (
    is      => 'ro',
    builder => 1,
);
sub _build_ratios {
  my ($self) = @_;
  no warnings 'once';
  my $ratios = { map {
    $Music::Intervals::Ratios::ratio->{$_}{ratio} => $Music::Intervals::Ratios::ratio->{$_}{name}
  } keys %$Music::Intervals::Ratios::ratio };
  return $ratios;
}

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

has _semitones => ( is => 'ro', default => sub { 12 } );
has _temper    => ( is => 'ro', lazy => 1, default => sub { my $self = shift;
    $self->_semitones * 100 / log(2) },
);


sub frequencies {
    my ($self) = @_;

    my %frequencies = map { $_ => $self->ratios->{$_} } @{ $self->notes };

    return \%frequencies;
}

sub intervals {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %intervals = map {
        $_ => {
            $dyads{$_} => $self->ratios->{ $dyads{$_} }
        }
    } keys %dyads;

    return \%intervals;
}

sub cent_vals {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %cent_vals = map {
        $_ => log( eval $dyads{$_} ) * $self->_temper
    } keys %dyads;
            
    return \%cent_vals;
}

sub prime_factor {
    my ($self) = @_;

    my %dyads = %{ $self->_dyads };

    my %prime_factor = map {
        $_ => {
            $dyads{$_} => scalar ratio_factorize( $dyads{$_} )
        }
    } keys %dyads;

    return \%prime_factor;
}


sub dyads {
    my $self = shift;
    my ($c) = @_;

    return () if @$c <= 1;

    my @pairs = combinations( $c, 2 );

    my %dyads;
    for my $i (@pairs) {
        # Construct our "dyadic" fraction.
        my $numerator   = Number::Fraction->new( $i->[1] );
        my $denominator = Number::Fraction->new( $i->[0] );
        my $fraction = $numerator / $denominator;

        $dyads{"@$i"} = $fraction->to_string;
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

Music::Intervals::Numeric - Breakdown of numeric musical intervals

=head1 VERSION

version 0.0905

=head1 SYNOPSIS

  use Music::Intervals::Numeric;

  my $m = Music::Intervals::Numeric->new(
    notes => [qw( 1/1 6/5 3/2 15/8 )],
  );

  print Dumper(
    $m->frequencies,
    $m->intervals,
    $m->cent_vals,
    $m->prime_factor,
  );

  my $interval = $m->ratios->{'5/4'};

=head1 DESCRIPTION

A C<Music::Intervals> object shows the mathematical break-down of musical
intervals given as integer ratios.

=head1 ATTRIBUTES

=head2 notes

The actual notes to use in the computation

Default: C<[ 1/1 5/4 3/2 ]>  (C E G)

The list of notes may be any of the keys in the L<Music::Intervals::Ratio>
C<ratio> hashref.  This is very very long and contains useful intervals such as
those of the common scale and even the Pythagorean intervals, too.

=head2 ratios

Musical ratios keyed by interval fractions. Computed attribute if not
given.

=head1 METHODS

=head2 new

  $x = Music::Intervals->new(%arguments);

Create a new C<Music::Intervals> object.

=head2 cent_vals

Show cents.

=head2 frequencies

Show frequencies.

=head2 intervals

Show intervals.

=head2 prime_factor

Show the prime factorization.

=head2 dyads

Return pairs of the given combinations with fractional and pitch ratio parts.

=head2 ratio_factorize

Return the dyadic fraction as a prime factored expression.

=head1 SEE ALSO

L<Music::Intervals>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
