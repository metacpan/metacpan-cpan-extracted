# NAME

Neo4j::Bolt::Path - Representation of a Neo4j Path

# SYNOPSIS

    $q = 'MATCH p=(n1)-[r]->(n2) RETURN p';
    $path = ( $cxn->run_query($q)->fetch_next )[0];
    
    ($n1, $r, $n2) = @$path;
    
    @nodes         = grep { ref eq 'Neo4j::Bolt::Node' } @$path;
    @relationships = grep { ref eq 'Neo4j::Bolt::Relationship' } @$path;
    
    $start_node = $path->[0];
    $end_node   = $path->[@$path - 1];
    $length     = @$path >> 1;  # number of relationships
    
    $arrayref = $path->as_simple;

# DESCRIPTION

[Neo4j::Bolt::Path](/lib/Neo4j/Bolt/Path.md) instances are created by executing
a Cypher query that returns paths from a Neo4j database.
Their nodes, relationships and metadata can be accessed
as shown in the synopsis above.

This class conforms to the [Neo4j::Types::Path](https://metacpan.org/pod/Neo4j::Types::Path) API, which
offers an object-oriented interface to the paths's
elements and metadata. This is entirely optional to use.

If a query returns the same path twice, two separate
[Neo4j::Bolt::Path](/lib/Neo4j/Bolt/Path.md) instances will be created.

# METHODS

This class provides the following methods defined by
[Neo4j::Types::Path](https://metacpan.org/pod/Neo4j::Types::Path):

- [**elements()**](https://metacpan.org/pod/Neo4j::Types::Path#elements)
- [**nodes()**](https://metacpan.org/pod/Neo4j::Types::Path#nodes)
- [**relationships()**](https://metacpan.org/pod/Neo4j::Types::Path#relationships)

The following additional method is provided:

- as\_simple()

        $simple  = $path->as_simple;

    Get path as a simple arrayref in the style of [REST::Neo4p](https://metacpan.org/pod/REST::Neo4p).

    The simple arrayref is unblessed, but is otherwise an exact duplicate
    of the [Neo4j::Bolt::Path](/lib/Neo4j/Bolt/Path.md) instance.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Types::Path](https://metacpan.org/pod/Neo4j::Types::Path)

# AUTHOR

    Arne Johannessen
    CPAN: AJNN

# LICENSE

This software is Copyright (c) 2020-2024 by Arne Johannessen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
