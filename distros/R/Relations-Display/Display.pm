# The module's purpose is to take a query and return
# a graph and or table of the query's results.

package Relations::Display;
require Exporter;
require DBI;
require GD::Graph;
require Relations;
require Relations::Query;
require Relations::Abstract;
require 5.004;

use GD::Graph;
use Relations;
use Relations::Query;
use Relations::Abstract;
use Relations::Display::Table;

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright 2001 GAF-3 Industries, Inc. All rights reserved.
# Written by George A. Fitch III (aka Gaffer), gaf3@gaf3.com

# This program is free software, you can redistribute it and/or modify it under
# the same terms as Perl istelf

$Relations::Display::VERSION = '0.92';

@ISA = qw(Exporter);

@EXPORT    = ();		

@EXPORT_OK = qw();

%EXPORT_TAGS = ();

# From here on out, be strict and clean.

use strict;



### Declare some defaults for the the graph.

my %graph_defaults = (
  fgclr        => 'black', 
  accentclr    => 'white', 
  labelclr     => 'black', 
  axislabelclr => 'black', 
  legendclr    => 'black', 
  textclr      => 'black'
);



### Create a Relations::Display object. 

sub new {

  # Get the type we were sent

  my ($type) = shift;

  # Get all the arguments passed

  my ($abstract,
      $query,
      $chart,
      $width,
      $height,
      $prefix,
      $x_axis,
      $y_axis,
      $legend,
      $aggregate,
      $settings,
      $hide,
      $vertical,
      $horizontal,
      $matrix,
      $table) = rearrange(['ABSTRACT',
                           'QUERY',
                           'CHART',
                           'WIDTH',
                           'HEIGHT',
                           'PREFIX',
                           'X_AXIS',
                           'Y_AXIS',
                           'LEGEND',
                           'AGGREGATE',
                           'SETTINGS',
                           'HIDE',
                           'VERTICAL',
                           'HORIZONTAL',
                           'MATRIX',
                           'TABLE'],@_);

  # $abstract - Relations::Abstract object
  # $query - Relations::Query object to obtain the data
  # $chart - The chart type, lines, bars, etc.
  # $width - The width of the chart
  # $height - The height of the chart
  # $prefix - The auto main label prefix
  # $x_axis - Array or string of X Axis fields
  # $y_axis - Y Axis field
  # $legend - Array or string of Legend fields
  # $aggregate - Whether to aggregate the data or not.
  # $settings - Hash of settings for GD::Graph
  # $hide - Hash, array or string of fields to hide
  # $vertical - Array or string of fields to 
  #             use draw vertical lines
  # $horizontal - Array or string of fields to 
  #               use draw horizontal lines
  # $matrix - Array of hashes of the data to use
  # $table - Table object of the data to use

  # Create the hash to hold all the vars
  # for this object.

  my $self = {};

  # Bless it with the type sent (I think this
  # makes it a full fledged object)

  bless $self, $type;

  # Die if they didn't send an abstract

  die "Relations::Display requires a Relations::Abstract object!" unless defined $abstract;

  # Grab the abstract

  $self->{abstract} = $abstract;

  # If they sent a query

  if (defined $query) {

    # If the query's a hash. 

    if (ref($query) eq 'HASH') {

      # Convert it to a Relations::Query object. 

      $self->{query} = new Relations::Query($query);

    } else {

      # Assume it's a Relations::Query object and
      # clone it so we don't mess with the original. 

      $self->{query} = $query->clone();

    }

  }

  # Add the info into the hash only if it was sent,
  # making sure we clone what was sent, so the original
  # won't change.

  $self->{matrix} = to_array($matrix) if defined $matrix;
  $self->{table} = $table->clone() if defined $table;

  $self->{chart} = $chart if defined $chart;
  $self->{width} = $width if defined $width;
  $self->{height} = $height if defined $height;
  $self->{prefix} = $prefix if defined $prefix;
  $self->{x_axis} = to_array($x_axis) if defined $x_axis;
  $self->{y_axis} = $y_axis if defined $y_axis;
  $self->{legend} = to_array($legend) if defined $legend;
  $self->{aggregate} = $aggregate if defined $aggregate;
  $self->{settings} = to_hash($settings) if defined $settings;

  $self->{hide} = to_hash($hide) if defined $hide;
  $self->{vertical} = to_array($vertical) if defined $vertical;
  $self->{horizontal} = to_array($horizontal) if defined $horizontal;

  # Give thyself

  return $self;

}



### Adds info to the Display object

sub add {

  # Know thyself

  my ($self) = shift;

  # Get all the arguments passed

  my ($x_axis,
      $legend,
      $settings,
      $hide,
      $vertical,
      $horizontal) = rearrange(['X_AXIS',
                                'LEGEND',
                                'SETTINGS',
                                'HIDE',
                                'VERTICAL',
                                'HORIZONTAL'],@_);

  # $x_axis - Array or string of X Axis fields
  # $legend - Array or string of Legend fields
  # $settings - Hash of settings for GD::Graph
  # $hide - Hash, Array or string of fields to hide
  # $vertical - Array or string of fields to 
  #             use draw vertical lines.
  # $horizontal - Array or string of fields to 
  #               use draw horizontal lines.

  # Add info the object only if it was sent

  $self->{x_axis} = add_array($self->{x_axis},to_array($x_axis)) if defined $x_axis;
  $self->{legend} = add_array($self->{legend},to_array($legend)) if defined $legend;

  $self->{hide} = add_hash($self->{hide},to_hash($hide)) if defined $hide;
  $self->{vertical} = add_array($self->{vertical},to_array($vertical)) if defined $vertical;
  $self->{horizontal} = add_array($self->{horizontal},to_array($horizontal)) if defined $horizontal;

  # If they sent settings

  if (defined $settings) {

    # If we already have settings

    if ($self->{settings}) {

      # Add them to our current settings

      foreach my $name (keys %{$settings}) {

        $self->{settings}->{$name} = $settings->{$name};

      }

    # If we don't have settings

    } else {

      # Set these as our own, making a copy so the original
      # isn't messed with.

      $self->{settings} = to_hash($settings);

    }

  }

  # Give thyself

  return $self;

}



### Sets info in the Display object

sub set {

  # Know thyself

  my ($self) = shift;

  # Get all the arguments passed

  my ($abstract,
      $query,
      $chart,
      $width,
      $height,
      $prefix,
      $x_axis,
      $y_axis,
      $legend,
      $aggregate,
      $settings,
      $hide,
      $vertical,
      $horizontal,
      $matrix,
      $table) = rearrange(['ABSTRACT',
                           'QUERY',
                           'CHART',
                           'WIDTH',
                           'HEIGHT',
                           'PREFIX',
                           'X_AXIS',
                           'Y_AXIS',
                           'LEGEND',
                           'AGGREGATE',
                           'SETTINGS',
                           'HIDE',
                           'VERTICAL',
                           'HORIZONTAL',
                           'MATRIX',
                           'TABLE'],@_);

  # $abstract - Relations::Abstract object
  # $query - Relations::Query object to obtain the data
  # $chart - The chart type, lines, bars, etc.
  # $width - The width of the chart
  # $height - The height of the chart
  # $prefix - The auto main label prefix
  # $x_axis - Array or string of X Axis fields
  # $y_axis - Y Axis field
  # $legend - Array or string of Legend fields
  # $aggregate - Whether to aggregate the data or not.
  # $settings - Hash of settings for GD::Graph
  # $hide - Hash, array or string of fields to hide
  # $vertical - Array or string of fields to 
  #             use draw vertical lines
  # $horizontal - Array or string of fields to 
  #               use draw horizontal lines
  # $matrix - Array of hashes of the data to use
  # $table - Table object of the data to use

  # If they sent a query

  if (defined $query) {

    # If the query's a hash. 

    if (ref($query) eq 'HASH') {

      # Convert it to a Relations::Query object. 

      $self->{query} = new Relations::Query($query);

    } else {

      # Assume it's a Relations::Query object and
      # clone it so we don't mess with the original. 

      $self->{query} = $query->clone();

    }

  }

  # Add the info into the hash only if it was sent

  $self->{abstract} = $abstract if defined $abstract;

  $self->{matrix} = to_array($matrix) if defined $matrix;
  $self->{table} = $table->clone() if defined $table;

  $self->{chart} = $chart if defined $chart;
  $self->{width} = $width if defined $width;
  $self->{height} = $height if defined $height;
  $self->{prefix} = $prefix if defined $prefix;
  $self->{x_axis} = to_array($x_axis) if defined $x_axis;
  $self->{y_axis} = $y_axis if defined $y_axis;
  $self->{legend} = to_array($legend) if defined $legend;
  $self->{aggregate} = $aggregate if defined $aggregate;
  $self->{settings} = to_hash($settings) if defined $settings;

  $self->{hide} = to_hash($hide) if defined $hide;
  $self->{vertical} = to_array($vertical) if defined $vertical;
  $self->{horizontal} = to_array($horizontal) if defined $horizontal;

  # Give thyself

  return $self;

}



### Create a copy of this display object

sub clone {

  # Know thyself

  my ($self) = shift;

  # Return a new display object

  return new Relations::Display(-abstract     => $self->{abstract},
                                -query        => $self->{query},
                                -chart        => $self->{chart},
                                -width        => $self->{width},
                                -height       => $self->{height},
                                -prefix       => $self->{prefix},
                                -x_axis       => $self->{x_axis},
                                -y_axis       => $self->{y_axis},
                                -legend       => $self->{legend},
                                -settings     => $self->{settings},
                                -hide         => $self->{hide},
                                -vertical     => $self->{vertical},
                                -horizontal   => $self->{horizontal},
                                -matrix       => $self->{matrix},
                                -table        => $self->{table});

}



### Runs the query if it needs to and and hasn't 
### been run yet and sets and returns the matrix 
### of data.

sub get_matrix {

  # Know thyself

  my ($self) = shift;

  # Unless the matrix hasn been set already

  unless ($self->{matrix}) {

    # Return nothing if we don't have a query to use,
    # and let the user know what's up.

    return $self->{abstract}->report_error("get_matrix failed: No query object set.\n") 
      unless $self->{query};

    # Set the object's matrix to this array.

    return $self->{abstract}->report_error("get_matrix failed: Query failed.\n") 
      unless $self->{matrix} = $self->{abstract}->select_matrix(-query => $self->{query});

  }

  # Return the matrix

  return $self->{matrix};

}



### Creates a Display::Table object from
### matrix data, if it needs to, and returns
### the new object.

sub get_table {

  # Know thyself

  my ($self) = shift;

  # Unless the table has been set already

  unless ($self->{table}) {

    # Return failed unless we can get a working
    # matrix and let the user know what's up.

    return $self->{abstract}->report_error("get_table failed: get_matrix returned nothing.\n") 
      unless $self->get_matrix();

    # Return failed unless we have x_axis fields
    # or legend fields, and let the user know 
    # what's up.

    return $self->{abstract}->report_error("get_table failed: No fields in x_axis and legend.\n") 
      unless ($self->{x_axis} or $self->{legend});

    # First we have to figure out which fields 
    # have the same value for all rows and which
    # ones have different values for different 
    # rows.

    # Declare a hash to indicate the fields that
    # have different values.

    my %different = ();

    # Go through each row of the matirx

    foreach my $row (@{$self->{matrix}}) {

      # Go through each of the x axis fields

      foreach my $x_axis (@{$self->{x_axis}}) {

        # Indicate this field has more than one value
        # unless it's the same as the field in the 
        # first row.

        $different{$x_axis} = 1 unless $row->{$x_axis} eq $self->{matrix}->[0]->{$x_axis};

      }

      # Go through each of the legend fields

      foreach my $legend (@{$self->{legend}}) {

        # Indicate this field has more than one value
        # unless it's the same as the field in the 
        # first row.

        $different{$legend} = 1 unless $row->{$legend} eq $self->{matrix}->[0]->{$legend};

      }

    }

    # Now we'll go through and figure out which 
    # field names and field values go where based 
    # on whether they all have the same values or 
    # not.

    # First declare some arrays to hold all the info.

    my @title = ();        # Holds same field values
    my @x_label = ();      # Holds different x_axis field names
    my @legend_label = (); # Holds different legend field names
    my @x_axis_value = (); # Holds different x axis field value (all)
    my @legend_value = (); # Holds different legend field value (all)
    my @x_axis_title = (); # Holds different x axis field value (shown)
    my @legend_title = (); # Holds different legend field value (shown)

    # Push the prefix on the title

    push @title, $self->{prefix} if $self->{prefix};

    # Now go through the different fields for the 
    # x axis and legend, putting the field names
    # in the label and the field (future) value
    # in the value and titles. Values are what's
    # really stored and titles are what's displayed.

    # Go through each of the x axis fields

    foreach my $x_axis (@{$self->{x_axis}}) {

      # Unless this field has different values

      unless ($different{$x_axis}) {

        # Make it part of the title unless it's to 
        # be hidden.

        push @title,$self->{matrix}->[0]->{$x_axis} unless $self->{hide}->{$x_axis};

      # This field has different values.

      } else {

        # Add what will be the field value (through
        # an eval string) to its array.

        push @x_axis_value,"\$row->{'$x_axis'}";

        # Unless the field's to be hidden.

        unless ($self->{hide}->{$x_axis}) {

          # Add what will be the field value (through
          # an eval string) to its array, and the field's
          # name to the x axis label.

          push @x_axis_title,"\$row->{'$x_axis'}";
          push @x_label,$x_axis;

        }

      }

    }

    # Go through each of the legend fields

    foreach my $legend (@{$self->{legend}}) {

      # Unless this field has different values

      unless ($different{$legend}) {

        # Make it part of the title unless it's to 
        # be hidden.

        push @title,$self->{matrix}->[0]->{$legend} unless $self->{hide}->{$legend};

      # This field has different values.

      } else {

        # Add what will be the field value (through
        # an eval string) to its array.

        push @legend_value,"\$row->{'$legend'}";

        # Unless the field's to be hidden.

        unless ($self->{hide}->{$legend}) {

          # Add what will be the field value (through
          # an eval string) to its array, and the field's
          # name to the legend label.

          push @legend_title,"\$row->{'$legend'}";
          push @legend_label,$legend;

        }

      }

    }

    # Create the labels from the arrays.

    my $title = join ' - ',@title;
    my $x_label = join ' - ',@x_label;
    my $y_label = $self->{y_axis};
    my $legend_label = join ' - ',@legend_label;

    # Create the eval strings from the arrays.

    my $x_axis_value_eval = '$x_axis_value = "' . (join ' - ',@x_axis_value) . '";';
    my $legend_value_eval = '$legend_value = "' . (join ' - ',@legend_value) . '";';
    my $x_axis_title_eval = '$x_axis_title = "' . (join ' - ',@x_axis_title) . '";';
    my $legend_title_eval = '$legend_title = "' . (join ' - ',@legend_title) . '";';

    # The titles are set, so now we have to figure
    # the different x axis values and titles and 
    # the different legend values and titles. We'll
    # go through the entire matrix using the eval
    # strings to determine the different x axis and
    # legend values for each row. We'll also figure
    # out which legend values will need lines drawn.

    # Let's declare some structures to hold 
    # everything.

    my $x_axis_value;
    my $legend_value;
    my $x_axis_title;
    my $legend_title;
    my %seen_x_axis = ();
    my %seen_legend = ();
    my @x_axis_values = ();
    my @legend_values = ();
    my $y_axis_values = ();
    my %x_axis_titles = ();
    my %legend_titles = ();
    my %vertical_lines = ();
    my %horizontal_lines = ();

    # We're goin to need a hash to hold all the 
    # fields that are in the legend so we can
    # make sure the lines we're drawing will have
    # the right color.

    my %in_legend = %{to_hash($self->{legend})};
    
    # Go through all the rows in the matrix.

    foreach my $row (@{$self->{matrix}}) {

      # Eval each of the eval strings

      eval $x_axis_value_eval;
      eval $legend_value_eval;
      eval $x_axis_title_eval;
      eval $legend_title_eval;

      # Unless we've seen this x axis 
      # value before.

      unless ($seen_x_axis{$x_axis_value}) {

        # Add this x axis value to the 
        # array and this x axis title
        # to the hash.

        push @x_axis_values,$x_axis_value;
        $x_axis_titles{$x_axis_value} = $x_axis_title;

        # We've seen this x axis 
        # value.

        $seen_x_axis{$x_axis_value} = 1;

      }

      # Unless we've seen this legend 
      # value before.

      unless ($seen_legend{$legend_value}) {

        # Add this legend value to the 
        # array and this legend title
        # to the hash.

        push @legend_values,$legend_value;
        $legend_titles{$legend_value} = $legend_title;

        # Go through the vertical lines
        # array, adding those fields'
        # values to the veritcal lines 
        # hash if they're part of the 
        # legend fields.

        foreach my $vertical (@{$self->{vertical}}) {

          $vertical_lines{scalar @legend_values} = $row->{$vertical}
            if $in_legend{$vertical};

        }

        # Save these vertical lines

        $self->{vertical_lines} = \%vertical_lines;

        # Go through the horizontal lines
        # array, adding those fields'
        # values to the veritcal lines 
        # hash if they're part of the 
        # legend fields.

        foreach my $horizontal (@{$self->{horizontal}}) {

          $horizontal_lines{scalar @legend_values} = $row->{$horizontal}
            if $in_legend{$horizontal};

        }    

        # Save these horizontal lines

        $self->{horizontal_lines} = \%horizontal_lines;

        # We've know seen this legend 
        # value.

        $seen_legend{$legend_value} = 1;

      }

      # Unless we're aggregating the data, which would be 
      # used by the GD::Graph::boxplot module.

      unless ($self->{aggregate}) {

        # If this point's already set, then we're
        # overwriting another value. Let the user
        # know what's up.

        $self->{abstract}->report_error("Over writing points for x axis: $x_axis_value legend: $legend_value!\n") 
          if defined $y_axis_values->{$x_axis_value}{$legend_value};

        # Set the data point for this value.

        $y_axis_values->{$x_axis_value}{$legend_value} = $row->{$self->{y_axis}};

      # We're doing a boxplot

      } else {

        # Create an empty array at this point 
        # unless it's already set.

        $y_axis_values->{$x_axis_value}{$legend_value} = to_array()
          unless $y_axis_values->{$x_axis_value}{$legend_value};

        # Add this data point to the array 

        push @{$y_axis_values->{$x_axis_value}{$legend_value}}, $row->{$self->{y_axis}};

      }

    }

    # Override the default labels with the user
    # specified ones.

    $title = $self->{settings}->{title} if $self->{settings}->{title};
    $x_label = $self->{settings}->{x_label} if $self->{settings}->{x_label};
    $y_label = $self->{settings}->{y_label} if $self->{settings}->{y_label};
    $legend_label = $self->{settings}->{legend_label} if $self->{settings}->{legend_label};

    # Create a table object created from all 
    # this good stuff.

    $self->{table} =  new Relations::Display::Table(-title         => $title,
                                                    -x_label       => $x_label,
                                                    -y_label       => $y_label,
                                                    -legend_label  => $legend_label,
                                                    -x_axis_values => \@x_axis_values,
                                                    -legend_values => \@legend_values,
                                                    -x_axis_titles => \%x_axis_titles,
                                                    -legend_titles => \%legend_titles,
                                                    -y_axis_values => $y_axis_values);

  }

  # Return the table

  return $self->{table};

}



### Creates a GD::Graph object from the 
### Display::Table object if it has to, and
### returns the new object.

sub get_graph {

  # Know thyself

  my $self = shift;

  # Unless the graph is already
  # created

  unless ($self->{graph}) {

    # Return nothing unless we can get a 
    # working table.

    return $self->{abstract}->report_error("get_graph failed: get_table failed.\n") 
     unless $self->get_table();

    # Return error if the chart isn't set.

    return $self->{abstract}->report_error("get_graph failed: chart not set.\n") 
      unless $self->{chart};

    # Return error if the width isn't set.

    return $self->{abstract}->report_error("get_graph failed: width not set.\n") 
      unless $self->{width};

    # Return error if the  height isn't set.

    return $self->{abstract}->report_error("get_graph failed: height not set.\n") 
      unless $self->{height};

    # Create the graph using the data sent 
    # and the library provided with the 
    # graph.

    my $graph;

    eval "use GD::Graph::$self->{chart};";
    eval "\$graph = new GD::Graph::$self->{chart}($self->{width},$self->{height});";

    # Set the defaults from us.

    foreach my $option (keys %graph_defaults) {

      $graph->set($option => $graph_defaults{$option});

    }

    # Set the defaults for the labels.

    $graph->set(title => $self->{table}->{title});
    $graph->set(x_label => $self->{table}->{x_label});
    $graph->set(y_label => $self->{table}->{y_label});

    # Set the settings from the user.

    foreach my $option (keys %{$self->{settings}}) {

      $graph->set($option => $self->{settings}->{$option});

    }

    # Now let's build the data structures
    # from our Display::Table object.

    # Create the big whompum data array.

    my @data = ();

    # Push the x axis titles into the first
    # slot of the data array.

    my @x_axis_titles = ();

    foreach my $x_axis_value (@{$self->{table}->{x_axis_values}}) {

      push @x_axis_titles, $self->{table}->{x_axis_titles}->{$x_axis_value};

    }

    push @data,[@x_axis_titles];

    # Set the legend titles as well.

    my @legend_titles = ();

    foreach my $legend_value (@{$self->{table}->{legend_values}}) {

      push @legend_titles, $self->{table}->{legend_titles}->{$legend_value};

    }

    $graph->set_legend(@legend_titles) if (@legend_titles > 1) or ($legend_titles[0]);

    # Go through all the table data, pushing 
    # it into the data array.

    foreach my $legend_value (@{$self->{table}->{legend_values}}) {

      # Declare an array to hold all the y
      # values.

      my @y_values = ();

      foreach my $x_axis_value (@{$self->{table}->{x_axis_values}}) {

        # Push this data point onto the y
        # values.

        push @y_values,$self->{table}->{y_axis_values}->{$x_axis_value}{$legend_value};

      }

      # Push these y values onto the data 
      # array.

      push @data,[@y_values];

    }

    # Ok, settings is set, data's fit, legend sent. 
    # Let's plot the data. Return error if we 
    # can't plot the data.

    return $self->{abstract}->report_error("get_graph failed: GD::Graph plot failed.\n") 
      unless $graph->plot(\@data);

    # Last up, the vertical and horizontal 
    # lines. 

    if ($self->{vertical} || $self->{horizontal}) {

      # Grab all the specs of the graph now into
      # small variables so the equations made
      # won't be so huge.
     
      my $r = $graph->{right};
      my $b = $graph->{bottom};
      my $l = $graph->{left};
      my $t = $graph->{top};
      my $h = $b - $t;
      my $w = $r - $l;

      # Vertical: we have to create a hash of 
      # points on which to draw a line. This is 
      # because some lines might be drawn on the 
      # same point, and would overwrite each other. 
      # So we'll make an array for each vertical 
      # space on which one or more lines will be 
      # drawn, in a hash keyed by the point on 
      # which the lines will be drawn.

      my %vertical_points = ();

      # Go through all the keys in the vertical lines 
      # hash. Each key is the data colour number for
      # the legend entry this lines was created under.

      foreach my $vertical_line (keys %{$self->{vertical_lines}}) {

        # Get the x,y values for the line

        my ($x,$y) = $graph->val_to_pixel($self->{vertical_lines}->{$vertical_line},0);

        # Push this legend value onto the array 
        # at the x point.

        push @{$vertical_points{$x}}, $vertical_line;

      }

      # Go through all the vertical points 

      foreach my $x (keys %vertical_points) {

        # Go through all the legend numbers for this 
        # point.

        for (my $i = 0; $i < @{$vertical_points{$x}}; $i++) {

          # Pick a data colour from legend number

          my $c = $graph->set_clr($graph->pick_data_clr($vertical_points{$x}->[$i]));

          # Make three dashes of patterns

          my $d = 3;

          for (my $j = 0; $j < $d; $j++) {

            # Dash the line between colors 

            my $s = $t + $j * $h / $d + $i * ($h) / ($d * (scalar @{$vertical_points{$x}}));
            my $e = $t + $j * $h / $d + ($i + 1) * ($h) / ($d * (scalar @{$vertical_points{$x}}));

            # Draw the vertical line

            $graph->{graph}->line($x, $s, $x, $e, $c);

          }

        }

      }

      # Horizontal: we have to create a hash of 
      # points on which to draw a line. This is 
      # because some lines might be drawn on the 
      # same point, and would overwrite each other. 
      # So we'll make an array for each horizontal 
      # space on which one or more lines will be 
      # drawn, in a hash keyed by the point on 
      # which the lines will be drawn.

      my %horizontal_points = ();

      # Go through all the keys in the horizontal lines 
      # hash. Each key is the data colour number for
      # the legend entry this lines was created under.

      foreach my $horizontal_line (keys %{$self->{horizontal_lines}}) {

        # Get the x,y values for the line

        my ($x,$y) = $graph->val_to_pixel(0,$self->{horizontal_lines}->{$horizontal_line});

        # Push this legend value onto the array 
        # at the x point.

        push @{$horizontal_points{$y}}, $horizontal_line;

      }

      # Go through all the horizontal points 

      foreach my $y (keys %horizontal_points) {

        # Go through all the legend numbers for this 
        # point.

        for (my $i = 0; $i < @{$horizontal_points{$y}}; $i++) {

          # Pick a data colour from legend number

          my $c = $graph->set_clr($graph->pick_data_clr($horizontal_points{$y}->[$i]));

          # Make four dashes of patterns

          my $d = 4;

          for (my $j = 0; $j < $d; $j++) {

            # Dash the line between colors 

            my $s = $l + $j * $w / $d + $i * ($w) / ($d * (scalar @{$horizontal_points{$y}}));
            my $e = $l + $j * $w / $d + ($i + 1) * ($w) / ($d * (scalar @{$horizontal_points{$y}}));

            # Draw the horizontal line

            $graph->{graph}->line($s, $y, $e, $y, $c);

          }

        }

      }

    }

    # Overwrite the graph image with our 
    # modified one.

    $self->{graph} = $graph;

  }

  # Return the graph object.

  return $self->{graph};

}

$Relations::Display::VERSION;

__END__

=head1 NAME

Relations::Display - DBI/DBD::mysql Query Graphing Module

=head1 SYNOPSIS

  # DBI, Relations::Display Script that creates a 
  # matrix, table, and graph from a query. 

  use DBI;
  use Relations;
  use Relations::Query;
  use Relations::Abstract;
  use Relations::Display;

  $dsn = "DBI:mysql:watcher";

  $username = "root";
  $password = '';

  $dbh = DBI->connect($dsn,$username,$password,{PrintError => 1, RaiseError => 0});

  $abstract = new Relations::Abstract($dbh);

  $display = new Relations::Display(-abstract   => $abstract,
                                    -query      => {-select   => {total  => "count(*)",
                                                                  first  => "'Bird'",
                                                                  second => "'Count'",
                                                                  third  => "if(gender='Male','Boy','Girl')",
                                                                  tao    => "if(gender='Male','Yang','Yin')",
                                                                  sex    => "gender",
                                                                  kind   => "sp_name",
                                                                  id     => "species.sp_id",
                                                                  fourth => "(species.sp_id+50)",
                                                                  vert   => "2",
                                                                  horiz  => "1.5"},
                                                    -from     => ['bird','species'],
                                                    -where    => ['species.sp_id=bird.sp_id',
                                                                  'species.sp_id < 4'],
                                                    -group_by => ['sp_name','gender','first','second'],
                                                    -order_by => ['gender','sp_name']},
                                    -x_axis     => 'first,kind,id,fourth',
                                    -legend     => 'second,third,tao,sex,vert,horiz',
                                    -y_axis     => 'total',
                                    -hide       => 'fourth,third,vert,horiz',
                                    -vertical   => 'vert',
                                    -horizontal => 'horiz');

  $matrix = $display->get_matrix();

  $table = $display->get_table();

  $display->set(-chart  => 'bars',
                -width  => 400,
                -height => 400,
                -settings => {y_min_value => 0,
                              y_max_value => 3,
                              y_tick_number => 3,
                              transparent => 0}
                );

  $gph = $display->get_graph();

  $gd = $gph->gd();

  open(IMG, '>test.png') or die $!;
  binmode IMG;
  print IMG $gd->png;

  $dbh->disconnect();

=head1 ABSTRACT

This perl library uses perl5 objects to simplify creating graphs
from MySQL queries. 

The current version of Relations::Display is available at

  http://relations.sourceforge.net

=head1 DESCRIPTION

=head2 WHAT IT DOES

The Relations::Display object takes in your query, along with information 
pertaining to which field values from the query results are to be used in 
creating the graph title, x axis label and titles, legend label (not used 
on the graph) and titles, and y axis data. 

It does this by looping through the query while taking into account which 
fields you want to use for the x axis and legend. While looping, it 
figures out which of these fields have all the same value throughout the 
query and which have different values. The fields with the same value 
throughout the query results have their value placed in the title of the 
graph, while the fields with different values throughout have their 
value placed in either the x axis or legend, which is set by the user.

Relations::Display can return either the raw query results in the form of 
a Relations select_matrix() return value, a Relations::Display::Table 
object, or a GD::Graph object. It obtains this data in stages. 
Relations::Display gets its matrix data from the query object, the 
Relations::Display::Table data from the matrix data, and the GD::Graph 
data from the Relations::Display::Table data.

=head2 CALLING RELATIONS::DISPLAY ROUTINES

All standard Relations::Display routines use both an ordered, named and
hashed argument calling style. This is because some routines have as many 
as fifteen arguments, and the code is easier to understand given a named 
argument style, but since some people, however, prefer the ordered 
argument style because its smaller, I'm glad to do that too. 

If you use the ordered argument calling style, such as

  $display->add('Book,ISBN','Publisher,Category,Discount',{interlaced => 0},'ISBN');

the order matters, and you should consult the function defintions 
later in this document to determine the order to use.

If you use the named argument calling style, such as

  $display->add(-x_axis   => 'Book,ISBN',
                -legend   => 'Publisher,Category,Discount',
                -settings => {interlaced => 0},
                -hide     => 'ISBN');

the order does not matter, but the names, and minus signs preceeding them, do.
You should consult the function defintions later in this document to determine 
the names to use.

In the named arugment style, each argument name is preceded by a dash.  
Neither case nor order matters in the argument list.  -name, -Name, and 
-NAME are all acceptable.  In fact, only the first argument needs to begin with 
a dash.  If a dash is present in the first argument, Relations::Display assumes
dashes for the subsequent ones.

If you use the hashed argument calling style, such as

  $display->add({x_axis   => 'Book,ISBN',
                 legend   => 'Publisher,Category,Discount',
                 settings => {interlaced => 0},
                 hide     => 'ISBN'});

or

  $display->add({-x_axis   => 'Book,ISBN',
                 -legend   => 'Publisher,Category,Discount',
                 -settings => {interlaced => 0},
                 -hide     => 'ISBN'});

the order does not matter, but the names, and curly braces do, (minus signs are
optional). You should consult the function defintions later in this document to 
determine the names to use.

In the hashed arugment style, no dashes are needed, but they won't cause problems
if you put them in. Neither case nor order matters in the argument list. 
settings, Settings, SETTINGS are all acceptable. If a hash is the first 
argument, Relations::Display assumes that is the only argument that matters, and 
ignores any other arguments after the {}'s.

=head2 QUERY ARGUMENTS

Some of the Relations functions recognize an argument named query. This
argument can either be a hash or a Relations::Query object. 

The following calls are all equivalent for $object->function($query).

  $object->function({select => 'nothing',
                     from   => 'void'});

  $object->function(Relations::Query->new(-select => 'nothing',
                                          -from   => 'void'));

=head1 LIST OF RELATIONS::DISPLAY FUNCTIONS

An example of each function is provided in 'test.pl'.

=head2 new

  $display = new Relations::Display($abstract,
                                    $query,
                                    $chart,
                                    $width,
                                    $height,
                                    $prefix,
                                    $x_axis,
                                    $y_axis,
                                    $legend,
                                    $aggregate,
                                    $settings,
                                    $hide,
                                    $vertical,
                                    $horizontal,
                                    $matrix,
                                    $table);

  $display = new Relations::Display(-abstract   => $abstract,
                                    -query      => $query,
                                    -chart      => $chart,
                                    -width      => $width,
                                    -height     => $height,
                                    -prefix     => $prefix,
                                    -x_axis     => $x_axis,
                                    -y_axis     => $y_axis,
                                    -legend     => $legend,
                                    -aggregate  => $aggregate,
                                    -settings   => $settings,
                                    -hide       => $hide,
                                    -vertical   => $vertical,
                                    -horizontal => $horizontal,
                                    -matrix     => $matrix,
                                    -table      => $table);

Creates creates a new Relations::Display object.

B<$abstract> - 
The Relations::Abstract object to use. This must be sent because 
Relations::Display uses the $abstract object to report errors. 
If this is not sent, the program will die.

B<$query> - 
The Relations::Query object to run to get the display data. This 
is unneccesary if you supply a $matrix or $table value. 

B<$chart>, B<$width> and B<$height> - 
The GD::Graph chart type to use, and the width and height
of the GD::Graph. All three of these must be set. There are no
defaults.

B<$prefix> - 
The prefix to put before the auto generated label. 

B<$x_axis> and B<$legend> - 
The fields to use for the x axis and legend values. Can be 
either a comma delimmitted string, or an array. The names
sent must exactly match the field names in the query.

B<$y_axis> and B<$aggregate>- 
The field to use for the y axis values of the graph and how those
values are to be stored. If you using a GD:Graph module that 
requires aggregate data, like boxplot, then set $aggregate to 1.
Else, forget about it.

B<$settings> - 
GD::Graph settings to set on the graph object. Must be a
hash of settings to set keyed by the setting name. Use this 
to set the title, x_label, y_label, and legend_label (table 
only) of the Relations::Display::Table and GD::Graph.

B<$hide> - 
The fields to use for the x axis and legend values but to 
hide on the actual display. Can be either a comma delimmitted 
string, an array, or a hash with true values keyed by the 
field names. The names sent must exactly match the field names 
in the query.

B<$vertical> and B<$horizontal> - 
The fields to use for drawing vertical and horizontal lines on 
the graph. These fields must also be in the legend settings, 
since the color of the lines drawn on the graph will be the color 
of the legend thay are connected to. If the x axis min and max 
is not set, the vertical lines values indicate on which x axis 
titles to drawn lines on (fractions work I think), ie 0=first x 
axis title, 1-scound, etc. If the x axis min and max is set, the 
vertical lines values indicate the numeric graph value on which 
to drawn lines. 

B<$matrix> - 
Matrix value to use to create the Relations::Display::Table object value
and or GD::Graph value. Uneccessary if is you supply a table 
argument.

B<$table> - 
Relations::Display::Table value to use to create the GD::Graph object. 

=head2 add

  $display->add($x_axis,
                $legend,
                $settings,
                $hide,
                $vertical,
                $horizontal);

  $display->add(-x_axis     => $x_axis,
                -legend     => $legend,
                -settings   => $settings,
                -hide       => $hide,
                -vertical   => $vertical,
                -horizontal => $horizontal);

Adds additional settings to a Relations::Display object. It does not 
override of the values already set.

B<$x_axis> and B<$legend> - 
The fields to use for the x axis and legend values. Can be 
either a comma delimmitted string, or an array. The names
sent must exactly match the field names in the query.

B<$settings> - 
GD::Graph settings to set on the graph object. Must be a
hash of settings to set keyed by the setting name. Use this 
to set the title, x_label, y_label, and legend_label (table 
only) of the Relations::Display::Table and GD::Graph.

B<$hide> - 
The fields to use for the x axis and legend values but to 
hide on the actual display. Can be either a comma delimmitted 
string, an array, or a hash with true values keyed by the 
field names. The names sent must exactly match the field names 
in the query.

B<$vertical> and B<$horizontal> - 
The fields to use for drawing vertical and horizontal lines on 
the graph. These fields must also be in the legend settings, 
since the color of the lines drawn on the graph will be the color 
of the legend thay are connected to. If the x axis min and max 
is not set, the vertical lines values indicate on which x axis 
titles to drawn lines on (fractions work I think), ie 0=first x 
axis title, 1-scound, etc. If the x axis min and max is set, the 
vertical lines values indicate the numeric graph value on which 
to drawn lines. 

=head2 set

  $display->set($abstract,
                $query,
                $chart,
                $width,
                $height,
                $prefix,
                $x_axis,
                $y_axis,
                $legend,
                $aggregate,
                $settings,
                $hide,
                $vertical,
                $horizontal,
                $matrix,
                $table);

  $display->set(-abstract   => $abstract,
                -query      => $query,
                -chart      => $chart,
                -width      => $width,
                -height     => $height,
                -prefix     => $prefix,
                -x_axis     => $x_axis,
                -y_axis     => $y_axis,
                -legend     => $legend,
                -aggregate  => $aggregate,
                -settings   => $settings,
                -hide       => $hide,
                -vertical   => $vertical,
                -horizontal => $horizontal,
                -matrix     => $matrix,
                -table      => $table);

Overrides any current setttings of the Relations::Display
object. It does not add to any of the values.

B<$abstract> - 
The Relations::Abstract object to use. 

B<$query> - 
The Relations::Query object to run to get the display data. This 
is unneccesary if you supply a $matrix or $table value. 

B<$chart>, B<$width> and B<$height> - 
The GD::Graph chart type to use, and the width and height
of the GD::Graph. All three of these must be set. There are no
defaults.

B<$prefix> - 
The prefix to put before the auto generated label. 

B<$x_axis> and B<$legend> - 
The fields to use for the x axis and legend values. Can be 
either a comma delimmitted string, or an array. The names
sent must exactly match the field names in the query.

B<$y_axis> and B<$aggregate>- 
The field to use for the y axis values of the graph and how those
values are to be stored. If you using a GD:Graph module that 
requires aggregate data, like boxplot, then set $aggregate to 1.
Else, forget about it.

B<$settings> - 
GD::Graph settings to set on the graph object. Must be a
hash of settings to set keyed by the setting name. Use this 
to set the title, x_label, y_label, and legend_label (table 
only) of the Relations::Display::Table and GD::Graph.

B<$hide> - 
The fields to use for the x axis and legend values but to 
hide on the actual display. Can be either a comma delimmitted 
string, an array, or a hash with true values keyed by the 
field names. The names sent must exactly match the field names 
in the query.

B<$vertical> and B<$horizontal> - 
The fields to use for drawing vertical and horizontal lines on 
the graph. These fields must also be in the legend settings, 
since the color of the lines drawn on the graph will be the color 
of the legend thay are connected to. If the x axis min and max 
is not set, the vertical lines values indicate on which x axis 
titles to drawn lines on (fractions work I think), ie 0=first x 
axis title, 1-scound, etc. If the x axis min and max is set, the 
vertical lines values indicate the numeric graph value on which 
to drawn lines. 

B<$matrix> - 
Matrix value to use to create the Relations::Display::Table object value
and or GD::Graph value. Uneccessary if is you supply a table 
argument.

B<$table> - 
Relations::Display::Table value to use to create the GD::Graph object. 

=head2 clone

  $clone = $display->clone();

Creates a copy of a Relations::Display object and returns it.

=head2 get_matrix

  $matrix = $display->get_matrix();

Returns the matrix value for a Relations::Display object. If the
matrix value is already set in the display object, it returns that. 
If the matrix value is not set, it attempts to run the query 
with the abstract. If successful, it returns a matrix created from the 
query, and set the matrix value for the display object. If that fails, 
it returns nothing and calls the Relations::Abstract object's
report_error() function. So, if you create the display object with only 
$table set, this function will fail because neither the query nor 
matrix value will be set.

=head2 get_table

  $table = $display->get_table();

Returns the Relations::Display::Table value for a Relations::Display 
object. If the table value is already set in the display object, it 
returns that. If the table value is not set, it calls its own 
get_matrix, and tries to create the table from the returned matrix. 
It'll return the new table object if successful. If that fails, it 
returns nothing and calls the Relations::Abstract object's 
report_error() function.

=head2 get_graph

  $graph = $display->get_graph();

Returns the graph value for Relations::Display object. If the
graph value is already set in the display object, it returns that. 
If the graph value is not set, it calls its own get_table, and
tries to create the graph from the returned table. It'll return 
the new graph object if successful. If that fails, it returns nothing 
and calls the Relations::Abstract object's report_error() function.

=head1 LIST OF RELATIONS::DISPLAY PROPERTIES

B<abstract> - 
The Relations::Abstract object

B<query> - 
The Relations::Query object

B<chart> - 
The name of the GD::Graph module

B<width> - 
The width of the GD::Graph in pixels

B<height> - 
The width of the GD::Graph in pixels

B<prefix> - 
The prefix put before the autogenerated title

B<x_axis> - 
Array ref of all the x axis fields 

B<y_axis> - 
The y axis field

B<legend> - 
Array ref of all the legend fields 

B<aggregate> - 
Whether to store the data in aggregate format. 

B<settings> - 
Hash of settings to send to the GD:Graph object, keyed on 
each property's name.

B<hide> - 
Hash ref of all the fields to hide. Keyed by field name, 
with a value of 1.

B<vertical> - 
Array ref of all the vertical line fields. Display will
drawn a vertical line on the graph for value of these fields.

B<horizontal> - 
Array ref of all the horizontal line fields. Display will
drawn a horizontal line on the graph for value of these fields.

B<matrix> - 
The matrix object. This is returned from the Relations::Abstract's
select_matrix() function. Array ref of rows of data, which are
hash ref keyed by field name.

B<table> - 
The table object. See Relations::Display::Table for more info.

=head1 LIST OF RELATIONS::DISPLAY::TABLE FUNCTIONS

An example of each function is provided in either 'test.pl' and 'demo.pl'.

=head2 new

  $table = new Relations::Display::Table($title,
                                         $x_label,
                                         $y_label,
                                         $legend_label,
                                         $x_axis_values,
                                         $legend_values,
                                         $x_axis_titles,
                                         $legend_titles,
                                         $y_axis_values);

  $table = new Relations::Display::Table(-title         => $title,
                                         -x_label       => $x_label,
                                         -y_label       => $y_label,
                                         -legend_label  => $legend_label,
                                         -x_axis_values => $x_axis_values,
                                         -legend_values => $legend_values,
                                         -x_axis_titles => $x_axis_titles,
                                         -legend_titles => $legend_titles,
                                         -y_axis_values => $y_axis_values);

Creates creates a new Relations::Display::Table object.

B<$title> - 
The main label for the table. String.

B<$x_label>, B<$y_label> and B<$legend_label> - 
The labels to use for x axis, y axis and legend. Strings.

B<$x_axis_values> and B<$legend_values> - 
The values for the x axis and legend. Array refs.

B<$x_axis_titles> and B<$legend_titles> - 
The titles (what's to be displayed) for the x axis and legend. 
Used if there are fields to be hidden. Hash refs keyed
by values arrays.

B<$y_axis_values> - 
The y axis data for the table. 2D hash ref keyed off the x axis and
legend arrays in that order.

=head1 LIST OF RELATIONS::DISPLAY::TABLE PROPERTIES

B<title> - 
The title.

B<x_label> - 
The x axis label.

B<y_label> - 
The y axis label.

B<legend_label> - 
The legend label.

B<x_axis_values> - 
Array ref of actual x_axis values to key the 
y_axis_values with. 

B<legend_values> - 
Array ref of actual legend values to key the 
y_axis_values with. 

B<x_axis_titles> - 
Hash ref of displayed x_axis values. What's left
after the fields specified by hide are removed.
Keyed by the the x axis values.
$table->{x_axis_titles}->{$x_axis_value}

B<legend_titles> - 
Hash ref of displayed legend values. What's left
after the fields specified by hide are removed.
Keyed by the the legend values.
$table->{legend_titles}->{$legend_value}

B<y_axis_values> - 
Hash ref of displayed legend values. What's left
Teh data of the table. A hash ref of data keyed 
by the x_axis and legend values in that order. 
$table->{y_axis_values}->{$x_axis_value}{$legend_value}

=head1 CHANGE LOG

=head2 Relations-Display-0.92

B<Fixed X Axis and Legend Evals>

Fixed a problem with x axis and legend field values. Any field
names that contained spaces would have their values show up as 
blank in the Graph and Table. That's fixed now.

=head2 Relations-Display-0.91

B<Added Argument Cloning>

Instead of just grabbing sent array refs, hash refs, queries and such,
Relations::Display now makes complete copies of all these objects. 
This was done because Relations::Report was messing up the Display's 
settings when it passed them to Report.

B<Added Object Cloning>

Both Relations::Display and Relations::Display::Table now have clone()
functions to create copies of themselves. This will be very useful for
Relations::Report's iterate functionality.

B<Arguments and Properties Renamed>

Many of the argument and property names were changed to be more 
consistent with GD::Graph. This may be annoying to deal with, but 
better to do it now rather than later.

=head1 TO DO

B<Improve Error Checking>

Add some warnings if fields specified in various arguments are not
present in the matrix data returned from the query. 
B<Add To Text Functionality>

Add a to_text() function to both Relations::Display and 
Relations::Display::Table. This will make it easier to debug.

B<Pass -w>

Clean up the code so it pass 'perl -w'. I completely forgot about 
making sure everything did that. 

=head1 OTHER RELATED WORK

=head2 Relations (Perl)

Contains functions for dealing with databases. It's mainly used as 
the foundation for the other Relations modules. It may be useful for 
people that deal with databases as well.

=head2 Relations-Query (Perl)

An object oriented form of a SQL select query. Takes hashes.
arrays, or strings for different clauses (select,where,limit)
and creates a string for each clause. Also allows users to add to
existing clauses. Returns a string which can then be sent to a 
database. 

=head2 Relations-Abstract (Perl)

Meant to save development time and code space. It takes the most common 
(in my experience) collection of calls to a MySQL database, and changes 
them to one liner calls to an object.

=head2 Relations-Admin (PHP)

Some generalized objects for creating Web interfaces to relational 
databases. Allows users to insert, select, update, and delete records from 
different tables. It has functionality to use tables as lookup values 
for records in other tables.

=head2 Relations-Family (Perl)

Query engine for relational databases.  It queries members from 
any table in a relational database using members selected from any 
other tables in the relational database. This is especially useful with 
complex databases: databases with many tables and many connections 
between tables.

=head2 Relations-Display (Perl)

Module creating graphs from database queries. It takes in a query through a 
Relations-Query object, along with information pertaining to which field 
values from the query results are to be used in creating the graph title, 
x axis label and titles, legend label (not used on the graph) and titles, 
and y axis data. Returns a graph and/or table built from from the query.

=head2 Relations-Report (Perl)

A Web interface for Relations-Family, Reations-Query, and Relations-Display. 
It creates complex (too complex?) web pages for selecting from the different 
tables in a Relations-Family object. It also has controls for specifying the 
grouping and ordering of data with a Relations-Query object, which is also 
based on selections in the Relations-Family object. That Relations-Query can 
then be passed to a Relations-Display object, and a graph and/or table will 
be displayed.

=head2 Relations-Structure (XML)

An XML standard for Relations configuration data. With future goals being 
implmentations of Relations in different languages (current targets are 
Perl, PHP and Java), there should be some way of sharing configuration data
so that one can switch application languages seamlessly. That's the goal
of Relations-Structure A standard so that Relations objects can 
export/import their configuration through XML. 

=cut