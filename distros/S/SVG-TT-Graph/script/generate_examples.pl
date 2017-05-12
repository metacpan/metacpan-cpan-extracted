#!/usr/bin/perl -w

# This module can be used to generate some examples

# More example will be added for the next release.
# See http://leo.cuckoo.org/projects/SVG-TT-Graph/ for more

use lib qw( ./lib ./blib/lib ../blib/lib );
use SVG::TT::Graph::Bar;
use SVG::TT::Graph::BarHorizontal;
use SVG::TT::Graph::Line;
use SVG::TT::Graph::Pie;

############ Create example directory

my $dir = 'examples';
mkdir($dir) unless -d $dir;

############ Some data to play with
my @fields1 = ('Januararyasdasdasd','Feb','Mar','Apr','Mayasdasdasdasdasd');
my @data_01 = qw(12 45 21 45 32);
my @data_02 = qw(12 23435 21 3445 345632);

my @fields2 = ('Oct 02','Nov 02','Dec 02','Jan 03','Feb 03','Mar 03','Apr 03','May 03','Jun 03','Jul 03','Aug 03','Sep 03');
my @data_03 = qw(0 0 0 0 0 0 0 0 0 0 1815 0);

############ Generate some bar graphs

run_bar('Bar',\@fields1,\@data_01,'small_range');
run_bar('BarHorizontal',\@fields1,\@data_02,'large_range');
run_line('Line',\@fields2,\@data_03,'default');

sub run_line {
	my $type = shift;
	my $fields = shift;
	my $data = shift;
	my $title = shift;

	my $module = "SVG::TT::Graph::$type";
	
	## Basic using default config
	my $graph1 = $module->new({
		'fields' => $fields,
	});
	$graph1->add_data({
		'data' => $data,
		'title' => 'Sales 2002 asdfasdfds',
	});
	
	my $outfile1 = "$dir/$type" . "_defaults_" . "$title.svg";
	open(FH,">$outfile1");
	print FH $graph1->burn();
	close(FH);
	
}



sub run_bar {
	my $type = shift;
	my $fields = shift;
	my $data = shift;
	my $title = shift;

	my $module = "SVG::TT::Graph::$type";
	my $graph2 = $module->new({
		'fields' => $fields,
	    'height'            => '400',
	    'width'             => '400',
	    'show_data_values'  => 1,
	
		'stagger_x_labels'  => 1,
		'bar_gap'           => 0,
	
	    'show_x_labels'     => 1,
	    'show_y_labels'     => 1,
		'rotate_x_labels'	=> 1,
		'key'				=> 0,
	
	    'show_x_title'      => 1,
	    'x_title'           => 'Field names',
	
	    'show_y_title'      => 1,
	    'y_title'           => 'Y Scale title',
	
	    'show_graph_title'		=> 1,
	    'graph_title'           => 'Graph Title',
	    'show_graph_subtitle'   => 1,
	    'graph_subtitle'        => 'Graph Sub Title',	
	});
	$graph2->add_data({
		'data' => $data,
		'title' => 'Sales 2002 asdfasdfds',
	});
	
	my $outfile2 = "$dir/$type" . "_non-defaults_" . "$title.svg";
	open(FH,">$outfile2");
	print FH $graph2->burn();
	close(FH);
	
	## Basic using default config
	my $graph1 = $module->new({
		'fields' => $fields,
	});
	$graph1->add_data({
		'data' => $data,
		'title' => 'Sales 2002 asdfasdfds',
	});
	
	my $outfile1 = "$dir/$type" . "_defaults_" . "$title.svg";
	open(FH,">$outfile1");
	print FH $graph1->burn();
	close(FH);
	
}





