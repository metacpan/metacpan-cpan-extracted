package SVG::Estimate::Path::Moveto;
$SVG::Estimate::Path::Moveto::VERSION = '1.0116';
use Moo;

extends 'SVG::Estimate::Path::Command';
with 'SVG::Estimate::Role::Pythagorean';

=head1 NAME

SVG::Estimate::Path::Moveto - Handles estimating non-drawn movement.

=head1 VERSION

version 1.0116

=head1 SYNOPSIS

 my $move = SVG::Estimate::Path::Moveto->new(
    transformer     => $transform,
    start_point     => [13, 19],
    point           => [45,13],
 );

 my $travel_length = $move->travel_length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Path::Command> and consumes L<SVG::Estimate::Role::Pythagorean>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item point

An array ref containing two floats that represent a point. 

=back

=cut

has point => (
    is          => 'ro',
    required    => 1,
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    my $point  = $args->{point};
    if ($args->{transformer}->has_transforms) {
        $point   = $args->{transformer}->transform($point);
    }
    $args->{start_point}  = $args->{start_point};
    $args->{end_point}    = $point;
    $args->{min_x}        = $point->[0];
    $args->{min_y}        = $point->[1];
    $args->{max_x}        = $point->[0];
    $args->{max_y}        = $point->[1];
    $args->{travel_length} = $class->pythagorean($args->{start_point}, $args->{end_point});
    $args->{shape_length}  = 0;
    return $args;
}

1;
