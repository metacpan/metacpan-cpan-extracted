# NAME

Neo4j::Bolt::Node - Representation of a Neo4j Node

# SYNOPSIS

    $q = 'MATCH (n) RETURN n';
    $node = ( $cxn->run_query($q)->fetch_next )[0];
    
    $node_id    = $node->{id};
    $labels     = $node->{labels} // [];
    @labels     = @$labels;
    $properties = $node->{properties} // {};
    %properties = %$properties;
    
    $value1 = $node->{properties}->{property1};
    $value2 = $node->{properties}->{property2};
    
    $hashref = $node->as_simple;

# DESCRIPTION

[Neo4j::Bolt::Node](/lib/Neo4j/Bolt/Node.md) instances are created by executing
a Cypher query that returns nodes from a Neo4j database.
Their properties and metadata can be accessed as shown in the
synopsis above.

If a query returns the same node twice, two separate
[Neo4j::Bolt::Node](/lib/Neo4j/Bolt/Node.md) instances will be created.

# METHODS

- as\_simple()

        $simple  = $node->as_simple;
        
        $node_id = $simple->{_node};
        @labels  = @{ $simple->{_labels} };
        $value1  = $simple->{property1};
        $value2  = $simple->{property2};

    Get node as a simple hashref in the style of [REST::Neo4p](https://metacpan.org/pod/REST::Neo4p).

    The value of properties named `_node` or `_labels` will be
    replaced with the node's metadata.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md)

# AUTHOR

    Arne Johannessen
    CPAN: AJNN

# LICENSE

This software is Copyright (c) 2019-2020 by Arne Johannessen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
