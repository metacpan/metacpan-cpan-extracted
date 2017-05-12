=head1 NAME

SVG::Plot - a simple module to take one or more sets of x,y points and plot them on a plane

=head1 SYNOPSIS

   use SVG::Plot;
   my $points = [ [0, 1, 'http://uri/'], [2, 3, '/uri/foo.png'] ];
   my $plot = SVG::Plot->new(
                              points      => $points,
                              debug       => 0,
                              scale       => 0.025,
                              max_width   => 800,
                              max_height  => 400,
                              point_size  => 3,
                              point_style => {
                                               fill   => 'blue',
                                               stroke => 'yellow',
                                             },
                              line        => 'follow',
                              margin      => 6,
                            ); 

   # -- or --
   $plot->points($points);
   $plot->scale(4);

   print $plot->plot;

=head1 DESCRIPTION

a very simple module which allows you to give one or more sets of points [x co-ord, y co-ord and optional http uri]) and plot them in SVG. 

$plot->points($points) where $points is a reference to an array of array references. 

see B<new> for a list of parameters you can give to the plot. (overriding the styles on the ponts; sizing a margin; setting a scale; optionally drawing a line ( line => 'follow' ) between the points in the order they are specified.

=cut

package SVG::Plot;

our $VERSION = '0.06';
use strict;
use SVG;
use Carp qw( croak );
use Algorithm::Points::MinimumDistance;

use Class::MethodMaker new_hash_init => 'new', get_set => [ qw( debug grid scale points pointsets image point_style point_size min_point_size max_point_size margin line line_style max_width max_height svg_options) ];

=head1 METHODS

=over 4

=item B<new>

  use SVG::Plot;

  # Simple use - single set of points, all in same style.
  my $points = [ [0, 1, 'http://uri/'], [2, 3, '/uri/foo.png'] ];
  my $plot = SVG::Plot->new(
                             points      => \@points,
                             point_size  => 3,
                             point_style => {
                                              fill   => 'blue',
                                              stroke => 'yellow',
                                            },
                             line        => 'follow',
                             debug       => 0,
                             scale       => 0.025,
                             max_width   => 800,
                             max_height  => 400,
                             margin      => 6,
                           );

  # Prepare to plot two sets of points, in distinct styles.
  my $pubs      = [
      [ 522770, 179023, "http://example.com/?Andover_Arms" ],
      [ 522909, 178232, "http://example.com/?Blue Anchor"  ] ];
  my $stations  = [
      [ 523474, 178483, "http://example.com/?Hammersmith" ] ];
  my $pointsets = [ { points      => $pubs,
                      point_size  => 3,
                      point_style => { fill => "blue" }
                    },
                    { points      => $stations,
                      point_size  => 5,
                      point_style => { fill => "red" }
                    } ];
  my $plot = SVG::Plot->new(
                             pointsets  => $pointsets,
                             scale      => 0.025,
                             max_width  => 800,
                             max_height => 400,
                           );

To pass options through to L<SVG>, use the C<svg_options> parameter:

  SVG::Plot->new( points      => $points,
                  svg_options => { -nocredits => 1 }
                );

You can define the boundaries of the plot:

  SVG::Plot->new(
    grid => { min_x => 1,
              min_y => 2,
              max_x => 15,
              max_y => 16 }
  );

or

  $plot->grid($grid)

This is like a viewbox onto the plane of the plot.  If it's not
specified, the module works out the viewbox from the highest and
lowest X and Y co-ordinates in the list(s) of points.

Note that the actual margin will be half of the value set
in C<margin>, since half of it goes to each side.

If C<max_width> and/or C<max_height> is set then C<scale> will be
reduced if necessary in order to keep the width down.

If C<debug> is set to true then debugging information is emitted as
warnings.

If C<point_size> is set to C<AUTO> then
L<Algorithm::Points::MinimumDistance> will be used to make the point
circles as large as possible without overlapping, within the
constraints of C<min_point_size> (which defaults to 1) and
C<max_point_size> (which defaults to 10).  Note that if you have multiple
pointsets then the point circle sizes will be worked out I<per set>.

All arguments have get_set accessors like so:

  $plot->point_size(3);

The C<point_size>, C<point_style> attributes of the SVG::Plot object
will be used as defaults for any pointsets that don't have their own
style set.

=cut

=item B<plot>

  print $plot->plot;

C<plot> will croak if the object has a C<max_width> or C<max_height>
attribute that is smaller than its C<margin> attribute, since this is
impossible.

=cut

sub plot {
    my $self = shift;
    my $points = $self->points;
    my $pointsets = $self->pointsets;
    croak "no points to plot!" unless ( $points or $pointsets );
    my $grid = $self->grid;

    if (not $grid) {
        $grid = $self->work_out_grid;
    }

    my $scale = $self->scale || 10;
    my $m = $self->margin || 10;
    
    # Reduce scale if necessary to fit to width constraint.
    if ( $self->max_width ) {
        my $max_plot_width = $self->max_width - $m; # Account for margin
        croak "max_width must be larger than margin"
            if $max_plot_width <= 0;
        my $x_extent = $grid->{max_x} - $grid->{min_x};
        my $max_width_scale = $max_plot_width / $x_extent;
        $scale = $max_width_scale if $scale > $max_width_scale;
    }

    # Reduce scale further if necessary to fit to height constraint.
    if ( $self->max_height ) {
        my $max_plot_height = $self->max_height - $m; # Account for margin
        croak "max_height must be larger than margin"
            if $max_plot_height <= 0;
        my $y_extent = $grid->{max_y} - $grid->{min_y};
        my $max_height_scale = $max_plot_height / $y_extent;
        $scale = $max_height_scale if $scale > $max_height_scale;
    }

    my $h = int(($grid->{max_y} - $grid->{min_y})*$scale);
    my $w = int(($grid->{max_x} - $grid->{min_x})*$scale);
 
    my $svg = SVG->new(
                        width  => $w + $m,
                        height => $h + $m,
                        %{ $self->svg_options || {} },
                      );

    if (my $map = $self->image) {
        my $img = $svg->image(
                              x=>0, y=>0,
                              '-href'=>$map, #may also embed SVG, e.g. "image.svg"
                              id=>'image_1'
                              );
    }

    # Process each pointset.
    my @pointset_data;

    if ( $self->points ) {
        push @pointset_data, { points         => $self->points,
                               point_size     => $self->point_size,
                               min_point_size => $self->min_point_size,
                               max_point_size => $self->max_point_size,
                               point_style    => $self->point_style,
                               line           => $self->line,
                               line_style     => $self->line_style };
    }

    foreach my $pointset ( @{$self->pointsets || []} ) {
        push @pointset_data, $pointset;
    }

    my %defaults = ( point_size     => $self->point_size,
                     min_point_size => $self->min_point_size,
                     max_point_size => $self->max_point_size,
                     point_style    => $self->point_style );

    foreach my $dataset ( @pointset_data ) {
        $self->_plot_pointset( svg         => $svg,
                               margin      => $m,
                               grid        => $grid,
                               scale       => $scale,
                               %defaults, # can be overridden by %$dataset
                               %$dataset );
    }

    return $svg->xmlify;
}

# Adds a pointset to the SVG plot - pass in args svg, margin, grid, scale,
# points, point_size, min_point_size, max_point_size, point_style,
# line, line_style.
sub _plot_pointset {
    my ($self, %args) = @_;
    my $points = $args{points} or croak "no points in pointset!";
    scalar @$points or croak "no points in pointset!";
    my $svg = $args{svg} or croak "no SVG object passed";
    my $scale = $args{scale} or croak "no scale passed";
    my $point_style = $args{point_style} || { stroke => 'red',
                                              fill => 'white' };

    my $z = $svg->tag( 'g',
                       id    => 'group_'.$self->random_id,
                       style => $point_style
                     );

    my $point_size = $args{point_size};
    if ( $point_size && $point_size eq "AUTO" ) {
        my $min_size = $args{min_point_size} || 1;
        my $max_size = $args{max_point_size} || 10;
        # Make sure we don't send URIs to A::P::MD
        my @coords = map { [ $_->[0], $_->[1] ] } @$points;
        my $boxsize = 1 + sprintf("%d", $max_size/$scale);
        my $dists = Algorithm::Points::MinimumDistance->new(
            points  => \@coords,
            boxsize => $boxsize );
        my $min_dist = $dists->min_distance;
        my $auto_size = sprintf("%d", $scale*$min_dist/2);
        $point_size = $auto_size;
        if ( $min_size and $point_size < $min_size ) {
            $point_size = $min_size;
        }
        if ( $max_size and $point_size > $max_size ) {
            $point_size = $max_size;
        }
    }

    $point_size ||= 3;
    my $plotted;

    foreach (@$points) {
        # adding a margin ... 
        my $halfm = $args{margin} / 2;

        my ($x,$y) = ($_->[0],$_->[1]);
        my $href = $_->[2] || $self->random_id;
        
        # svg is upside-down
        $x = int(($x - $args{grid}->{min_x})*$scale) + $halfm;
        $y = int(($args{grid}->{max_y} - $y)*$scale) + $halfm;

        push @$plotted, [$x,$y,$href];
        my $id = $self->random_id;
        warn("anchor_$id") if $self->debug;;

        $z->anchor(id => "anchor_".$id,
                   -href => $href,
                   -target => 'new_window_0')->circle(
                                                      cx => $x, cy => $y,
                                                      r => $point_size,
                                                      id    => 'dot_'.$id,
                                                  );
    }

    if (my $line = $args{line}) {
        my $style = $args{line_style};
        $style ||= {  'stroke-width' => 2, stroke => 'blue'  };

        if ($line eq 'follow') {
            for my $n (0..($#{$plotted}-1)) {
                my $p1 = $plotted->[$n];
                my $p2 = $plotted->[$n+1];
                my $tag = $svg->line(
                                     id => $self->random_id,
                                     x1 => $p1->[0], y1 => $p1->[1],
                                     x2 => $p2->[0], y2 => $p2->[1],
                                     style => $style
                                     );
            }
        }
    }
}

sub work_out_grid {
    my $self = shift;
    my $all_points = $self->points;
    my $pointsets = $self->pointsets;

    if ( $pointsets ) {
        foreach my $pointset ( map { $_->{points} } @$pointsets ) {
            foreach my $point ( @$pointset ) {
                push @$all_points, $point;
            }
        }
    }

    my $start = $all_points->[0];
    my ($lx,$ly,$hx,$hy);
    $lx = $start->[0];
    $hx = $lx;
    $ly = $start->[1];
    $hy = $ly;

    foreach (@$all_points) {

        $lx = $_->[0] if ($_->[0] <= $lx); 
        $ly = $_->[1] if ($_->[1] <= $ly);
        $hx = $_->[0] if ($_->[0] >= $hx);
        $hy = $_->[1] if ($_->[1] >= $hy);
    }
    return {
        min_x => $lx,
        max_x => $hx,
        min_y => $ly,
        max_y => $hy
    };
}

sub random_id {
    my @t = (0..9);
    return '_:id'.join '', (map { @t[rand @t] } 0..6);
}

=back

=cut
    
1;

=head1 NOTES

this is an early draft, released mostly so Kake can use it in OpenGuides without having non-CPAN dependencies.

for an example of what one should be able to do with this, see http://space.frot.org/rdf/tubemap.svg ... a better way of making meta-information between the lines, some kind of matrix drawing; cf the grubstreet link below, different styles according to locales, sets, conceptual contexts... 

it would be fun to supply access to different plotting algorithms, not just for the cartesian plane; particularly the buckminster fuller dymaxion map; cf Geo::Dymaxion, when that gets released (http://iconocla.st/hacks/dymax/ )

to see work in progress, http://un.earth.li/~kake/cgi-bin/plot2.cgi?cat=Pubs&cat=Restaurants&cat=Tube&colour_diff_this=loc&action=display 

=head1 BUGS

possibly. this is alpha in terms of functionality, beta in terms of code; the API won't break backwards, though. 


=head1 AUTHOR

    Jo Walsh  ( jo@london.pm.org )
    Kate L Pugh ( kake@earth.li )

=cut



