#!/usr/bin/env perl

use lib qw( ./lib ./blib/lib ./lib);

use strict;
use Getopt::Long;
use Data::Dumper;
use SVG::TT::Graph::TimeSeries;

my $MODULE_NAME      = "timeseries";
my $MODULE_VERSION   = "1.0.0";
my $DEFAULT_SAMPLE_FILE = "timeseries";

sub zUsage
{
    die <<USAGE;
$MODULE_NAME [-f <file_name>] -html

Create sample SVG files

where -f  <file name>              File name for output (without ext)
USAGE
} #end zUsage

########################################################
#
#        MAIN
#
#########################################################

my ($file_name);

GetOptions(
    "f=s"    => \$file_name,
) or zUsage();

$file_name = $DEFAULT_SAMPLE_FILE unless $file_name;

#print Dumper(%group)."\n";
#print Dumper(%passwd)."\n";
#####################################################################################

my @data_cpu = ('2003-09-03 09:00:00',10,'2003-09-03 09:30:00',23,'2003-09-03 09:45:00',54,'2003-09-03 10:00:00',67,'2003-09-03 10:15:00',12);
my @data_disk = ('2003-09-03 08:00:00',8,'2003-09-03 09:00:00',12,'2003-09-03 10:00:00',26,'2003-09-03 11:00:00',23);
  
my $graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 0,
    'show_data_values'  => 0,

    'area_fill'         => 0,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 0,
    
    'x_label_format'    => '%Y-%m-%d %H:%M:%S',    
    
    'show_y_labels'     => 1,

    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Auto-scale X and Y',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'No Fill. X labels formatted.',
    
    'key'               => 1,
    'key_position'      => 'bottom',
    
});

$graph->add_data({
'data' => \@data_cpu,
'title' => 'CPU',
});

$graph->add_data({
'data' => \@data_disk,
'title' => 'Disk',
});

open (SAMPLE_FILE, ">".$file_name.'1.svg') || die("ERROR: Could not open sample file: ${file_name}1.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;
#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 1,
    'show_data_values'  => 1,

    'area_fill'         => 1,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 0,
    
    'x_label_format'    => '%H:%M:%S',  
    'rotate_x_labels'   => 1,    
    
    'timescale_divisions'=> '1 hours',
    
    'show_y_labels'     => 1,
    'y_label_format'    => '%.1f',
    
    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Auto-scale X and Y',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'Fill. Rotate formatted X labels. Show values and points.',
    
    'key'               => 1,
    'key_position'      => 'bottom',
    
});

$graph->add_data({
'data' => \@data_cpu,
'title' => 'CPU',
});

$graph->add_data({
'data' => \@data_disk,
'title' => 'Disk',
});

open (SAMPLE_FILE, ">".$file_name.'2.svg') || die("ERROR: Could not open sample file: ${file_name}2.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;
#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 0,
    'show_data_values'  => 0,

    'area_fill'         => 1,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 0,
    'rotate_x_labels'   => 0,
    
    'x_label_format'    => '%e %B, %Y %I:%M:%S%p',    
    'timescale_divisions'=> '1',   
    
    'show_y_labels'     => 1,

    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Minimum and maximum time scale',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'X labels formatted.',
    
    'key'               => 1,
    'key_position'      => 'bottom',
    
    'min_timescale_value' => '2003-09-03 08:00:00',
    'max_timescale_value' => '2003-09-03 10:00:00',
    
});

$graph->add_data({
'data' => \@data_cpu,
'title' => 'CPU',
});

$graph->add_data({
'data' => \@data_disk,
'title' => 'Disk',
});

open (SAMPLE_FILE, ">".$file_name.'3.svg') || die("ERROR: Could not open sample file: ${file_name}3.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;
#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 0,
    'show_data_values'  => 1,

    'area_fill'         => 1,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 0,
    
    'x_label_format'    => '%H:%M:%S',    
    
    'max_scale_value'   => 60,
    'min_scale_value'   => 10,
    
    'show_y_labels'     => 1,

    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Minimum and maximum value scale',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'Values shown.',
    
    'key'               => 1,
    'key_position'      => 'bottom',
    
});

$graph->add_data({
'data' => \@data_cpu,
'title' => 'CPU',
});

$graph->add_data({
'data' => \@data_disk,
'title' => 'Disk',
});

open (SAMPLE_FILE, ">".$file_name.'4.svg') || die("ERROR: Could not open sample file: ${file_name}4.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;
#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 0,
    'show_data_values'  => 1,

    'area_fill'         => 1,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 1,
    
    'timescale_divisions'=> '1 days',    
    'min_timescale_value' => '2003-09-01',
    
    'x_label_format'    => '%A',    
    
    'max_scale_value'   => 100,
    'min_scale_value'   => 0,
    
    'show_y_labels'     => 1,

    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Staggered timescale.',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'Labelled data points',
    
    'key'               => 1,
    'key_position'      => 'bottom',
    
});

my @data_cpu_long = (['2003-09-01 08:00:00',10,'<a xlink:href="http://www.w3.org">A</a>'],
                     ['2003-09-01 20:00:00',13,'B'],
                     ['2003-09-02 08:00:00',23,'C'],
                     ['2003-09-02 20:00:00',25,'D'],
                     ['2003-09-03 08:00:00',34,'E'],
                     ['2003-09-03 20:00:00',67,'F'],
                     ['2003-09-04 08:00:00',56,'G'],
                     ['2003-09-04 20:00:00',45,'H'],
                     ['2003-09-05 08:00:00',34,'I'],
                     ['2003-09-05 20:00:00',23,'J'],
                     ['2003-09-06 08:00:00',10,'K'],
                     ['2003-09-06 20:00:00',5,'L'],
                     ['2003-09-07 08:00:00',24,'M'],
                     ['2003-09-07 20:00:00',13,'N'],
                     ['2003-09-08 08:00:00',89,'O'],
                     ['2003-09-08 20:00:00',90,'P'],
                     ['2003-09-09 08:00:00',95,'Q'],
                     ['2003-09-09 20:00:00',91,'R'],
                     );

$graph->add_data({
'data' => \@data_cpu_long,
'title' => 'CPU usage',
});

open (SAMPLE_FILE, ">".$file_name.'5.svg') || die("ERROR: Could not open sample file: ${file_name}5.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;
#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 0,
    'show_data_values'  => 1,
    
    'data_value_format' => '%.3f',    

    'area_fill'         => 1,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 1,
    'rotate_x_labels'   => 1,
    
    'scale_divisions'   => '',
    
    'timescale_divisions'=> '1 days',    
    'min_timescale_value' => '2003-09-01',
    
    'x_label_format'    => '%A',    
   
    'show_y_labels'     => 1,

    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Autoscaled with value range smaller than 1',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'Data values formatted.',
    
    'key'               => 0,
    'key_position'      => 'bottom',
    
});

my @data_cpu_small = ('2003-09-01 08:00:00',0.10,
                     '2003-09-01 20:00:00',0.13,
                     '2003-09-02 08:00:00',0.23,
                     '2003-09-02 20:00:00',0.25,
                     '2003-09-03 08:00:00',0.34,
                     '2003-09-03 20:00:00',0.67,
                     '2003-09-04 08:00:00',0.56,
                     '2003-09-04 20:00:00',0.45,
                     '2003-09-05 08:00:00',0.34,
                     '2003-09-05 20:00:00',0.23,
                     '2003-09-06 08:00:00',0.10,
                     '2003-09-06 20:00:00',0.5,
                     '2003-09-07 08:00:00',0.24,
                     '2003-09-07 20:00:00',0.13,
                     '2003-09-08 08:00:00',0.69,
                     '2003-09-08 20:00:00',0.60,
                     '2003-09-09 08:00:00',0.65,
                     '2003-09-09 20:00:00',0.61,
                     );

$graph->add_data({
'data' => \@data_cpu_small,
'title' => 'CPU usage',
});

open (SAMPLE_FILE, ">".$file_name.'6.svg') || die("ERROR: Could not open sample file: ${file_name}6.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;

#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 0,
    'show_data_values'  => 0,
    
    'area_fill'         => 1,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 1,
    'stacked'           => 1,
    
    'scale_divisions'   => '',
    
    'timescale_divisions'=> '1 minutes',    
    
    'x_label_format'    => '%H:%M',    
   
    'show_y_labels'     => 1,

    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Stacked',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'Very small value range, autoformatted',
    
    'key'               => 1,
    'key_position'      => 'right',
    
    'compress'          => 1,
    
});

my @data_stack1 = (  '08:01:00',0.010,
                     '08:02:00',0.013,
                     '08:03:00',0.023,
                     '08:04:00',0.025,
                     '08:05:00',0.034,
                     '08:06:00',0.067,
                     '08:07:00',0.056,
                     '08:08:00',0.045,
                     '08:09:00',0.034,
                     '08:10:00',0.023,
                     );

my @data_stack2 = (  '08:10:00',0.010,
                     '08:09:00',0.011,
                     '08:08:00',0.022,
                     '08:07:00',0.023,
                     '08:06:00',0.034,
                     '08:05:00',0.065,
                     '08:04:00',0.056,
                     '08:03:00',0.047,
                     '08:02:00',0.038,
                     '08:01:00',0.029,
                     );
                     
$graph->add_data({
'data' => \@data_stack1,
'title' => 'User',
});
$graph->add_data({
'data' => \@data_stack2,
'title' => 'System',
});

open (SAMPLE_FILE, ">".$file_name.'7.svg.gz') || die("ERROR: Could not open sample file: ${file_name}7.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;
#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 1,
    'show_data_values'  => 1,
    'rollover_values'   => 1,

    'area_fill'         => 0,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 0,
    
    'x_label_format'    => '%H:%M:%S',  
    'rotate_x_labels'   => 1,    
    
    'timescale_divisions'=> '15 minutes',
    
    'show_y_labels'     => 1,
    
    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Rollover values',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'No key.',
    
    'key'               => 0,
    'key_position'      => 'bottom',
    
});

$graph->add_data({
'data' => \@data_cpu,
'title' => 'CPU',
});

$graph->add_data({
'data' => \@data_disk,
'title' => 'Disk',
});

open (SAMPLE_FILE, ">".$file_name.'8.svg') || die("ERROR: Could not open sample file: ${file_name}8.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;

#####################################################################################

$graph->clear_data();

$graph = SVG::TT::Graph::TimeSeries->new({
    'height'            => '500',
    'width'             => '500',
    'show_data_points'  => 1,
    'show_data_values'  => 0,
    'max_time_span'     => '1 minutes',
    
    'area_fill'         => 1,
    'show_x_labels'     => 1,
    'stagger_x_labels'  => 1,
    'stacked'           => 0,
    
    'scale_divisions'   => '',
    
    'timescale_divisions'=> '1 minutes',    
    
    'x_label_format'    => '%H:%M',    
   
    'show_y_labels'     => 1,

    'show_x_title'      => 1,
    'x_title'           => 'Time',

    'show_y_title'      => 1,
    'y_title'           => 'Bogons',

    'show_graph_title'      => 1,
    'graph_title'           => 'Filled with maximum timespan',
    'show_graph_subtitle'   => 1,
    'graph_subtitle'        => 'Missing data skipped',
    
    'key'               => 0,
    'key_position'      => 'right',
    
    'compress'          => 1,
    
});

@data_stack1 = (  '08:01:00',10,
                     '08:02:00',13,
                     '08:03:00',23,
                     '08:04:00',25,
                     '08:05:00',34,
                     '08:06:00',67,
                     '08:07:00',56,
                     '08:08:00',45,
                     '08:09:00',34,
                     '08:10:00',53,
                     );

@data_stack2 = (     '08:10:00',10,
                     '08:09:00',31,
                     '08:06:00',34,
                     '08:05:00',65,
                     '08:04:00',56,
                     '08:03:00',47,
                     '08:02:00',38,
                     '08:01:00',49,
                     );
                     
$graph->add_data({
'data' => \@data_stack1,
'title' => 'User',
});
$graph->add_data({
'data' => \@data_stack2,
'title' => 'System',
});

open (SAMPLE_FILE, ">".$file_name.'9.svg.gz') || die("ERROR: Could not open sample file: ${file_name}9.svg");

print SAMPLE_FILE $graph->burn();
close SAMPLE_FILE;

#####################################################################################
# HTML page with all
open (SAMPLE_FILE, ">".$file_name.'.html') || die("ERROR: Could not open sample file: ${file_name}.html");

print SAMPLE_FILE <<HEADER;
<html>
<head>Sample Time Series Charts</head>
<body>
    <p>
HEADER
;
    for my $i (1,2,3,4,5,6,7,8,9) {
        print SAMPLE_FILE "<object type=\"image/svg+xml\" name=\"sample$i\" width=\"500\" height=\"500\"\n";
        print SAMPLE_FILE "data=\"${file_name}${i}.svg\">\n" if $i != 7 && $i != 9;
        print SAMPLE_FILE "data=\"${file_name}${i}.svg\">\n" if $i == 7 && $i == 9;
        print SAMPLE_FILE "Requires SVG plugin.\n</object>\n";
    }
    print SAMPLE_FILE <<FOOTER;
    </p>
</body>
</html>
FOOTER
;

close SAMPLE_FILE;
