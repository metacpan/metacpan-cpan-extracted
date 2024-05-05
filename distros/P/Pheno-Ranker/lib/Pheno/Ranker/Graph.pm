package Pheno::Ranker::Graph;

use strict;
use warnings;
use autodie;
use feature qw(say);
use JSON::XS;
use Pheno::Ranker::IO;
use Exporter 'import';
our @EXPORT = qw(matrix2graph cytoscape2graph);
use constant DEVEL_MODE => 0;

############################
############################
#  SUBROUTINES FOR GRAPHS  #
############################
############################

sub matrix2graph {

    # *** IMPORTANT***
    # Hard-coded in purpose to avoid using Graph unless necessary

    my $arg         = shift;
    my $input       = $arg->{matrix};
    my $output      = $arg->{json};
    my $verbose     = $arg->{verbose};
    my $graph_stats = $arg->{graph_stats};

    # Open the matrix file to read
    open( my $matrix_fh, '<', $input );

    # Read the first line to get node IDs (headers)
    my $header_line = <$matrix_fh>;
    chomp $header_line;
    my @headers = split /\t/, $header_line;
    shift @headers;    # Remove the initial empty element from the headers list

    # Initialize the nodes and edges arrays
    my ( @nodes, @edges );
    my $threshold = 0.0;

    # Initialize an index to keep track of the current row
    my $current_index = 0;

    # Read each subsequent line
    while ( my $line = <$matrix_fh> ) {
        chomp $line;
        my @values  = split /\t/, $line;
        my $node_id = shift @values;    # The first column is the node ID

        # Ensure each node is represented in the node array
        push @nodes, { data => { id => $node_id } };

        # Process each value in the row corresponding to an edge, but only in the upper triangle
        # and explicitly skipping diagonal elements
        # Undirected graph - Cytoscape.js settings:
        # "style": [
        #  {
        #  "selector": "edge",
        #  "style": {
        #    "target-arrow-shape": "none"
        #    }
        #  }
        # ]

        for ( my $i = $current_index + 1 ; $i < scalar @headers ; $i++ ) {
            if ( $values[$i] >= $threshold ) {
                push @edges,
                  {
                    data => {
                        source => $node_id,
                        target => $headers[$i],
                        weight => $values[$i]
                    }
                  };
            }
        }

        # Increment the current row index
        $current_index++;
    }

    # Close the matrix file handle
    close $matrix_fh;

    # Assemble the complete graph structure
    my %graph = (
        elements => {
            nodes => \@nodes,
            edges => \@edges,
        }
    );

    # Open a file to write JSON output
    say "Writting <$output> file " if $verbose;
    write_json( { filepath => $output, data => \%graph } );

    return defined $graph_stats ? \%graph : undef;
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

    my @nodes = @{ $json_data->{elements}->{nodes} };
    my @edges = @{ $json_data->{elements}->{edges} };

    # Create a new Graph object
    my $graph = Graph->new( undirected => 1 );

    # Add nodes and edges to the graph
    foreach my $node (@nodes) {
        $graph->add_vertex( $node->{data}->{id} );
    }

    foreach my $edge (@edges) {
        $graph->add_weighted_edge(
            $edge->{data}->{source},
            $edge->{data}->{target},
            $jaccard ? 1 - $edge->{data}->{weight} : $edge->{data}->{weight}
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
    open( my $fh, '>', $output );

    # Basic stats
    print $fh "Metric: ",             ucfirst($metric), "\n";
    print $fh "Number of vertices: ", scalar $g->vertices, "\n";
    print $fh "Number of edges: ",    scalar $g->edges,    "\n";

    # Checking connectivity and components
    print $fh "Is connected: ", $g->is_connected, "\n";
    print $fh "Connected Components: ", scalar $g->connected_components, "\n";

    # Diameter and average path length, check if the graph is connected first
    if ( $g->is_connected ) {
        print $fh "Graph Diameter: ", ( join "->", $g->diameter ), "\n";
        print $fh "Average Path Length: ", $g->average_path_length, "\n";
    }

    # Display degrees of all vertices
    foreach my $v ( $g->vertices ) {
        print $fh "Degree of vertex $v: ", $g->degree($v), "\n";
    }

    # Minimum Spanning Tree
    my $mst = $g->MST_Kruskal;    # Assuming Kruskal's is available and appropriate
    print $fh "MST has ", scalar $mst->edges, " edges\n";

    # Calculate and write all pairs shortest paths and their lengths to the file
    foreach my $u ( $g->vertices ) {
        foreach my $v ( $g->vertices ) {
            if ( $u ne $v ) {
                my @path = $g->SP_Dijkstra( $u, $v );    # Get shortest path using Dijkstra's algorithm
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
