package SVG::Estimate::Path::HorizontalLineto;
$SVG::Estimate::Path::HorizontalLineto::VERSION = '1.0108';
use Moo;

extends 'SVG::Estimate::Path::Command';
with 'SVG::Estimate::Role::Pythagorean';

=head1 NAME

SVG::Estimate::Path::HorizontalLineto - Handles estimating horizontal lines.

=head1 VERSION

version 1.0108

=head1 SYNOPSIS

 my $line = SVG::Estimate::Path::HorizontalLineto->new(
    transformer     => $transform,
    start_point     => [13, 19],
    x               => 13,
 );

 my $length = $line->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Path::Command> and consumes L<SVG::Estimate::Role::Pythagorean>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item x

A float indicating what to change the x value to.

=back

=cut

has x => (
    is          => 'ro',
    required    => 1,
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    my $end  = [$args->{x}, $args->{start_point}[0]];
    if ($args->{transformer}->has_transforms) {
        $end = $args->{transformer}->transform($end);
    }
    $args->{end_point}     = [$end->[0], $args->{start_point}[1]];
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
