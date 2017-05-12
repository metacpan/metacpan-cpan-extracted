package SVG::Estimate::Polyline;
$SVG::Estimate::Polyline::VERSION = '1.0107';
use Moo;
use Clone qw/clone/;

extends 'SVG::Estimate::Shape';
with 'SVG::Estimate::Role::Pythagorean';

=head1 NAME

SVG::Estimate::Polyline - Handles estimating multi-part lines.

=head1 VERSION

version 1.0107

=head1 SYNOPSIS

 my $line = SVG::Estimate::Polyline->new(
    transformer => $transform,
    start_point => [45,13],
    points      => '20,20 40,25 60,40 80,120 120,140 200,180',
 );

 my $length = $line->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Shape> and consumes L<SVG::Estimate::Role::Pythagorean>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item points

A string listing points for the polyline as defined by L<http://www.w3.org/TR/SVG/shapes.html>.

=back

=cut

has points => (
    is          => 'ro',
    required    => 1,
);

=head2 parsed_points() 

Returns an array reference of array references marking the parsed C<points> string.

=cut

has parsed_points => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->parse_points($self->points);
    },
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    my $string = $args->{points};
    $string =~ s/^\s+|\s+$//g;
    my @pairs = $class->_get_pairs($string);
    my @points = ();
    my ($min_x, $max_x, $min_y, $max_y) = (1e10, -1e10, 1e10, -1e10);
    my $first  = 1;
    my $start  = [];
    my $length = 0;
    PAIR: foreach my $pair (@pairs) {
        my $point =  [ split ',', $pair ];
        if ($args->{transformer}->has_transforms) {
            $point = $args->{transformer}->transform($point);
        }
        $min_x = $point->[0] if $point->[0] < $min_x;
        $max_x = $point->[0] if $point->[0] > $max_x;
        $min_y = $point->[1] if $point->[1] < $min_y;
        $max_y = $point->[1] if $point->[1] > $max_y;
        push @points, $point;
        if ($first) {
            $first = 0;
            $start = $point;
            next PAIR;
        }
        $length += $class->pythagorean($start, $point);
        $start = $point;
    }
    $args->{parsed_points} = \@points;
    $args->{min_x} = $min_x;
    $args->{max_x} = $max_x;
    $args->{min_y} = $min_y;
    $args->{max_y} = $max_y;
    $args->{draw_start}   = clone $points[0];
    $args->{draw_end}     = clone $points[-1];
    $args->{shape_length} = $length;
    return $args;
}

##This method is here so that Polygon can wrap it to add a closing point.

sub _get_pairs {
    my ($class, $string) = @_;
    return split ' ', $string;
}

1;
