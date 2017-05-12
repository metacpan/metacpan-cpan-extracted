use lib qw(lib);
use SVG::TT::Graph::XY;

my @data_cpu  = (0.3, 23, 0.5, 54, 1.0, 67, 1.8, 12);
my @data_disk = (0.45, 12, 0.51, 26, 0.53, 23);
  
my $graph = SVG::TT::Graph::XY->new({
  'height' => '500',
  'width'  => '300',
});
  
$graph->add_data({
  'data'  => \@data_cpu,
  'title' => 'CPU',
});

$graph->add_data({
  'data'  => \@data_disk,
  'title' => 'Disk',
});

#print "Content-type: image/svg+xml\n\n";
print $graph->burn();
