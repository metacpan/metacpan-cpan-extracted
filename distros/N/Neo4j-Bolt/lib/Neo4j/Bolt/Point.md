# NAME

Neo4j::Bolt::Point - Representation of a Neo4j geographic point structure

# SYNOPSIS

    $q = "RETURN point({latitude:55.944167, longitude:-3.161944});"
    $point = ( $cxn->run_query($q)->fetch_next )[0];

    $srid = $point->{srid};
    $latitude = $point->{y};
    $longitude = $point->{x};
    

# DESCRIPTION

[Neo4j::Bolt::Point](/lib/Neo4j/Bolt/Point.md) instances are created by executing
a Cypher query that returns a location value
from the Neo4j database.
They can also be created locally and passed to Neo4j as
query parameter. See ["Point" in Neo4j::Types::Generic](https://metacpan.org/pod/Neo4j::Types::Generic#Point).

The values in the Bolt structure are described at
[https://neo4j.com/docs/bolt/current/bolt/structure-semantics/](https://neo4j.com/docs/bolt/current/bolt/structure-semantics/). The
Neo4j::Bolt::Point object possesses number values for the keys `x`,
`y`, and `z` (if present), and an integer code for `srid`.

This class conforms to the [Neo4j::Types::Point](https://metacpan.org/pod/Neo4j::Types::Point) API,
which offers an object-oriented interface to the point's
SRID and coordinates. This is entirely optional to use.

# METHODS

This class provides the following methods defined by
[Neo4j::Types::Point](https://metacpan.org/pod/Neo4j::Types::Point):

- [**coordinates()**](https://metacpan.org/pod/Neo4j::Types::Point#coordinates)
- [**srid()**](https://metacpan.org/pod/Neo4j::Types::Point#srid)

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Types::Point](https://metacpan.org/pod/Neo4j::Types::Point)

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN

# LICENSE

This software is Copyright (c) 2024 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
