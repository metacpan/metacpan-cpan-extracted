package SVG::Estimate::Path::VerticalLineto;
$SVG::Estimate::Path::VerticalLineto::VERSION = '1.0111';
use Moo;

extends 'SVG::Estimate::Path::Command';
with 'SVG::Estimate::Role::Pythagorean';

=head1 NAME

SVG::Estimate::Path::VerticalLineto - Handles estimating vertical lines.

=head1 VERSION

version 1.0111

=head1 SYNOPSIS

 my $line = SVG::Estimate::Path::VerticalLineto->new(
    transformer     => $transform,
    start_point     => [13, 19],
    y               => 45,
 );

 my $length = $line->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Path::Command> and consumes L<SVG::Estimate::Role::Pythagorean>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item y

A float representing what to change the y value to.

=back

=cut

has y => (
    is          => 'ro',
    required    => 1,
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    my $end  = [$args->{start_point}[0], $args->{y}];
    if ($args->{transformer}->has_transforms) {
        $end = $args->{transformer}->transform($end);
    }
    $args->{end_point}     = [$args->{start_point}[0], $end->[1]];
    $args->{y}             = $args->{end_point}[1];
    $args->{shape_length}  = $class->pythagorean($args->{start_point}, $args->{end_point});
    $args->{travel_length} = 0;
    $args->{min_x}         = $args->{start_point}[0] < $args->{end_point}->[0] ? $args->{start_point}[0] : $args->{end_point}->[0];
    $args->{min_y}         = $args->{start_point}[1] < $args->{end_point}->[1] ? $args->{start_point}[1] : $args->{end_point}->[1];
    $args->{max_x}         = $args->{start_point}[0] > $args->{end_point}->[0] ? $args->{start_point}[0] : $args->{end_point}->[0];
    $args->{max_y}         = $args->{start_point}[1] > $args->{end_point}->[1] ? $args->{start_point}[1] : $args->{end_point}->[1];
    return $args;
}

1;
