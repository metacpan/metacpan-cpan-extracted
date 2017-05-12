package Random::PoissonDisc;
use strict;
use List::Util qw(sum);
use Math::Random::MT::Auto qw(rand gaussian);

use vars qw($VERSION %grid_neighbours);
$VERSION = '0.02';

# %grid_neighbours caches the vectors pointing to
# neighbours

=head1 NAME

Random::PoissonDisc - distribute points aesthetically in R^n

=head1 SYNOPSIS

    my $points = Random::PoissonDisc->points(
        dimensions => [100,100],
        r => $r,
    );
    print join( ",", @$_),"\n"
        for @$points;

This module allows relatively fast
(linear in the number of points generated) generation of random points in
I<n>-dimensional space with a distance of
at least C<r> between each other. This distribution
results in aesthetic so called "blue noise".

The algorithm was adapted from a sketch
by Robert Bridson
in L<http://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf>.

=head1 DATA REPRESENTATION

All vectors (or points) are represented
as anonymous arrays of numbers. All have the same
dimension as the cardinality of the C<dimensions>
array passed in the C<< ->points >> method.

=head2 USER INTERFACE

=head3 C<< Random::PoissonDisc->points( %options ) >>

Returns a reference to an array of points.

Acceptable options are:

=over 4

=item *

C< r > - minimum distance between points.

Default is 10 units.

=item *

C< dimensions > - number of dimensions and respective value range as an arrayref.

Default is

    [ 100, 100 ]

meaning all points will be in R^2 , with each coordinate in the
range [0, 100).

=item *

C< candidates > - Number of candidates to inspect before deciding that no
ew neighbours can be placed around a point.

Default is 30.

This number may or may not need to be tweaked if you go further up in
dimensionality beyond 3 dimensions. The more candidates you inspect
the longer the algorithm will run for generating a number of points.

In the algorithm description, this constant is named I<k>.

=back

=cut

sub points {
    my ($class,%options) = @_;
    
    $options{candidates} ||= 30;
    $options{dimensions} ||= [100,100]; # do we only create integral points?
    $options{r} ||= 10;
    #$options{max} ||= 10; # we want to fill the space instead?!
    $options{ grid } ||= {};
    
    my $grid_size = $options{ r } / sqrt( 0+@{$options{dimensions}});
    
    my @result;
    my @work;
        
    # Create a first random point somewhere in our cube:
    my $p = [map { rnd(0,$_) } @{ $options{ dimensions }}];
    push @result, $p;
    push @work, $p;
    my $c = grid_coords($grid_size, $p);
    $options{ grid }->{ $c } = $p;
    
    while (@work) {
        my $origin = splice @work, int rnd(0,$#work), 1;
        CANDIDATE: for my $candidate ( 1..$options{ candidates } ) {
            # Create a random distance between r and 2r
            # that is, in the annulus with radius (r,2r)
            # surrounding our current point
            my $dist = rnd( $options{r}, $options{r}*2 );
            
            # Choose a random angle in which to point
            # this vector
            my $angle = random_unit_vector(0+@{$options{ dimensions}});
            
            # Generate a new point by adding the $angle*$dist to $origin
            my $p = [map { $origin->[$_] + $angle->[$_]* $dist } 0..$#$angle];
            
            # Check whether our point lies within the dimensions
            for (0..$#$p) {
                 next CANDIDATE
                    if   $p->[$_] >= $options{ dimensions }->[ $_ ]
                      or $p->[$_] < 0
            };
            
            # check discs by using the grid
            # Here we should check the "neighbours" in the grid too
            my $c = grid_coords($grid_size, $p);
            if (! $options{ grid }->{ $c }) {
                my @n = neighbour_points($grid_size, $p, $options{ grid });
                for my $neighbour (@n) {
                    if( vdist($neighbour, $p) < $options{ r }) {
                        next CANDIDATE;
                    };
                };
                
                # not already in grid, no close neighbours, add it
                push @result, $p;
                push @work, $p;
                $options{ grid }->{ $c } = $p;
                #warn "$candidate Taking";
            } else {
                #warn "$candidate Occupied";
            };
        };
    };
    
    \@result
};

=head2 INTERNAL SUBROUTINES

These subroutines are used for the algorithm.
If you want to port this module to PDL or any other
vector library, you will likely have to rewrite these.

=head3 C<< rnd( $low, $high ) >>

    print rnd( 0, 1 );

Returns a uniform distributed random number
in C<< [ $low, $high ) >>.

=cut

sub rnd {
    my ($low,$high) = @_;
    return $low + rand($high-$low);
};

=head3 C<< grid_coords( $grid_size, $point ) >>

Returns the string representing the coordinates
of the grid cell in which C<< $point >> falls.

=cut

sub grid_coords {
    my ($size,$point) = @_;
    join "\t", map { int($_/$size) } @$point;
};

=head3 C<< norm( @vector ) >>

    print norm( 1,1 ); # 1.4142

Returns the Euclidean length of the vector, passed in as array.

=cut

sub norm {
    sqrt( sum @{[map {$_**2} @_]} );
};

=head3 C<< vdist( $l, $r ) >>

    print vdist( [1,0], [0,1] ); # 1.4142

Returns the Euclidean distance between two points
(or vectors)

=cut

sub vdist {
    my ($l,$r) = @_;
    my @connector = map { $l->[$_] - $r->[$_] } 0..$#$l;
    norm(@connector);
};

=head3 C<< neighbour_points( $size, $point, $grid ) >>

    my @neighbours = neighbour_points( $size, $p, \%grid )

Returns the points from the grid that have a distance
between 0 and 2r around C<$point>. These points are
the candidates to check when trying to insert a new
random point into the space.

=cut

sub neighbour_points {
    my ($size,$point,$grid) = @_;
    
    my $dimension = 0+@$point;
    my $vectors;
    if (! $grid_neighbours{ $dimension }) {
        my @elements = (-1,0,1);
        $grid_neighbours{ $dimension } =
        # Count up, and use the number in ternary as our odometer
        [map {
            my $val = $_;
            my $res = [ map { 
                          my $res = $elements[ $val % 3 ];
                          $val = int($val/3);
                          $res
                        } 1..$dimension ];
            } (1..3**$dimension)
        ];
    };
    
    my @coords = split /\t/, grid_coords( $size, $point );

    # Find the elements in the grid according to the offsets
    map {
        my $e = $_;
        my $n = join "\t", map { $coords[$_]+$e->[$_] } 0..$#$_;
        # Negative grid positions never get filled, conveniently!
        $grid->{ $n } ? $grid->{ $n } : ()
    } @{ $grid_neighbours{ $dimension }};
};

=head3 C<< random_unit_vector( $dimensions ) >>

    print join ",", @{ random_unit_vector( 2 ) };

Returns a vector of unit length
pointing in a random uniform distributed
I<n>-dimensional direction
angle
and returns a unit vector pointing in
that direction

The algorithm used is outlined in 
Knuth, _The Art of Computer Programming_, vol. 2,
3rd. ed., section 3.4.1.E.6.
but has not been verified formally or mathematically
by the module author.

=cut

sub random_unit_vector {
    my ($dimensions) = @_;
    my (@vec,$len);
    
    # Create normal distributed coordinates
    RETRY: {
        @vec = map { gaussian() } 1..$dimensions;
        $len = norm(@vec);
        redo RETRY unless $len;
    };
    # Normalize our vector so we get a unit vector
    @vec = map { $_ / $len } @vec;
    
    \@vec
};

1;

=head1 TODO

The module does not use L<PDL> or any other
vector library.

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/random-poissondisc>.

=head1 SUPPORT

The public support forum of this module is
L<http://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Random-PoissonDisc>
or via mail to L<random-poissondisc@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2011 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
