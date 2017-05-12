#!/usr/bin/perl -w 
use strict;

use SVG::Template::Graph;
use Config::General;
use Data::Dumper;
use Carp;


my $file = $ARGV[0];
my $template = $ARGV[1];
unless ($file && -r $file) {
	croak("Template error: Unable to find data file $file: $!")
}
unless ($template && -r $template) {
	croak("Template error: Unable to find template file $template: $!")
}


my $conf = Config::General->new(
	-ConfigFile => $file,
	-UseApacheInclude => 1,
	-IncludeRelative => 1) || croak("Failed to open configuration object: $!");

my %config = $conf->getall; #|| croak("Failed to retrieve configuration data from file '$file':$!");
my $data = $config{'SVG::Template::Graph::Trace'} ||
	croak("Did not find an SVG::Template::Graph element in data file '$filë́'");

#construct a new SVG::Template::Graph object with a file handle
my $tt = SVG::Template::Graph->new($template);
#set up the titles for the graph
$tt->setGraphTitle(['RELATIVE PERFORMANCE','Equities Vs. Indices']);
#generate the traces. 
print STDERR Dumper $data if lc($ARGV[-1]) eq 'debug';

$data = [$data] if ref($data) eq 'HASH';

$tt->drawTraces($data) || confess("Failed to draw the traces");
#serialize and print

print  $tt->burn() || confess("Failed to serialize output");


