use lib qw(lib);
use SVG::TT::Graph::TimeSeries;

my @data_cpu = ('2003-09-03 09:30:00',23,'2003-09-03 09:45:00',54,'2003-09-03 10:00:00',67,'2003-09-03 10:15:00',12);
my @data_disk = ('2003-09-03 09:00:00',12,'2003-09-03 10:00:00',26,'2003-09-03 11:00:00',23);
  
my $graph = SVG::TT::Graph::TimeSeries->new({
      'height'   => '500',
      'width'    => '300',
      'compress' => 0,
});
  
$graph->add_data({
      'data' => \@data_cpu,
      'title' => 'CPU',
});

$graph->add_data({
      'data' => \@data_disk,
      'title' => 'Disk',
});
  
#print "Content-type: image/svg+xml\r\n\r\n";
print $graph->burn();
