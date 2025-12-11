# NAME

Neo4j::Bolt::Node - Representation of a Neo4j Node

# SYNOPSIS

    $q = 'MATCH (n) RETURN n';
    $node = ( $cxn->run_query($q)->fetch_next )[0];
    
    $node_id    = $node->{id};
    $node_eltid = $node->{element_id};
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

This class conforms to the [Neo4j::Types::Node](https://metacpan.org/pod/Neo4j::Types::Node) API, which
offers an object-oriented interface to the node's
properties and metadata. This is entirely optional to use.

If a query returns the same node twice, two separate
[Neo4j::Bolt::Node](/lib/Neo4j/Bolt/Node.md) instances will be created.

# METHODS

This class provides the following methods defined by
[Neo4j::Types::Node](https://metacpan.org/pod/Neo4j::Types::Node):

- [**element\_id()**](https://metacpan.org/pod/Neo4j::Types::Node#element_id)
- [**get()**](https://metacpan.org/pod/Neo4j::Types::Node#get)
- [**id()**](https://metacpan.org/pod/Neo4j::Types::Node#id)
- [**labels()**](https://metacpan.org/pod/Neo4j::Types::Node#labels)
- [**properties()**](https://metacpan.org/pod/Neo4j::Types::Node#properties)

The following additional method is provided:

- as\_simple()

        $simple  = $node->as_simple;
        
        $node_id = $simple->{_node};
        $eid     = $simple->{_element_id};
        @labels  = @{ $simple->{_labels} };
        $value1  = $simple->{property1};
        $value2  = $simple->{property2};

    Get node as a simple hashref in the style of [REST::Neo4p](https://metacpan.org/pod/REST::Neo4p).

    The value of properties named `_node`, `_element_id`, or
    `_labels` will be replaced with the node's metadata.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Types::Node](https://metacpan.org/pod/Neo4j::Types::Node)

# AUTHOR

    Arne Johannessen
    CPAN: AJNN

# LICENSE

This software is Copyright (c) 2019-2024 by Arne Johannessen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
