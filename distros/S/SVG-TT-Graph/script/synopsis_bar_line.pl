use lib qw(lib);
use SVG::TT::Graph::BarLine;

my @fields = qw(Jan Feb Mar);
my @data_sales_02 = qw(12 45 21);
my @data_sales_03 = (24, 55, 61);

my $graph = SVG::TT::Graph::BarLine->new({
  'height'   => '500',
  'width'    => '300',
  'fields'   => \@fields,
  'compress' => 0,
});
  
$graph->add_data({
  'data'  => \@data_sales_02,
  'title' => 'Sales 2002',
});
  
$graph->add_data({
  'data'  => \@data_sales_03,
  'title' => 'Sales 2003',
});

#print "Content-type: image/svg+xml\n\n";
print $graph->burn();

#my $tt = $graph->get_template();
#print "$tt\n";

