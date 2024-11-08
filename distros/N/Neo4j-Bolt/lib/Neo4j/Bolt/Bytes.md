# NAME

Neo4j::Bolt::Bytes - Representation of a Neo4j byte array

# SYNOPSIS

    # Neo4j::Bolt byte arrays are a blessed reference to
    # a string, the bytes of which represent the array
    
    $string = $bytes->$*;
    
    $bytes = bless \$string, 'Neo4j::Bolt::Bytes';

# DESCRIPTION

[Neo4j::Bolt::Bytes](/lib/Neo4j/Bolt/Bytes.md) instances are created by executing
a Cypher query that returns a Neo4j byte array value
from the Neo4j database.
They can also be created locally and passed to Neo4j as
query parameter. See ["ByteArray" in Neo4j::Types::Generic](https://metacpan.org/pod/Neo4j::Types::Generic#ByteArray).

Neo4j only has limited support for byte arrays. They shouldn't
be used for storing large blobs. Cypher doesn't provide a literal
syntax for creating byte array values. The only regular way to
create them in the database is to send them as a query parameter.
However, database plugin libraries may add functions able
to create them through Cypher statements without the use of
parameters. For example:

    # https://neo4j.com/docs/apoc/5/overview/apoc.util/
    RETURN apoc.util.compress("data", {compression: "NONE"})

Before Neo4j::Bolt version 0.5000, byte arrays were returned
from the database as unblessed strings instead. Accessing
[Neo4j::Bolt::Bytes](/lib/Neo4j/Bolt/Bytes.md) objects as strings is currently still
possible for backwards compatibility, but it issues a
deprecation warning and will likely be removed in a future
version.

This class conforms to the [Neo4j::Types::ByteArray](https://metacpan.org/pod/Neo4j::Types::ByteArray) API,
which offers an object-oriented interface to the underlying
byte string. This is entirely optional to use.

# METHODS

This class provides the following method defined by
[Neo4j::Types::ByteArray](https://metacpan.org/pod/Neo4j::Types::ByteArray):

- [**as\_string()**](https://metacpan.org/pod/Neo4j::Types::ByteArray#as_string)

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Types::ByteArray](https://metacpan.org/pod/Neo4j::Types::ByteArray)

# AUTHOR

    Arne Johannessen
    CPAN: AJNN

# LICENSE

This software is Copyright (c) 2024 by Arne Johannessen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
