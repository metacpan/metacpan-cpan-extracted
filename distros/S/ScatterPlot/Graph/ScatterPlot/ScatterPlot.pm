package ScatterPlot;

#use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SCatterPlot ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# constructor
sub new {
    # declare the class name and assign it the input parameter
    my ($class_name) = @_;

    # create the new variable, its a hash
    my ($self) = [];

    # bless it to be an object within class $class_name
    bless ($self, $class_name);

    # return the hash and exit
    return $self;
}


# draw an ASCII plot
sub draw {
    # declare local copy of self and sport, assigning with input paramters
    my ($self, $xy_points, $x_size, $y_size, $x_label, $y_label, $char, $type) = @_;

    # default variables
    unless ($type) {
        $type = 'text';
    }
    unless ($char) {
        $char = 'o';
    }
    unless ($y_label) {
        $y_label = '';
    }
    unless ($x_label) {
        $x_label = '';
    }
    unless ($y_size) {
        $y_size = 26;
    } else {
        $y_size--;
    }
    unless ($x_size) {
        $x_size = 60;
    }
    unless ($xy_points) {
        my @xy_points = ();
        my $i_max = 20;
        for (my $i=0; $i<$i_max; $i++) {
            $xy_points[$i][0] = ($i - ($i_max - 1) / 2 ) * 6 / $i_max;
            $xy_points[$i][1] = ($xy_points[$i][0] + 2) * ($xy_points[$i][0] - 2) * $xy_points[$i][0];
        }
        $xy_points = \@xy_points;
    }



    # find the number of points to plot
    my $num_points = @$xy_points;

    # loop thru the points and find min/max values
    my $i = 0;
    my $x_min;
    my $x_max;
    my $y_min;
    my $y_max;
    while ((!$x_min or !$y_min) and ($i < $num_points)) {
        $x_min = $$xy_points[$i][0];
        $x_max = $$xy_points[$i][0];
        $y_min = $$xy_points[$i][1];
        $y_max = $$xy_points[$i][1];
        $i++;
    }
    for (my $j=$i; $j<$num_points; $j++) {
        if ($$xy_points[$j][0] and $$xy_points[$j][1]) {
            if ($$xy_points[$j][0] < $x_min) {
                $x_min = $$xy_points[$j][0];
            }
            if ($$xy_points[$j][0] > $x_max) {
                $x_max = $$xy_points[$j][0];
            }
            if ($$xy_points[$j][1] < $y_min) {
                $y_min = $$xy_points[$j][1];
            }
            if ($$xy_points[$j][1] > $y_max) {
                $y_max = $$xy_points[$j][1];
            }
        }
    }

    # calculate the scale and offset values
    my $x_scale = 0;
    if ($x_max - $x_min != 0) {
        $x_scale = $x_size / ($x_max - $x_min);
    }
    my $x_offset = -$x_min;
    my $y_scale = 0;
    if ($y_max - $y_min != 0) {
        $y_scale = $y_size / ($y_max - $y_min);
    }
    my $y_offset = -$y_min;

    # clear the graph
    for (my $x=0; $x<$x_size; $x++) {
        for (my $y=0; $y<=$y_size; $y++) {
            $$self[$x][$y] = ' ';
        }
    }

    # draw the axes
    my $x_axis = int($x_scale * $x_offset);
    my $y_axis = int($y_scale * $y_offset);
    if (($y_axis >= 0) and ($y_axis < $y_size)) {
        for (my $x=0; $x<$x_size; $x++) {
            $$self[$x][$y_axis] = '-';
        }
    }
    if (($x_axis >= 0) and ($x_axis < $x_size)) {
        for (my $y=0; $y<$y_size; $y++) {
            $$self[$x_axis][$y] = '|';
        }
    }
    if (($x_axis >= 0) and ($x_axis < $x_size) and($y_axis >= 0) and ($y_axis < $y_size)) {
        $$self[$x_axis][$y_axis] = '+';
    }

    # plot the points
    for (my $i=0; $i<$num_points; $i++) {
        my $x_pos = 0;
        if ($$xy_points[$i][0]) {
            $x_pos = int($x_scale * ($$xy_points[$i][0] + $x_offset));
        }
        if ($x_pos < 0) {
            $x_pos = 0;
        } elsif ($x_pos > $x_size - 1) {
            $x_pos = $x_size - 1;
        }
        my $y_pos = 0;
        if ($$xy_points[$i][1]) {
            $y_pos = int($y_scale * ($$xy_points[$i][1] + $y_offset));
        }
        if ($y_pos < 0) {
            $y_pos = 0;
        } elsif ($y_pos > $y_size - 1) {
            $y_pos = $y_size - 1;
        }
        if ($$xy_points[$i][0] and $$xy_points[$i][1]) {
            $$self[$x_pos][$y_pos] = $char;
        }
    }

    # add the axes limits
    # left label
    my $y_pos = 1;
    if ($y_axis < 1) {
        $y_pos = 1;
    } elsif ($y_axis > $y_size) {
        $y_pos = $y_size;
    } else {
        $y_pos = $y_axis;
    }
    my $label = sprintf("%0.1f ", $x_min);
    my $l = length($label);
    for (my $i=0; $i<$l; $i++) {
        $$self[$i][$y_pos] = substr($label, $i, 1);
    }
    # right label
    $label = sprintf(" %0.1f", $x_max);
    $l = length($label);
    my $x_label_pos = $x_size - $l;
    for (my $i=0; $i<$l; $i++) {
        $$self[$x_label_pos+$i][$y_pos] = substr($label, $i, 1);
    }
    # bottom label
    $label = sprintf("%0.1f", $y_min);
    $l = length($label);
    my $y_label_pos = $x_axis - int($l/2);
    if ($y_label_pos < 0) {
        $y_label_pos = 0;
    } elsif ($y_label_pos + $l > $x_size) {
        $y_label_pos = $x_size - $l;
    }
    for (my $i=0; $i<$l; $i++) {
        $$self[$y_label_pos+$i][0] = substr($label, $i, 1);
    }
    # top label
    $label = sprintf("%0.1f", $y_max);
    $l = length($label);
    $y_label_pos = $x_axis - int($l/2);
    if ($y_label_pos < 0) {
        $y_label_pos = 0;
    } elsif ($y_label_pos + $l > $x_size) {
        $y_label_pos = $x_size - $l;
    }
    for (my $i=0; $i<$l; $i++) {
        $$self[$y_label_pos+$i][$y_size-1] = substr($label, $i, 1);
    }

    # add the labels
    # x label
    $l = length($x_label);
    $x_label_pos = $x_size - $l;
    for (my $i=0; $i<$l; $i++) {
        $$self[$x_label_pos+$i][$y_pos+1] = substr($x_label, $i, 1);
    }
    # y label
    $l = length($y_label);
    $y_label_pos = $x_axis - int($l/2);
    if ($y_label_pos < 0) {
        $y_label_pos = 0;
    } elsif ($y_label_pos + $l > $x_size) {
        $y_label_pos = $x_size - $l;
    }
    for (my $i=0; $i<$l; $i++) {
        $$self[$y_label_pos+$i][$y_size] = substr($y_label, $i, 1);
    }

    # print the $self
    my $prefix = "\n";
    my $newline = "\n";
    my $postfix = "\n";
    if (($type eq 'html') or ($type eq 'HTML')) {
        $prefix = "<pre>\n";
        $newline = "\n";
        $postfix = "</pre>\n";
    }
    print $prefix;
    for (my $y=$y_size; $y>=0; $y--) {
        for (my $x=0; $x<$x_size; $x++) {
            print $$self[$x][$y];
        }
        print $newline;
    }
    print $postfix;

    return 1;
}


1;
__END__

=head1 NAME

ScatterPlot - Perl extension for drawing ASCII scatter plots

=head1 SYNOPSIS

  use ScatterPlot;

=head1 DESCRIPTION

This module will draw a quick and easy ASCII scatter plot.  It has only two functions, new() and draw().  new() takes no arguments and creates a new ScatterPlot object.  draw() can be called with no arguments to draw a sample test plot.  You can call draw like this:  

    draw($xy_points);

where $xy_points is a reference to an array of (x,y) pairs.  See the file ScatterPlot.pl for an example.  The full call to draw is: 

    draw($xy_points, $x_size, $y_size, $x_label, $y_label, $char, $type);

where $xy_points is a reference to an array of (x,y) pairs, $x_size is an integer describing the width of the plot in characters, $y_size is an integer describing the height of the plot in characters, $x_label is a string for the horizontal axis label, $y_label is a string for the vertical axis lable, $char is the plot character, and $type is either 'text', 'html', or 'HTML'.  If you are using CGI or sending the plot output to a web page, then use $type='html' or $type='HTML'.  

The method draw() will automatically scale the plot to fit your data and draw the axes labels accordingly.  The size of the output text will be $y_size lines of text, each of which is $x_size long in characters (plus line terminator).  In text mode the plot begins with "\n" and ends with "\n", while in html mode the plot begins with "<pre>" and ends with "<\pre>".  

=head2 EXPORT

none


=head1 SEE ALSO

The example file ScatterPlot.pl contains an example of how to use the ScatterPlot module.  

=head1 AUTHOR

Les Hall, E<lt>inventor-66@comcast.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Les Hall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut













