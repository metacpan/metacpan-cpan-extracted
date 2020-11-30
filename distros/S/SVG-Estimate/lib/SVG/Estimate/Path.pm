package SVG::Estimate::Path;
$SVG::Estimate::Path::VERSION = '1.0115';
use Moo;
use Image::SVG::Path qw/extract_path_info/;
use SVG::Estimate::Path::Moveto;
use SVG::Estimate::Path::Lineto;
use SVG::Estimate::Path::CubicBezier;
use SVG::Estimate::Path::QuadraticBezier;
use SVG::Estimate::Path::HorizontalLineto;
use SVG::Estimate::Path::VerticalLineto;
use SVG::Estimate::Path::Arc;
use Clone qw/clone/;
use Ouch;

extends 'SVG::Estimate::Shape';

=head1 NAME

SVG::Estimate::Path - Handles estimating arbitrary vectors.

=head1 VERSION

version 1.0115

=head1 SYNOPSIS

 my $path = SVG::Estimate::Path->new(
    transformer => $transform,
    start_point => [45,13],
    d           => 'M150 0 L75 200 L225 200 Z',
 );

 my $length = $path->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Shape>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item d

An SVG path string as described L<http://www.w3.org/TR/SVG/paths.html>.

=back

=cut

has d => ( is => 'ro', required => 1, );
has commands => ( is => 'ro', );
has internal_travel_length => ( is => 'ro', required => 1, );
has summarize => ( is => 'ro', default => sub { 0 }, );

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };

    if (! exists $args->{d} || $args->{d} =~ /^\s*$/) {
        $args->{d} = "m 0 0";
    }
    my @path_info = extract_path_info($args->{d}, { absolute => 1, no_shortcuts=> 1, });
    my @commands = ();

    my $first_flag = 1;
    my $first;
    my $cursor  = clone $args->{start_point};
    $args->{length} = 0;
    foreach my $subpath (@path_info) {
        $subpath->{transformer} = $args->{transformer};
        ##On the first command, set the start point to the moveto destination, otherwise the travel length gets counted twice.
        $subpath->{start_point} = clone $cursor;
        my $command = $subpath->{type} eq 'moveto'             ? SVG::Estimate::Path::Moveto->new($subpath)
                    : $subpath->{type} eq 'line-to'            ? SVG::Estimate::Path::Lineto->new($subpath)
                    : $subpath->{type} eq 'cubic-bezier'       ? SVG::Estimate::Path::CubicBezier->new($subpath)
                    : $subpath->{type} eq 'quadratic-bezier'   ? SVG::Estimate::Path::QuadraticBezier->new($subpath)
                    : $subpath->{type} eq 'horizontal-line-to' ? SVG::Estimate::Path::HorizontalLineto->new($subpath)
                    : $subpath->{type} eq 'vertical-line-to'   ? SVG::Estimate::Path::VerticalLineto->new($subpath)
                    : $subpath->{type} eq 'arc'                ? SVG::Estimate::Path::Arc->new($subpath)
                    : $subpath->{type} eq 'closepath'          ? '' #Placeholder so we don't fall through
                    : ouch('unknown_path', "Unknown subpath type ".$subpath->{type}) ;  ##Something bad happened
        if ($subpath->{type} eq 'closepath') {
            $subpath->{point} = clone $first->point;
            $command = SVG::Estimate::Path::Lineto->new($subpath);
        }
        $cursor = clone $command->end_point;
        if ($first_flag) {
            ##Save the first point in order to handle a closepath, if it exists
            $first_flag = 0;
            $first = $command; ##According to SVG, this will be a Moveto.
            $args->{min_x}      = $command->min_x;
            $args->{max_x}      = $command->max_x;
            $args->{min_y}      = $command->min_y;
            $args->{max_y}      = $command->max_y;
            $args->{draw_start} = $command->end_point;
        }
        elsif ($subpath->{type} eq 'moveto') {
            $first = $command;  ##Save for the next close, if it comes
        }
        $args->{shape_length}  += $command->shape_length;
        $args->{internal_travel_length} += $command->travel_length;
        $args->{min_x} = $command->min_x if $command->min_x < $args->{min_x};
        $args->{max_x} = $command->max_x if $command->max_x > $args->{max_x};
        $args->{min_y} = $command->min_y if $command->min_y < $args->{min_y};
        $args->{max_y} = $command->max_y if $command->max_y > $args->{max_y};
        if (exists $args->{summarize} && $args->{summarize}) {
            $command->summarize_myself;
        }
        push @commands, $command;
    }
    $args->{draw_end} = $cursor;

    $args->{commands}      = \@commands;
    return $args;
}

##Return the internally calculated travel length, not the standard one use by SVG::Estimate::Shape
sub travel_length {
    my $self = shift;
    my $length = $self->internal_travel_length;
    return $length;
}

1;
