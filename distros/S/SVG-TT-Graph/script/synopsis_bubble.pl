use lib qw(../lib);
use SVG::TT::Graph::Bubble;
 


my @data_flat_array;
my @data_AOA;
my @data_AOH;
# DONT DOTHIS
my @data_AOAHs;

for (1..20)
{
  push @data_flat_array, (rand(),rand(100),rand(20));
  push @data_AOA, [rand(),rand(100), rand(20)];
  push @data_AOH, {x=>rand(),y=>rand(100), z=>rand(20)};


  push @data_AOAHs, [rand(),rand(100), rand(20)];
  push @data_AOAHs, {x=>rand(),y=>rand(100), z=>rand(20)};

}


  

my $graph = SVG::TT::Graph::Bubble->new( {
       'height' => 900,
       'width'  => 900,

       'show_y_labels'    => 1,
       'yscale_divisions' => '',
       'min_yscale_value' => 0,
       'max_yscale_value' => 100,

       'show_x_labels'     => 1,
       'xscale_divisions'  => '',
       'min_xscale_value'  => 0,
       'max_xscale_value'  => 1,
       'stagger_x_labels'  => 0,
       'rotate_x_labels'   => 0,
       'y_label_formatter' => sub {return @_},
       'x_label_formatter' => sub {return @_},

       'show_data_values' => 0,
       'rollover_values'  => 0,

       'area_fill' => 1,

       'show_x_title' => 1,
       'x_title'      => 'X Field names',

       'show_y_title' => 0,
       'y_title'      => 'Y Scale',

       'show_graph_title'    => 0,
       'graph_title'         => 'Graph Title',
       'show_graph_subtitle' => 0,
       'graph_subtitle'      => 'Graph Sub Title',
       'key'                 => '',
       'key_position'        => 'right',

       # Stylesheet defaults
       #    'style_sheet'         => '/includes/graph.css', # internal stylesheet
       'bubble_fill'   => 0.4,
       'bubble_stroke' => 0,
       'diagonal_path' => 0,
       'random_colors' => 0
    } );


$graph->add_data( { 'data'  => \@data_flat_array,
                    'title' => 'Flat_array',
                  } );
$graph->add_data( { 'data'  => \@data_AOA,
                    'title' => 'Array_of_arrays',
                  } );
$graph->add_data( { 'data'  => \@data_AOH,
                    'title' => 'Array_of_hashes',
                  } );

$graph->add_data( { 'data'  => \@data_AOAHs,
                    'title' => 'Array_of_array_and_hashes',
                  } );


$graph->tidy(1);

#$graph->compress(1);
#print "Content-type: image/svg+xml\n\n";
print $graph->burn();
