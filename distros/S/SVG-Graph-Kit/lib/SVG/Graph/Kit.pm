package SVG::Graph::Kit;
our $AUTHORITY = 'cpan:GENE';
# ABSTRACT: Data plotting with SVG

use strict;
use warnings;

our $VERSION = '0.0402';

use parent qw(SVG::Graph);

use SVG::Graph::Data;
use SVG::Graph::Data::Datum;
use Math::Trig;


sub new {
    my $class = shift;
    my %args = @_;

    # Move non-parent arguments to the kit.
    my %kit = ();
    for my $arg (qw(axis data plot polar)) {
        next unless exists $args{$arg};
        $kit{$arg} = $args{$arg};
        delete $args{$arg};
    }

    # Construct the SVG::Graph object with the remaining arguments.
    $args{width}  ||= 600;
    $args{height} ||= 600;
    $args{margin} ||= 35;
    my $self = $class->SUPER::new(%args);

    # Re-bless as a Graph::Kit object.
    bless $self, $class;
    $self->_setup(%kit);
    return $self;
}

sub _setup {
    my $self = shift;
    my %args = @_;

    # Start with an initial frame...
    my $frame = $self->add_frame;

    # Plot the data.
    if ($args{data}) {
        # Load the graph data and use the SVG::Graph::Data object for label making.
        $self->{graph_data} = _load_data($args{data}, $frame, $args{polar});
        # Add the data to the graph.
        my %plot = (
            stroke         => $args{plot}{stroke}         || 'red',
            fill           => $args{plot}{fill}           || 'red',
            'fill-opacity' => $args{plot}{'fill-opacity'} || 0.5,
        );
        $args{plot}{type} ||= 'scatter';
        $frame->add_glyph($args{plot}{type}, %plot);
    }

    # Handle the axis unless it's set to 0.
    if (not(exists $args{axis}) or exists $args{axis} and $args{axis}) {
        my %axis = $self->_load_axis($args{data}, $args{axis});
        $frame->add_glyph('axis', %axis);
    }
}

sub _load_axis {
    my($self, $data, $axis) = @_;

    # Initialize an empty axis unless given a hashref.
    $axis = {} if not ref $axis eq 'HASH';

    # Set the default properties and user override.
    my %axis = (
        x_intercept => 0,
        y_intercept => 0,
        stroke => 'gray',
        'stroke-width' => 2,
        ticks => 30, # Max data per axis
        log => 0,
        %$axis, # User override
    );

    # Set the number of ticks to show on each axis.
    $axis{xticks} ||= $axis{ticks};
    $axis{yticks} ||= $axis{ticks};

    # Set the logarithmic scaling factor.
    $axis{xlog} ||= $axis{log};
    $axis{ylog} ||= $axis{log};

    # Compute scale factors.
    my ($xscale, $yscale) = (1, 1);
    if ($data and $self->{graph_data}->xmax - $self->{graph_data}->xmin > $axis{xticks}) {
        # Round to the integer, i.e. 0 decimal places.
        $xscale = sprintf '%.0f', $self->{graph_data}->xmax / $axis{xticks};
    }
    if ($data and $self->{graph_data}->ymax - $self->{graph_data}->ymin > $axis{yticks}) {
        # Round to the integer, i.e. 0 decimal places.
        $yscale = sprintf '%.0f', $self->{graph_data}->ymax / $axis{yticks};
    }

    # Use absolute_ticks if no tick mark setting is provided.
    unless (defined $axis{x_absolute_ticks} or defined $axis{x_fractional_ticks}) {
        $axis{x_absolute_ticks} = $xscale;
    }
    unless (defined $axis{y_absolute_ticks} or defined $axis{y_fractional_ticks}) {
        $axis{y_absolute_ticks} = $yscale;
    }

    # Use increments of 1 to data-max for ticks if none are provided.
    if ($data and !defined $axis{x_tick_labels} and !defined $axis{x_intertick_labels}) {
        if ($xscale > 1) {
            $axis{x_tick_labels} = [ $self->{graph_data}->xmin ];
            push @{ $axis{x_tick_labels} }, $_ * $xscale for 1 .. $axis{ticks};
        }
        else {
            $axis{x_tick_labels} = [ $self->{graph_data}->xmin .. $self->{graph_data}->xmax ];
        }
    }
    if ($data and !defined $axis{y_tick_labels} and !defined $axis{y_intertick_labels}) {
        if ($yscale > 1) {
            $axis{y_tick_labels} = [ $self->{graph_data}->ymin ];
            push @{ $axis{y_tick_labels} }, $_ * $yscale for 1 .. $axis{ticks};
        }
        else {
            $axis{y_tick_labels} = [ $self->{graph_data}->ymin .. $self->{graph_data}->ymax ];
        }
    }

    # Remove keys not used by parent module.
    delete $axis{ticks};
    delete $axis{xticks};
    delete $axis{yticks};
    delete $axis{log};
    delete $axis{xlog};
    delete $axis{ylog};

    return %axis;
}

sub _load_data {
    my ($data, $frame, $polar) = @_;
    # Create individual data points.
    my @data = ();
    for my $datum (@$data) {
        # Set the coordinate.
        my @coord = @$datum;
        @coord = _to_polar($datum) if $polar;

        # Add our 3D data point.
        push @data, SVG::Graph::Data::Datum->new(
            x => $coord[0],
            y => $coord[1],
            z => $coord[2],
        );
    }
    # Instantiate a new SVG::Graph::Data object;
    my $obj = SVG::Graph::Data->new(data => \@data);
    # Populate our graph with data.
    $frame->add_data($obj);
    return $obj;
}

sub _theta {
    my $point = shift;
#    return int(rand 359);
    return atan2($point->[1], $point->[0]);
}

sub _to_polar {
    my $point = shift;
    my $r = 0;
    $r += $_ ** 2 for @$point;
    $r = sqrt $r;
    my $t = _theta($point);
    return $r, $t;
}


sub stat {
    my ($self, $dimension, $name, @args) = @_;
    my $method = $dimension . $name;
    return $self->{graph_data}->$method(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SVG::Graph::Kit - Data plotting with SVG

=head1 VERSION

version 0.0402

=head1 SYNOPSIS

  use SVG::Graph::Kit;
  my $data = [ [ 1,  2, 0 ],
               [ 2,  3, 1 ],
               [ 3,  5, 1 ],
               [ 4,  7, 2 ],
               [ 5, 11, 3 ],
               [ 6, 13, 5 ], ];
  my $g = SVG::Graph::Kit->new(data => $data);
  print $g->draw;
  my $n;
  for my $dim (qw(x y z)) {
    for my $stat (qw(min max mean mode median range stdv percentile)) {
      $n = $stat eq 'percentile' ? 90 : undef; # Inspect the 90th percentile.
      printf "%s %s = %0.2f\n", $dim, $stat, $g->stat($dim, $stat, $n);
    }
  }

=head1 DESCRIPTION

An C<SVG::Graph::Kit> object is an automated data plotter that is a
subclass of C<SVG::Graph>.

=head1 NAME

SVG::Graph::Kit - Data plotting with SVG

=head1 METHODS

=head2 new()

  $g = SVG::Graph::Kit->new();
  $g = SVG::Graph::Kit->new(data => \@numeric);
  $g = SVG::Graph::Kit->new(data => \@numeric, axis => 0);
  # Custom:
  $g = SVG::Graph::Kit->new(
    data => \@numeric,
    axis => { xticks => 10, yticks => 20 },
  );
  $g = SVG::Graph::Kit->new(
    width => 300, height => 300, margin => 20,
    data => [[0,2], [1,3] ... ],
    plot => {
      type => 'line', # default: scatter
      'fill-opacity' => 0.5, # etc.
    },
    axis => {
      'stroke-width' => 2, # etc.
      ticks => scalar @$data, # default: 30
      log => 2, # Default factor 10
    },
  );

Return a new C<SVG::Graph::Kit> instance.

Optional arguments:

  data => Numeric vectors (the datapoints)
  plot => Chart type and data rendering properties
  axis => Axis rendering properties or 0 for off

Except for the C<plot type>, C<axis =E<gt> 0> and C<axis ticks>, the
C<plot> and C<axis> arguments are ordinary CSS, 'a la C<SVG::Graph>.

The C<plot type> is given in C<SVG::Graph>.  C<axis =E<gt> 0> turns
off the rendering of the axis.  The C<axis ticks>, C<xticks> and
C<yticks> values represent the number of labeled tick marks displayed
on a scaled graph axis.

=head2 stat()

  $g->stat($dimension, $name);
  $g->stat('x', 'mean');
  $g->stat('y', 'stdv');
  $g->stat('z', 'percentile');
  # etc.

This method is a direct call to the appropriate C<SVG::Graph::Data>
"x-method" (i.e. min, max, mean, mode, median, range, stdv and
percentile).

=head1 TO DO

Allow log scaling.

Position axis origin.

Call any C<Statistics::Descriptive> method, not just those given by
C<SVG::Graph>.

Highlight data points or areas.

Draw grid lines.

Add an C<SVG::Graph::polar> chart?

=head1 SEE ALSO

The code in F<t/*>.

L<SVG::Graph>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
