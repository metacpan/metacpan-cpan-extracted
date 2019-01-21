package SVG::Estimate::Role::Pythagorean;
$SVG::Estimate::Role::Pythagorean::VERSION = '1.0111';
use strict;
use Moo::Role;

=head1 NAME

SVG::Estimate::Role::Pythagorean - Use Pythagorean theorem to calc distance

=head1 VERSION

version 1.0111

=head1 METHODS

=head2 pythagorean ( point1, point2 )

Calculates the distance between two points.

=cut

sub pythagorean {
    my ($self, $p1, $p2) = @_;
    my $dy = $p2->[1] - $p1->[1];
    my $dx = $p2->[0] - $p1->[0];
    return sqrt(($dx**2)+($dy**2)); 
}


1;
