package SVG::Estimate::Rect;
$SVG::Estimate::Rect::VERSION = '1.0112';
use Moo;

extends 'SVG::Estimate::Shape';
with 'SVG::Estimate::Role::ArgsWithUnits';

=head1 NAME

SVG::Estimate::Rect - Handles estimating rectangles.

=head1 VERSION

version 1.0112

=head1 SYNOPIS

 my $rect = SVG::Estimate::Rect->new(
    transformer => $transform,
    start_point => [45,13],
    x           => 3,
    y           => 6,
    width       => 11.76,
    height      => 15.519,
 );

 my $length = $rect->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Shape>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item x

Float representing the top left corner x.

=item y

Float representing the top left corner y.

=item width

Float representing the width of the box.

=item height

Float representing the height of the box.

=back

=cut

has x => (
    is => 'ro',
    default => sub { 0 },
);

has y => (
    is => 'ro',
    default => sub { 0 },
);

has width => (
    is => 'ro',
    required => 1,
);

has height => (
    is => 'ro',
    required => 1,
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    $args->{x} //= 0;
    $args->{y} //= 0;
    my $origin   = [ $args->{x}, $args->{y} ];
    my $opposite = [ $args->{x} + $args->{width}, $args->{y} + $args->{height} ];
    if ($args->{transformer}->has_transforms) {
        $origin   = $args->{transformer}->transform($origin);
        $opposite = $args->{transformer}->transform($opposite);
        $args->{x} = $origin->[0] < $opposite->[0] ? $origin->[0] : $opposite->[0];
        $args->{y} = $origin->[1] < $opposite->[1] ? $origin->[1] : $opposite->[1];
        $args->{width}  = abs($opposite->[0] - $origin->[0]);
        $args->{height} = abs($opposite->[1] - $origin->[1]);
    }
    $args->{draw_start}   = $origin;
    $args->{draw_end}     = $origin;
    my $disabled = $args->{width} == 0 || $args->{height} == 0;
    $args->{shape_length} = $disabled ? 0 : ($args->{width} + $args->{height}) * 2;
    $args->{min_x}        = $origin->[0];
    $args->{min_y}        = $origin->[1];
    $args->{max_x}        = $opposite->[0];
    $args->{max_y}        = $opposite->[1];
    return $args;
}

sub args_with_units {
    return qw/width height/;
}

1;
