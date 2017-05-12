#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use SAL::DBI;
use SAL::Graph;

my $send_mime_headers = 1;

my $q = new CGI;
my $self_url = $q->script_name();

my $graph_obj = new SAL::Graph;
my $dbo_factory = new SAL::DBI;
my $dbo_data = $dbo_factory->spawn_sqlite(':memory:');

#######################################################################################################################
# Build a sample report...
my $report_query = qq[create table ReportData (dfm varchar(255), name varchar(255), purchases int(11), sort int(11))];
$dbo_data->do($report_query);

my $header_dfm = qq|[strong bg=#dddddd solid_over solid_under]|;
my $totals_dfm = qq|[strong dashed_over solid_under]|;

$report_query = qq[insert into ReportData values('$header_dfm Data Formatting Tags','Customer','Purchases','0')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Morris','30','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Albert','22','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Tina','14','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','John','2','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Jane','19','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values('$totals_dfm','Totals','0','999')];  # we'll replace this 0 later...
$dbo_data->do($report_query);

#######################################################################################################################
# Query Section

my $graph_query = 'SELECT name, purchases FROM ReportData WHERE (sort > 0) and (sort < 998) ORDER BY sort, name';
my ($w, $h) = $dbo_data->execute($graph_query);

# set the legend and general formatting
my @legend = (' ');
$graph_obj->set_legend(@legend);
$graph_obj->{image}{width} = '400';
$graph_obj->{image}{height} = '300';
$graph_obj->{formatting}{title} = "Customer Purchases";
$graph_obj->{formatting}{'y_max_value'} = 50;
$graph_obj->{formatting}{'y_min_value'} = 0;
$graph_obj->{formatting}{'x_label'} = 'Customer';
$graph_obj->{formatting}{'y_label'} = 'Purchases';
$graph_obj->{formatting}{'y_tick_number'} = 10;
$graph_obj->{formatting}{'shadow_depth'} = '0';
$graph_obj->{formatting}{'boxclr'} = '#EEEEFF';
$graph_obj->{formatting}{'show_values'} = '0';
$graph_obj->{formatting}{'values_vertical'} = '0';
$graph_obj->{formatting}{'long_ticks'} = '1';
$graph_obj->{formatting}{'line_types'} = [(1,3,4)];
$graph_obj->{formatting}{'line_width'} = '2';
#$graph_obj->{formatting}{'logo'} = '';
$graph_obj->{formatting}{'logo_resize'} = 0.32;
$graph_obj->{formatting}{'logo_position'} = 'UL';
$graph_obj->{formatting}{'text_space'} = 32;
$graph_obj->{formatting}{'markers'} = [(7,5,1,8,2,6)];

# set the graph type
$graph_obj->{type}='bars3d';

# and finally graph it all
my $graph = $graph_obj->build_graph($send_mime_headers, $dbo_data, $graph_query);
print $graph;
