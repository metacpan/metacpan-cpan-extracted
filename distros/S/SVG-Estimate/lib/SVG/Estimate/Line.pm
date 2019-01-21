package SVG::Estimate::Line;
$SVG::Estimate::Line::VERSION = '1.0111';
use Moo;

extends 'SVG::Estimate::Shape';
with 'SVG::Estimate::Role::Pythagorean';

=head1 NAME

SVG::Estimate::Line - Handles estimating straight lines.

=head1 VERSION

version 1.0111

=head1 SYNOPSIS

 my $line = SVG::Estimate::Line->new(
    transformer => $transform,
    start_point => [45,13],
    x1          => 1,
    y1          => 3,
    x2          => 4.6,
    y2          => 3,
 );

 my $length = $line->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Shape> and consumes L<SVG::Estimate::Role::Pythagorean>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item x1

Float representing the x start point.

=item y1

Float representing the y start point.

=item x2 

Float representing the x end point.

=item y2

Float representing the y end point.

=back

=cut

has x1 => (
    is => 'ro',
    default => sub { 0 },
);

has y1 => (
    is => 'ro',
    default => sub { 0 },
);

has x2 => (
    is => 'ro',
    default => sub { 0 },
);

has y2 => (
    is => 'ro',
    default => sub { 0 },
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    foreach my $arg (qw(x1 x2 y1 y2)) {
        $args->{$arg} //= 0;
    }
    return $args unless exists $args->{transformer};
    my $point1 = $args->{transformer}->transform([$args->{x1}, $args->{y1}]);
    my $point2 = $args->{transformer}->transform([$args->{x2}, $args->{y2}]);
    $args->{x1} = $point1->[0];
    $args->{y1} = $point1->[1];
    $args->{x2} = $point2->[0];
    $args->{y2} = $point2->[1];
    $args->{draw_start} = $point1;
    $args->{draw_end}   = $point2;
    $args->{min_y} = $args->{y1} < $args->{y2} ? $args->{y1} : $args->{y2};
    $args->{max_y} = $args->{y1} > $args->{y2} ? $args->{y1} : $args->{y2};
    $args->{min_x} = $args->{x1} < $args->{x2} ? $args->{x1} : $args->{x2};
    $args->{max_x} = $args->{x1} > $args->{x2} ? $args->{x1} : $args->{x2};
    $args->{shape_length} = $class->pythagorean($point1, $point2);
    return $args;
}

1;
