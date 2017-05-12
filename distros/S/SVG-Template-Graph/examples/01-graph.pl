#!/usr/bin/perl -w 
use strict;
use SVG::Template::Graph;
use Carp;
use Data::Dumper;
my $data = 
[
	{

        'title'=> 'John Doe',
        'data' => #hash ref containing x-val and y-val array refs
                {
                'x_val' =>
                        [1, 1.5, 2, 3.1, 3.5, 4, 5, 5.1, 5.2, 5.7, 6, 6.7],
                'y_val' =>
                        [4, 3, 3.2, 2.5, 2.1, 1.9, 1.2, 2.3, 3, 4.2, 5.1, 6.3],
                },
        'format' =>
                { #note that these values could change for *each* trace
                'x_min' =>      0.5, #or for your case, the date value of the last point
                'x_max' =>      7.5, #or for your case, the date value of the 1st point
                'y_min' =>      -0.5,
                'y_max' =>      7.5,
                'x_title' =>    'Calendar Year',
                'y_title' =>    'Effort',

                #define the labels that provide the data context.

                'labels' =>
                        {
                        #for year labels, we have to center the axis markers
                        'x_ticks' =>
                                {
                                'label'         =>[1999,2000,2001,2002,2003,2004,2005,],
                                'position'      =>[1,2,3,4,5,6,7,],
                                },
                        'y_ticks' =>
                                {
                                #tick mark labels
                                'label' => ["FIRED!",'very bad','bad','average','good','very good','excellent','superb!' ],
                                #tick mark location in the data space
                                'position' => [0,1,2,3,4,5,6,7],
                                },
                        },
                },
	},
];


###################################################


my $file = 'test.svg';
unless (-r $file) {
	croak("Unable to find file $file: $!")
}

#construct a new SVG::Template::Graph object with a file handle
my $tt = SVG::Template::Graph->new($file);

print  Dumper $tt->D;

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

