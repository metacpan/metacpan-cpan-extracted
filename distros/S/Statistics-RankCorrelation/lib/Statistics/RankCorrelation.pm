package Statistics::RankCorrelation;
our $AUTHORITY = 'cpan:GENE';
# ABSTRACT: Compute the rank correlation between two vectors

use strict;
use warnings;

our $VERSION = '0.1205';

use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;

    # Handle vector and named parameters.
    while( my $arg = shift ) {
        if( ref $arg eq 'ARRAY' ) {
               if( !defined $self->x_data ) { $self->x_data( $arg ) }
            elsif( !defined $self->y_data ) { $self->y_data( $arg ) }
        }
        elsif( !ref $arg ) {
            my $v = shift;
            $self->{$arg} = defined $v ? $v : $arg;
        }
    }

    # Automatically compute the ranks if given data.
    if( $self->x_data && $self->y_data &&
        @{ $self->x_data } && @{ $self->y_data }
    ) {
        # "Co-normalize" the vectors if they are of unequal size.
        my( $x, $y ) = pad_vectors( $self->x_data, $self->y_data );

        # "Co-sort" the bivariate data set by the first one.
        ( $x, $y ) = co_sort( $x, $y ) if $self->{sorted};

        # Set the massaged data.
        $self->x_data( $x );
        $self->y_data( $y );

        # Set the size of the data vector.
        $self->size( scalar @{ $self->x_data } );

        # Set the ranks and ties of the vectors.
        ( $x, $y ) = rank( $self->x_data );
        $self->x_rank( $x );
        $self->x_ties( $y );
        ( $x, $y ) = rank( $self->y_data );
        $self->y_rank( $x );
        $self->y_ties( $y );
    }
}

sub size {
    my $self = shift;
    $self->{size} = shift if @_;
    return $self->{size};
}

sub x_data {
    my $self = shift;
    $self->{x_data} = shift if @_;
    return $self->{x_data};
}

sub y_data {
    my $self = shift;
    $self->{y_data} = shift if @_;
    return $self->{y_data};
}

sub x_rank {
    my $self = shift;
    $self->{x_rank} = shift if @_;
    return $self->{x_rank};
}

sub y_rank {
    my $self = shift;
    $self->{y_rank} = shift if @_;
    return $self->{y_rank};
}

sub x_ties {
    my $self = shift;
    $self->{x_ties} = shift if @_;
    return $self->{x_ties};
}

sub y_ties {
    my $self = shift;
    $self->{y_ties} = shift if @_;
    return $self->{y_ties};
}

sub spearman {
    my $self = shift;
    # Algorithm contributed by Jon Schutz <Jon.Schutz@youramigo.com>:
    my($x_sum, $y_sum) = (0, 0);
    $x_sum += $_ for @{$self->{x_rank}};
    $y_sum += $_ for @{$self->{y_rank}};
    my $n = $self->size;
    my $x_mean = $x_sum / $n;
    my $y_mean = $y_sum / $n;
    # Compute the sum of the difference of the squared ranks.
    my($x_sum2, $y_sum2, $xy_sum) = (0, 0, 0);
    for( 0 .. $self->size - 1 ) {
        $x_sum2 += ($self->{x_rank}[$_] - $x_mean) ** 2;
        $y_sum2 += ($self->{y_rank}[$_] - $y_mean) ** 2;
        $xy_sum += ($self->{x_rank}[$_] - $x_mean) * ($self->{y_rank}[$_] - $y_mean);
    }
    return 1 if $x_sum2 == 0 || $y_sum2 == 0;
    return $xy_sum / sqrt($x_sum2 * $y_sum2);
}


sub rank {
    my $u = shift;

    # Make a list of tied ranks for each datum.
    my %ties;
    push @{ $ties{ $u->[$_] } }, $_ for 0 .. @$u - 1;

    my ($old, $cur) = (0, 0);

    # Set the averaged ranks.
    my @ranks;
    for my $x (sort { $a <=> $b } keys %ties) {
        # Get the number of ties.
        my $ties = @{ $ties{$x} };
        $cur += $ties;

        if ($ties > 1) {
            # Average the tied data.
            my $average = $old + ($ties + 1) / 2;
            $ranks[$_] = $average for @{ $ties{$x} };
        }
        else {
            # Add the single rank to the list of ranks.
            $ranks[ $ties{$x}[0] ] = $cur;
        }

        $old = $cur;
    }

    # Remove the non-tied ranks.
    delete @ties{ grep @{ $ties{$_} } <= 1, keys %ties };

    # Return the ranks arrayref in a scalar context and include ties
    # if called in a list context.
    return wantarray ? (\@ranks, \%ties) : \@ranks;
}

sub co_sort {
    my( $u, $v ) = @_;
    return unless @$u == @$v;
    # Ye olde Schwartzian Transforme:
    $v = [
        map { $_->[1] }
            sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] }
                map { [ $u->[$_], $v->[$_] ] }
                    0 .. @$u - 1
    ];
    # Sort the independent vector last.
    $u = [ sort { $a <=> $b } @$u ];
    return $u, $v;
}

sub csim {
    my $self = shift;

    # Get the pitch matrices for each vector.
    my $m1 = correlation_matrix($self->{x_data});
#warn map { "@$_\n" } @$m1;
    my $m2 = correlation_matrix($self->{y_data});
#warn map { "@$_\n" } @$m2;

    # Compute the rank correlation.
    my $k = 0;
    for my $i (0 .. @$m1 - 1) {
        for my $j (0 .. @$m1 - 1) {
            $k++ if $m1->[$i][$j] == $m2->[$i][$j];
        }
    }

    # Return the rank correlation normalized by the number of rows in
    # the pitch matrices.
    return $k / (@$m1 * @$m1);
}

sub pad_vectors {
    my ($u, $v) = @_;

    if (@$u > @$v) {
        $v = [ @$v, (0) x (@$u - @$v) ];
    }
    elsif (@$u < @$v) {
        $u = [ @$u, (0) x (@$v - @$u) ];
    }

    return $u, $v;
}

sub correlation_matrix {
    my $u = shift;
    my $c;

    # Is a row value (i) lower than a column value (j)?
    for my $i (0 .. @$u - 1) {
        for my $j (0 .. @$u - 1) {
            $c->[$i][$j] = $u->[$i] < $u->[$j] ? 1 : 0;
        }
    }

    return $c;
}

sub kendall {
    my $self = shift;

    # Calculate number of concordant and discordant pairs.
    my( $concordant, $discordant ) = ( 0, 0 );
    for my $i ( 0 .. $self->size - 1 ) {
        for my $j ( $i + 1 .. $self->size - 1 ) {
            my $x_sign = sign( $self->{x_data}[$j] - $self->{x_data}[$i] );
            my $y_sign = sign( $self->{y_data}[$j] - $self->{y_data}[$i] );
            if (not($x_sign and $y_sign)) {}
            elsif ($x_sign == $y_sign) { $concordant++ }
            else { $discordant++ }
        }
    }

    # Set the indirect relationship.
    my $d = $self->size * ($self->size - 1) / 2;
    if( keys %{ $self->x_ties } || keys %{ $self->y_ties } ) {
        my $x = 0;
        $x += @$_ * (@$_ - 1) for values %{ $self->x_ties };
        $x = $d - $x / 2;
        my $y = 0;
        $y += @$_ * (@$_ - 1) for values %{ $self->y_ties };
        $y = $d - $y / 2;
        $d = sqrt($x * $y);
    }

    return ($concordant - $discordant) / $d;
}

sub sign {
    my $x = shift;
    return 0 if $x == 0;
    return $x > 0 ? 1 : -1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::RankCorrelation - Compute the rank correlation between two vectors

=head1 VERSION

version 0.1205

=head1 SYNOPSIS

  use Statistics::RankCorrelation;

  $x = [ 8, 7, 6, 5, 4, 3, 2, 1 ];
  $y = [ 2, 1, 5, 3, 4, 7, 8, 6 ];

  $c = Statistics::RankCorrelation->new( $x, $y, sorted => 1 );

  $n = $c->spearman;
  $t = $c->kendall;
  $m = $c->csim;

  $s = $c->size;
  $xd = $c->x_data;
  $yd = $c->y_data;
  $xr = $c->x_rank;
  $yr = $c->y_rank;
  $xt = $c->x_ties;
  $yt = $c->y_ties;

=head1 DESCRIPTION

This module computes rank correlation coefficient measures between two 
sample vectors.

Examples can be found in the distribution C<eg/> directory and methods
test.

=head1 METHODS

=head2 new

  $c = Statistics::RankCorrelation->new( \@u, \@v );
  $c = Statistics::RankCorrelation->new( \@u, \@v, sorted => 1 );

This method constructs a new C<Statistics::RankCorrelation> object.

If given two numeric vectors (as array references), the statistical 
ranks are computed.  If the vectors are of different size, the shorter
is padded with zeros.

If the C<sorted> flag is set, both are sorted by the first (B<x>)
vector.

=head2 x_data

  $c->x_data( $y );
  $x = $c->x_data;

Set or return the one dimensional array reference data.  This is the
"unit" array, used as a reference for size and iteration.

=head2 y_data

  $c->y_data( $y );
  $x = $c->y_data;

Set or return the one dimensional array reference data.  This vector
is dependent on the x vector.

=head2 size

  $s = $c->size;

Return the number of array elements.

=head2 x_rank

  $r = $c->x_rank;

Return the ranks as an array reference.

=head2 y_rank

  $y = $c->y_rank;

Return the ranks as an array reference.

=head2 x_ties

  $t = $c->x_ties;

Return the x ties as a hash reference.

=head2 y_ties

  $t = $c->y_ties;

Return the y ties as a hash reference.

=head2 spearman

  $n = $c->spearman;

      6 * sum( (xi - yi)^2 )
  1 - --------------------------
             n^3 - n

Return Spearman's rho.

Spearman's rho rank-order correlation is a nonparametric measure of 
association based on the rank of the data values and is a special 
case of the Pearson product-moment correlation.

Here C<x> and C<y> are the two rank vectors and C<i> is an index 
from one to B<n> number of samples.

=head2 kendall

  $t = $c->kendall;

         c - d
  t = -------------
      n (n - 1) / 2

Return Kendall's tau.

Here, B<c> and B<d>, are the number of concordant and discordant
pairs and B<n> is the number of samples.

=head2 csim

  $n = $c->csim;

Return the contour similarity index measure.  This is a single 
dimensional measure of the similarity between two vectors.

This returns a measure in the (inclusive) range C<[-1..1]> and is 
computed using matrices of binary data representing "higher or lower" 
values in the original vectors.

This measure has been studied in musical contour analysis.

=head1 FUNCTIONS

=head2 rank

  $v = [qw(1 3.2 2.1 3.2 3.2 4.3)];
  $ranks = rank($v);
  # [1, 4, 2, 4, 4, 6]
  my( $ranks, $ties ) = rank($v);
  # [1, 4, 2, 4, 4, 6], { 1=>[], 3.2=>[]}

Return an list of an array reference of the ordinal ranks and a hash
reference of the tied data.

In the case of a tie in the data (identical values) the rank numbers
are averaged.  An example will elucidate:

  sorted data:    [ 1.0, 2.1, 3.2, 3.2, 3.2, 4.3 ]
  ranks:          [ 1,   2,   3,   4,   5,   6   ]
  tied ranks:     3, 4, and 5
  tied average:   (3 + 4 + 5) / 3 == 4
  averaged ranks: [ 1,   2,   4,   4,   4,   6   ]

=head2 pad_vectors

  ( $u, $v ) = pad_vectors( [ 1, 2, 3, 4 ], [ 9, 8 ] );
  # [1, 2, 3, 4], [9, 8, 0, 0]

Append zeros to either input vector for all values in the other that 
do not have a corresponding value.  That is, "pad" the tail of the 
shorter vector with zero values.

=head2 co_sort

  ( $u, $v ) = co_sort( $u, $v );

Sort the vectors as two dimensional data-point pairs with B<u> values
sorted first.

=head2 correlation_matrix

  $matrix = correlation_matrix( $u );

Return the correlation matrix for a single vector.

This function builds a square, binary matrix that represents "higher 
or lower" value within the vector itself.

=head2 sign

Return 0, 1 or -1 given a number.

=head1 TO DO

Handle any number of vectors instead of just two.

Implement other rank correlation measures that are out there...

=head1 SEE ALSO

For the C<csim> method:

L<http://personal.systemsbiology.net/ilya/Publications/JNMRcontour.pdf>

For the C<spearman> and C<kendall> methods:

L<http://mathworld.wolfram.com/SpearmanRankCorrelationCoefficient.html>

L<http://en.wikipedia.org/wiki/Kendall's_tau>

=head1 THANK YOU

For helping make this sturdier code:

Thomas Breslin

Jerome

Jon Schutz

Andy Lee

anno

mst

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
