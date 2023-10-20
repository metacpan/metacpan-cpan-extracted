package Music::Interval::Barycentric;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Compute barycentric musical interval space

use strict;
use warnings;

our $VERSION = '0.0401';

use List::Util qw( min );

use Exporter 'import';

our @EXPORT = qw(
    barycenter
    distance
    evenness_index
    orbit_distance
    forte_distance
    cyclic_permutation
    inversion
);

use constant SIZE  => 3;  # Default chord size
use constant SCALE => 12; # Default number of scale notes


sub barycenter {
    my $size  = shift || SIZE;  # Default to a triad
    my $scale = shift || SCALE; # Default to the common scale notes
    return ($scale / $size) x $size;
}


sub distance {
    my ($chord1, $chord2) = @_;
    my $distance = 0;
    for my $note (0 .. @$chord1 - 1) {
        $distance += ($chord1->[$note] - $chord2->[$note]) ** 2;
    }
    $distance /= 2;
    return sqrt $distance;
}


sub orbit_distance {
    my ($chord1, $chord2) = @_;
    my @distance = ();
    for my $perm (cyclic_permutation(@$chord2)) {
        push @distance, distance($chord1, $perm);
    }
    return min(@distance);
}


sub forte_distance {
    my ($chord1, $chord2) = @_;
    my @distance = ();
    for my $perm (cyclic_permutation(@$chord2)) {
        push @distance, distance($chord1, $perm);
        push @distance, distance($chord1, [reverse @$perm]);
    }
    return min(@distance);
}


sub cyclic_permutation {
    my @set = @_;
    my @cycles = ();
    for my $backward (reverse 0 .. @set - 1) {
        for my $forward (0 .. @set - 1) {
            push @{ $cycles[$backward] }, $set[$forward - $backward];
        }
    }
    return @cycles;
}


sub evenness_index {
    my $chord = shift;
    my @b = barycenter( scalar @$chord );
    my $i = distance( $chord, \@b );
    return $i;
}


sub inversion {
    my $chord = shift;
    return [ reverse @$chord ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Interval::Barycentric - Compute barycentric musical interval space

=head1 VERSION

version 0.0401

=head1 SYNOPSIS

 use Music::Interval::Barycentric;

 my @chords = ([3,4,5], [0,4,7]); # Given in "pitch-class notation"

 my $dist = distance(@chords);
 $dist = orbit_distance(@chords);
 $dist = forte_distance(@chords);
 my $even = evenness_index($chords[0]);

 my @cycles = cyclic_permutation($chords[0]);
 # [3,4,5], [5,3,4], [4,5,3]

 my @center = barycenter(scalar @{ $chords[0] });
 # [4,4,4]

=head1 DESCRIPTION

Barycentric chord analysis

From the book (linked below):

"An intervallic representation of the chord leads naturally to a discrete
barycentric condition. This condition itself leads to a convenient geometric
representation of the chordal space as a simplicial grid.

Chords appear as points in this grid and musical inversions of the chord would
generate beautiful polyhedra inscribed in concentric spheres centered at the
barycenter. The radii of these spheres would effectively quantify the evenness
and thus the consonance of the chord."

=head1 FUNCTIONS

=head2 barycenter

 @point = barycenter;
 @point = barycenter($chord_size);
 @point = barycenter($chord_size, $scale_notes);

Return the barycenter (the "central coordinate") given an optional integer
representing the number of notes in a chord, and an optional number of notes in
the scale.

Defaults:

  chord_size: 3
  scale_notes: 12

=head2 distance

 $d = distance($chord1, $chord2);

Common Euclidean space distance metric between chords (vectors).

This function takes two array references representing chords.

=head2 orbit_distance

  $d = orbit_distance($chord1, $chord2);

Return the distance from C<chord1> to the minimum of the cyclic permutations
for C<chord2>.

This function takes two array references representing chords.

=head2 forte_distance

  $d = forte_distance($chord1, $chord2);

Return the distance from C<chord1> to the minimum of the cyclic permutations and
reverse cyclic permutations for C<chord2>.

This function takes two array references representing chords.

=head2 cyclic_permutation

 @cycles = cyclic_permutation(@intervals);

Return the list of cyclic permutations of the given intervals.

This function takes a list of array references representing chords.

=head2 evenness_index

  $e = evenness_index($chord);

Return a chord distance from the barycenter.

This function takes an array reference representing a chord.

=head2 inversion

  my $inverted = inversion($chord);

"The inversion of a chord is formed by displaying the "retrograde"
representation of the original chord."

This function takes an array reference representing a chord.

=head1 SEE ALSO

L<List::Util>

The F<t/01-functions.t> and F<eg/*> programs in this distribution.

L<http://www.amazon.com/Geometry-Musical-Chords-Interval-Representation/dp/145022797X>
"A New Geometry of Musical Chords in Interval Representation: Dissonance, Enrichment, Degeneracy and Complementation"

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
