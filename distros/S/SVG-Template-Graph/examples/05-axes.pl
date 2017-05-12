#!/usr/bin/perl -w

use strict;
use SVG::Template::Graph;
use Data::Dumper;
my $template_filename = shift @ARGV;
#draw the graph
my $x_vals = [ -5,-3,-2.1, 1, 2, 3, 0, -1, 0, 1, 2, 3, 4 ];
my $y_vals = [ -4,-3,-1.1, 2, 2, 3, 0, -2, 1, 3, 1, 4, 3 ];

my $data = [
    {

        'title' => 'plot one: title',
        'data'  =>               #hash ref containing x-val and y-val array refs
          {
            x_val => $x_vals,
            y_val => $y_vals,
          },
        'format' => {
    #        'x_axis'  => 1,
    #        'y_axis'  => 1,
            'x_min'   => Min($x_vals),
            'x_max'   => Max($x_vals),
            'y_min'   => Min($y_vals),
            'y_max'   => Max($y_vals),
            'x_title' => 'x title',
            'y_title' => 'y title',

            #define the labels that provide the data context.

            'labels' => {

                #for year labels, we have to center the axis markers
                'x_ticks' => {
                    'position' => [ $x_vals->[0], $x_vals->[-1] ],
                    'label'    => [ $x_vals->[0], $x_vals->[-1] ],
                },
                'y_ticks' => {

                    #tick mark location in the data space
                    'position' => [ $y_vals->[0], $y_vals->[-1] ],

                    #tick mark labels
                    'label' => [ $y_vals->[0], $y_vals->[-1] ],
                },
            },
        },
    },
];

my %attributes = ( SVG => { -new => {}, -xmlify => {} } );

#construct a new SVG::Template::Graph object with a file handle
my $tt = SVG::Template::Graph->new( $template_filename, %attributes );

#set up the titles for the graph
$tt->setGraphTitle( [ "Example:", "graph with axes", "$0" ] );
$tt->setYAxisTitle( 1, ['y','magnitude'] );
$tt->setXAxisTitle( 1, ['x','value'] );
#print  Dumper $tt;
#generate the traces.
$tt->drawTraces($data);
$tt->drawAxis("group.trace.axes.x.1",'x');
$tt->drawAxis("group.trace.axes.x.1",'y');


#serialize and print
print STDOUT $tt->burn();

#subs Max, Min from:
#https://lists.dulug.duke.edu/pipermail/dulug/2001-March/009326.html

sub Max {

    # takes an array ref - returns the max

    my $list = shift;
    my $max  = $list->[0];
    foreach (@$list) {
        $max = $_ if ( $_ > $max );
    }

    return ($max);
}

sub Min {

    # takes an array ref - returns the min

    my $list = shift;
    my $min  = $list->[0];
    foreach (@$list) {
        $min = $_ if ( $_ < $min );
    }

    return ($min);
}
