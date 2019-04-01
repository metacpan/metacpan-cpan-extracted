package SVG::Estimate::Polyline;
$SVG::Estimate::Polyline::VERSION = '1.0112';
use Moo;
use Clone qw/clone/;
use List::Util qw/pairs/;

extends 'SVG::Estimate::Shape';
with 'SVG::Estimate::Role::Pythagorean';

=head1 NAME

SVG::Estimate::Polyline - Handles estimating multi-part lines.

=head1 VERSION

version 1.0112

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
        return [];
    },
);

##Blatantly stolen from Image::SVG::Path

# Match the e or E in an exponent.

my $e = qr/[eE]/;

# These regular expressions are directly taken from the SVG grammar,
# https://www.w3.org/TR/SVG/paths.html#PathDataBNF

our $sign = qr/\+|\-/;

our $wsp = qr/[\x20\x09\x0D\x0A]/;

our $comma_wsp = qr/(?:$wsp+,?$wsp*|,$wsp*)/;

# The following regular expression splits the path into pieces Note we
# only split on '-' or '+' when not preceeded by 'e'.  This regular
# expression is not following the SVG grammar, it is going our own
# way.

my $split_re = qr/
		     (?:
			 $wsp*,$wsp*
		     |
			 (?<!$e)(?=-)
		     |
			 (?<!$e)(?:\+)
		     |
			 $wsp+
		     )
		 /x;

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    my @pairs = $class->_get_pairs($args->{points});
    my ($min_x, $max_x, $min_y, $max_y) = (1e10, -1e10, 1e10, -1e10);
    my $first  = 1;
    my $start  = [];
    my $length = 0;
    PAIR: foreach my $point (@pairs) {
        if ($args->{transformer}->has_transforms) {
            $point = $args->{transformer}->transform($point);
        }
        $min_x = $point->[0] if $point->[0] < $min_x;
        $max_x = $point->[0] if $point->[0] > $max_x;
        $min_y = $point->[1] if $point->[1] < $min_y;
        $max_y = $point->[1] if $point->[1] > $max_y;
        if ($first) {
            $first = 0;
            $start = $point;
            next PAIR;
        }
        $length += $class->pythagorean($start, $point);
        $start = $point;
    }
    $args->{parsed_points} = \@pairs;
    $args->{min_x} = $min_x;
    $args->{max_x} = $max_x;
    $args->{min_y} = $min_y;
    $args->{max_y} = $max_y;
    $args->{draw_start}   = clone $pairs[0];
    $args->{draw_end}     = clone $pairs[-1];
    $args->{shape_length} = $length;
    return $args;
}

##This method is here so that Polygon can wrap it to add a closing point.

sub _get_pairs {
    my ($class, $string) = @_;
    my @points = split $split_re, $string;
    my @pairs = pairs @points;
    return @pairs;
}

1;
