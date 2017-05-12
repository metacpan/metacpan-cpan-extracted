#!/usr/bin/perl -w 
use strict;

use SVG::Template::Graph;
use Config::General;

my $file = $ARGV[0];
unless (-r $file) {
	croak("Template error: Unable to find file $file: $!")
}


my $data = 
[
	{
	barGraph=>1,
	barSpace=>20,
        'title'=> '1: Trace 1',
        'data' => #hash ref containing x-val and y-val array refs
                {
                'x_val' =>
                        [50,100,150,200,250,300,350,400,450,500,550],
                'y_val' =>
                        [100,150,100,126,100,175,100,150,120,125,100],

                },
        'format' =>
                { #note that these values could change for *each* trace
		'line' => 1,
		'marker' => 1,
		'marker_vector'=>'height',
		'marker_source'=>'rect.svg',
                'x_min' =>      0, #or for your case, the date value of the last point
                'x_max' =>      600, #or for your case, the date value of the 1st point
                'y_min' =>      50,
                'y_max' =>      200,
                'x_title' =>    'Calendar Year',
                'y_title' =>    '% Annual Performance',

                #define the labels that provide the data context.

                'labels' =>
                        {
                        #for year labels, we have to center the axis markers
                        'x_ticks' =>
                                {
                                'label'         =>[2002,2003,2004],
                                'position'      =>[100,300,500],
                                },
                        'y_ticks' =>
                                {
                                #tick mark labels
                                'label' => [ 
					-250,
					-000,
					 250,
					 500],
                                #tick mark location in the data space
                                'position' => [50,100,150,200],
                                },
                        },
                },
	},


	{
	'lineGraph' => 1,
        'title'=> '2: Trace 2',
        'data' => #hash ref containing x-val and y-val array refs
                {
                'x_val' =>
                        [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10],
                'y_val' =>
                        [1,2,3,4,5,6,7,8,9,10,10,9,8,7,6,5,4,3,2,1],
                },
        'format' =>
                { #note that these values could change for *each* trace
                'line' => 1,
                'marker' => 0,
                'marker_vector'=>'height',
                'marker_source'=>'rect.svg',
                'x_min' =>      0, #or for your case, the date value of the last point
                'x_max' =>      11, #or for your case, the date value of the 1st point
                'y_min' =>      0,
                'y_max' =>      11,
                'x_title' =>    'Ten values',
                'y_title' =>    'Ten settings',

                #define the labels that provide the data context.

                'labels' =>
                        {
                        #for year labels, we have to center the axis markers
                        'x_ticks' =>
                                {
                                'label'         => [2,4,5.25,6,8,10],
                                'position'      => [2,4,5.25,6,8,10],
				'unit'          => '%',
                                },
                        'y_ticks' =>
                                {
                                #tick mark labels
                                'label' => ['two','four','six','eight','ten'],
                                #tick mark location in the data space
                                'position' => [2,4,6,8,10],
                                },
                        },
                },
        },
];


###################################################


#construct a new SVG::Template::Graph object with a file handle
my $tt = SVG::Template::Graph->new($file);
#set up the titles for the graph
$tt->setGraphTitle(['Hello svg graphing world','I am a subtitle']);
$tt->setYAxisTitle(1,['I am Y-axis One','Subtitle - % of total length']);
$tt->setYAxisTitle(2,['I am Y-axis Two','More text lives here']);
$tt->setXAxisTitle(1,['I am X-axis One','Subtitle - % of total length']);
$tt->setXAxisTitle(2,'I am X-axis Two');
#generate the traces. 
$tt->drawTraces($data);
#serialize and print
print  $tt->burn();

