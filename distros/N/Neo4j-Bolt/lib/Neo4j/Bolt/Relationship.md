# NAME

Neo4j::Bolt::Relationship - Representation of a Neo4j Relationship

# SYNOPSIS

    $q = 'MATCH ()-[r]-() RETURN r';
    $reln = ( $cxn->run_query($q)->fetch_next )[0];
    
    $reln_id       = $reln->{id};
    $reln_type     = $reln->{type};
    $start_node_id = $reln->{start};
    $end_node_id   = $reln->{end};
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

If a query returns the same relationship twice, two separate
[Neo4j::Bolt::Relationship](/lib/Neo4j/Bolt/Relationship.md) instances will be created.

# METHODS

- as\_simple()

        $simple = $reln->as_simple;
        
        $reln_id       = $simple->{_relationship};
        $reln_type     = $simple->{_type};
        $start_node_id = $simple->{_start};
        $end_node_id   = $simple->{_end};
        $value1        = $simple->{property1};
        $value2        = $simple->{property2};

    Get relationship as a simple hashref in the style of [REST::Neo4p](https://metacpan.org/pod/REST::Neo4p).

    The value of properties named `_relationship`, `_type`, `_start`
    or `_end` will be replaced with the relationship's metadata.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md)

# AUTHOR

    Arne Johannessen
    CPAN: AJNN

# LICENSE

This software is Copyright (c) 2020 by Arne Johannessen

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
