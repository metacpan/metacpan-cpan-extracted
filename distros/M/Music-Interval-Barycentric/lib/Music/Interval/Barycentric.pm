package Music::Interval::Barycentric;
our $AUTHORITY = 'cpan:GENE';
# ABSTRACT: Compute barycentric musical interval space

use strict;
use warnings;

our $VERSION = '0.0105';

use List::Util qw( min );
use Readonly;

Readonly my $SIZE  => 3;  # Triad chord
Readonly my $SCALE => 12; # Scale notes


sub barycenter {
    my $size  = shift || $SIZE;  # Default to a triad
    my $scale = shift || $SCALE; # Default to the common scale notes
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Interval::Barycentric - Compute barycentric musical interval space

=head1 VERSION

version 0.0105

=head1 SYNOPSIS

 use Music::Interval::Barycentric;
 print join(', ', Music::Interval::Barycentric::barycenter(3)), "\n";
 my @chords = ([3, 4, 5], [0, 4, 7]);
 printf "D: %.3f\n", Music::Interval::Barycentric::distance($chords[0], $chords[1]);
 print Music::Interval::Barycentric::evenness_index($chords[0]);
 print Music::Interval::Barycentric::orbit_distance(@chords), "\n";
 print Music::Interval::Barycentric::forte_distance(@chords), "\n";

=head1 DESCRIPTION

Barycentric chord analysis

=head1 FUNCTIONS

=head2 barycenter()

 @barycenter = barycenter($n);

Return the barycenter (the "central coordinate")  given an integer representing
the number of notes in a chord.

=head2 distance()

 $d = distance($chord1, $chord2);

Interval space distance metric between chords.

* This is used by the C<orbit_distance()> and C<evenness_index()> functions.

=head2 orbit_distance()

  $d = orbit_distance($chord1, $chord2);

Return the distance from C<chord1> to the minimum of the cyclic permutations
for C<chord2>.

=head2 forte_distance()

  $d = forte_distance($chord1, $chord2);

Return the distance from C<chord1> to the minimum of the cyclic permutations and
reverse cyclic permutations for C<chord2>.

=head2 cyclic_permutation()

 @cycles = cyclic_permutation(@intervals);

Return the list of cyclic permutations of the given intervals.

=head2 evenness_index()

  $d = evenness_index($chord);

Return a chord distance from the barycenter.

=head1 SEE ALSO

L<http://www.amazon.com/Geometry-Musical-Chords-Interval-Representation/dp/145022797X>
"A New Geometry of Musical Chords in Interval Representation: Dissonance, Enrichment, Degeneracy and Complementation"

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
