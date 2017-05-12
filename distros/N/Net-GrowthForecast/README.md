# NAME

Net::GrowthForecast - A client library for awesome visualization tool GrowthForecast

# SYNOPSIS

    use Net::GrowthForecast;

    my $gf = Net::GrowthForecast->new( host => 'localhost', port => 5125 );

    $gf->post( 'serviceName', 'sectionName', 'graphName', $update_value );

    $gf->graphs();   #=> arrayref of hashref
    $gf->complexes();
    $gf->all();

    $gf->graph( $graph_id );   # hashref
    $gf->complex( $complex_id );
    $gf->by_name( $service_name, $section_name, $graph_name );

    my $graph = $gf->all()->[0];
    $graph->{description} = 'update description of your graph';
    $gf->edit($graph);

    my $spec = $gf->all()->[0];
    $graph->{graph_name} = 'copy_of_' . $graph->{graph_name};
    $gf->add($graph);

    my $graph = pop @{ $gf->all() };
    $gf->delete($graph);

# DESCRIPTION

Net::GrowthForecast is a client library for GrowthForecast JSON API. This supports GET/LIST/EDIT/ADD/REMOVE simple graphs and complex graphs.

USE GrowthForecast v0.33 or later

# METHODS

- my $gf = Net::GrowthForecast->new( %opts )

    Create client instance for growhtforecast. All options are optional.

    host: Your growthforecast hostname as string (default: 'localhost')

    port: Port number (default: 5125)

    prefix: URI path prefix string if you use reverse-proxy and mounts growthforecast on sub directory. (default: none)

    timeout: HTTP timeout seconds (default: 30)

    debug: Debug mode for HTTP request/response (default: false)

- $gf->post( $service, $section, $name, $value, %opts )

    Update graph (specified by service, section, name) number value as $value. %opts (optional) are:

    mode: 'gauge', 'count', 'modified', or 'derive' (default: 'gauge')

    color: update graph color like '\#FF8800' (default: not changed, or random (when creation))

- $gf->graphs()

    Return arrayref of hashref, includes list of basic graph, like:

        [ { id => 1, service_name => '...', section_name => '...', graph_name => '...' }, { id => 2, ... }, ... ]

- $gf->complexes()

    Return arrayref of hashref, includes list of complex graph, like:

        [ { id => 1, service_name => '...', section_name => '...', graph_name => '...' }, { id => 2, ... }, ... ]

    You should take care that 'id' of complex graph and basic graph is not unique - basic graph id '1' and complex graph id '1' may also exists at the same time. 'service/section/graph' name is unique key of graphs.

- $gf->graph( $graph\_id )

    Return graph detail as hashref like:

        {
          id => 13,
          

          service_name => 'example',
          section_name => 'test',
          graph_name   => 'sample1',
          

          complex => 0,
          

          description => '',
          mode    => 'gauge',
          sort    => 0,
          color   => '#ff0000',
          gmode   => 'gauge',
          type    => 'LINE2',
          ulimit  => 1000000000,
          llimit  => -1000000000,
          stype   => 'AREA',
          sulimit => 100000,
          sllimit => -100000,
          adjust  => '*',
          adjustval => 1,
          unit    => '',
          

          number  => 0,
          data    => [],
          created_at => '2012/12/31 10:57:46',
          updated_at => '2012/12/31 10:57:46'
        }

- $gf->complex( $complex\_id )

    Return graph detail as hashref like:

        {
          id => 2,
          

          section_name => 'test',
          service_name => 'example',
          graph_name   => 'sample2',
          

          complex  => 1,
          

          data => [
                    {
                      gmode    => 'gauge',
                      graph_id => 1,
                      stack    => \0,
                      type     => 'LINE1'
                    },
                    {
                      gmode    => 'gauge',
                      graph_id => 45,
                      stack    => 1,
                      type     => 'LINE1'
                    },
                    {
                      gmode    => 'gauge',
                      graph_id => 46,
                      stack    => 1,
                      type     => 'LINE1'
                    }
                  ],
          

          description => 'testing now',
          sort  => 19,
          sumup => 1,
          

          number => 0,
          created_at => '2012/12/31 11:32:22',
          updated_at => '2012/12/31 11:32:22'
        }

- $gf->all()

    Returns arrayref of both detail basic graph hashref and detail complex graph hashref.

- $gf->tree()

    Returns hashref, contains serice - section - graph\_name as directory tree, for both of graph and complex. Value of $tree->{$service}->{$section}->{$graph\_name} is detail graph infomation.

- $gf->by\_name( $service, $section, $graph\_name )

    Returns detail graph info for complex or not. (Relatively heavy: you should use cached $gf->tree() result for many queries)

- $gf->edit( $graph || $complex )

    Update graph data with specified object's values. Returns success or not.

- $gf->delete( $graph || $complex )

    Delete graph data with specified object's id. Returns success or not.

- $gf->add( $spec )

    Add graph or complex graph, with specified detail graph object's spec. 'id' is ignored if exits. Request will fail with non-unique'service/section/graph' values.

    Returns success or not.

- $gf->add\_graph( $service, $section, $graph\_name, $init\_value \[, $color, $mode\] )

    Add basic graph with specified service/section/name and value. 'color' and 'mode' are optional.

    mode: You should specify $mode at graph creation if you want 'derive' graph.

    Returns success or not.

- $gf->add\_complex( $service, $section, $graph\_name, $description, $sumup, $sort, $type, $gmode, $stack, @data\_graph\_ids )

    Add complex graph with specified options. All arguments are reequired, and type/gmode/stack will used for all sub data graphs. Returns success or not.

# AUTHOR

tagomoris (TAGOMORI Satoshi) <tagomoris {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modifyit under the same terms as Perl itself.
