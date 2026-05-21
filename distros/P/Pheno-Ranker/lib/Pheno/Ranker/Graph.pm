package Pheno::Ranker::Graph;

use strict;
use warnings;
use autodie;
use feature qw(say);
use JSON::XS;
use Sort::Naturally qw(nsort);
use Pheno::Ranker::IO;
use Pheno::Ranker::Metrics;
use Exporter 'import';
our @EXPORT = qw(binary_hash2graph cytoscape2graph);
use constant DEVEL_MODE => 0;

############################
############################
#  SUBROUTINES FOR GRAPHS  #
############################
############################

sub binary_hash2graph {
    my $arg                 = shift;
    my $ref_binary_hash     = $arg->{ref_binary_hash};
    my $output              = $arg->{json};
    my $metric_name         = $arg->{metric};
    my $verbose             = $arg->{verbose};
    my $graph_stats         = $arg->{graph_stats};
    my $graph_min_weight    = $arg->{graph_min_weight};
    my $graph_max_weight    = $arg->{graph_max_weight};
    my @ids                 = nsort( keys %$ref_binary_hash );
    my @strings             = map { $ref_binary_hash->{$_}{binary_digit_string_weighted} } @ids;
    my %similarity_function = (
        hamming => \&hd_fast,
        jaccard => \&jaccard_similarity_formatted,
    );
    my $metric = $similarity_function{$metric_name};

    my @nodes = map { { data => { id => $_ } } } @ids;
    my @edges;

    for my $i ( 0 .. $#ids ) {
        say "Creating graph edges for <" . $ids[$i] . ">..." if $verbose;
        my $str1 = $strings[$i];

        for my $j ( $i + 1 .. $#ids ) {
            my $weight = $metric->( $str1, $strings[$j] );
            next unless _keep_edge( $weight, $graph_min_weight, $graph_max_weight );

            push @edges,
              {
                data => {
                    source => $ids[$i],
                    target => $ids[$j],
                    weight => $weight,
                }
              };
        }
    }

    my %graph = (
        elements => {
            nodes => \@nodes,
            edges => \@edges,
        }
    );

    say "Writting <$output> file " if $verbose;
    write_json( { filepath => $output, data => \%graph } );

    return defined $graph_stats ? \%graph : undef;
}

sub _keep_edge {
    my ( $weight, $min_weight, $max_weight ) = @_;

    return 0 if defined $min_weight && $weight < $min_weight;
    return 0 if defined $max_weight && $weight > $max_weight;
    return 1;
}

sub cytoscape2graph {

 # This is a very time consuming function, that's why we only load data in Graph
 # if the user asks for it
    require Graph;

    # Decode JSON to a Perl data structure
    my $arg       = shift;
    my $json_data = $arg->{graph};
    my $output    = $arg->{output};
    my $metric    = $arg->{metric};
    my $verbose   = $arg->{verbose};
    my $jaccard   = $metric eq 'jaccard' ? 1 : 0;

    my @nodes = @{ $json_data->{elements}{nodes} };
    my @edges = @{ $json_data->{elements}{edges} };

    # Create a new Graph object
    my $graph = Graph->new( undirected => 1 );

    # Add nodes and edges to the graph
    foreach my $node (@nodes) {
        $graph->add_vertex( $node->{data}{id} );
    }

    foreach my $edge (@edges) {
        $graph->add_weighted_edge(
            $edge->{data}{source},
            $edge->{data}{target},

            # Convert to distances if Jaccard
            $jaccard ? 1 - $edge->{data}{weight} : $edge->{data}{weight}
        );
    }

    # Now $graph contains the Graph object populated with the Cytoscape data
    graph_stats( $graph, $output, $metric, $verbose );
    return 1;
}

sub graph_stats {
    my ( $g, $output, $metric, $verbose ) = @_;

    # Open the output file
    say "Writting <$output> file " if $verbose;
    open( my $fh, '>:encoding(UTF-8)', $output );

    # Basic stats
    print $fh "Metric: ",             ucfirst($metric),    "\n";
    print $fh "Number of vertices: ", scalar $g->vertices, "\n";
    print $fh "Number of edges: ",    scalar $g->edges,    "\n";

    # Checking connectivity and components
    print $fh "Is connected: ",         $g->is_connected,                "\n";
    print $fh "Connected Components: ", scalar $g->connected_components, "\n";

    # Diameter and average path length, check if the graph is connected first
    if ( $g->is_connected ) {
        print $fh "Graph Diameter: ", ( join "->", $g->diameter ), "\n";
        print $fh "Average Path Length: ",
          sprintf( "%7.3f", $g->average_path_length ), "\n";
    }

    # Display degrees of all vertices
    foreach my $v ( $g->vertices ) {
        print $fh "Degree of vertex $v: ", $g->degree($v), "\n";
    }

    # Minimum Spanning Tree
    my $mst = $g->MST_Kruskal; # Assuming Kruskal's is available and appropriate
    print $fh "MST has ", scalar $mst->edges, " edges\n";

    # Calculate and write all pairs shortest paths and their lengths to the file
    foreach my $u ( $g->vertices ) {
        foreach my $v ( $g->vertices ) {
            if ( $u ne $v ) {
                my @path = $g->SP_Dijkstra( $u, $v )
                  ;    # Get shortest path using Dijkstra's algorithm
                if (@path) {
                    my $distance = $g->path_length( $u, $v );    # Recompute
                    print $fh "Shortest path from $u to $v is ",
                      ( join "->", @path ), " [", scalar @path,
                      "] with length $distance\n";
                }
                else {
                    print $fh "No path from $u to $v\n";
                }
            }
        }
    }

    # Close the output file
    close $fh;
    return 1;
}

1;
