use lib qw(lib);

use SVG::TT::Graph::Bar;

my @fields = qw(Jan Feb Mar);
my @data_sales_02 = qw(12 45 21);

my $graph = SVG::TT::Graph::Bar->new({
      'height'   => '500',
      'width'    => '300',
      'fields'   => \@fields,
      'compress' => 0,
});
  
$graph->add_data({
      'data' => \@data_sales_02,
      'title' => 'Sales 2002',
});
  
#print "Content-type: image/svg+xml\r\n\r\n";
print $graph->burn();
