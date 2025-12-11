# NAME

Neo4j::Bolt::Relationship - Representation of a Neo4j Relationship

# SYNOPSIS

    $q = 'MATCH ()-[r]-() RETURN r';
    $reln = ( $cxn->run_query($q)->fetch_next )[0];
    
    $reln_id       = $reln->{id};
    $reln_eltid    = $reln->{element_id};
    $reln_type     = $reln->{type};
    $start_node_id = $reln->{start};
    $start_node_el = $reln->{start_element_id};
    $end_node_id   = $reln->{end};
    $end_node_el   = $reln->{end_element_id};
    $properties    = $reln->{properties} // {};
    %properties    = %$properties;
    
    $value1 = $reln->{properties}->{property1};
    $value2 = $reln->{properties}->{property2};
    
    $hashref = $reln->as_simple;

# DESCRIPTION

[Neo4j::Bolt::Relationship](/lib/Neo4j/Bolt/Relationship.md) instances are created by executing
a Cypher query that returns relationships from a Neo4j database.
Their properties and metadata can be accessed as shown in the
synopsis above.

This class conforms to the [Neo4j::Types::Relationship](https://metacpan.org/pod/Neo4j::Types::Relationship) API, which
offers an object-oriented interface to the relationship's
properties and metadata. This is entirely optional to use.

If a query returns the same relationship twice, two separate
[Neo4j::Bolt::Relationship](/lib/Neo4j/Bolt/Relationship.md) instances will be created.

# METHODS

This class provides the following methods defined by
[Neo4j::Types::Relationship](https://metacpan.org/pod/Neo4j::Types::Relationship):

- [**element\_id()**](https://metacpan.org/pod/Neo4j::Types::Relationship#element_id)
- [**get()**](https://metacpan.org/pod/Neo4j::Types::Relationship#get)
- [**id()**](https://metacpan.org/pod/Neo4j::Types::Relationship#id)
- [**properties()**](https://metacpan.org/pod/Neo4j::Types::Relationship#properties)
- [**start\_element\_id()**](https://metacpan.org/pod/Neo4j::Types::Relationship#start_element_id)
- [**start\_id()**](https://metacpan.org/pod/Neo4j::Types::Relationship#start_id)
- [**end\_element\_id()**](https://metacpan.org/pod/Neo4j::Types::Relationship#end_element_id)
- [**end\_id()**](https://metacpan.org/pod/Neo4j::Types::Relationship#end_id)
- [**type()**](https://metacpan.org/pod/Neo4j::Types::Relationship#type)

The following additional method is provided:

- as\_simple()

        $simple = $reln->as_simple;
        
        $reln_id       = $simple->{_relationship};
        $reln_el       = $simple->{_element_id};
        $reln_type     = $simple->{_type};
        $start_node_id = $simple->{_start};
        $start_node_el = $simple->{_start_element_id};
        $end_node_id   = $simple->{_end};
        $end_node_el   = $simple->{_end_element_id};
        $value1        = $simple->{property1};
        $value2        = $simple->{property2};

    Get relationship as a simple hashref in the style of [REST::Neo4p](https://metacpan.org/pod/REST::Neo4p).

    The value of properties named `_relationship`, `_element_id`,
    `_type`, `_start`, `_start_element_id`, `_end`, or
    `_end_element_id` will be replaced with the relationship's metadata.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Types::Relationship](https://metacpan.org/pod/Neo4j::Types::Relationship)

# AUTHOR

    Arne Johannessen
    CPAN: AJNN

# LICENSE

This software is Copyright (c) 2020-2024 by Arne Johannessen

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
