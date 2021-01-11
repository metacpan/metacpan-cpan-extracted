# NAME

Neo4j::Bolt::TypeHandlersC - Low level Perl to Bolt converters

# SYNOPSIS

    // how Neo4j::Bolt::ResultStream uses it
     for (i=0; i<n; i++) {
       value = neo4j_result_field(result, i);
       perl_value = neo4j_value_to_SV(value);
       Inline_Stack_Push( perl_value );
     }

# DESCRIPTION

[Neo4j::Bolt::TypeHandlersC](/lib/Neo4j/Bolt/TypeHandlersC.md) is all C code, managed by [Inline::C](https://metacpan.org/pod/Inline::C).
It tediously defines methods to convert Perl structures to Bolt
representations, and also tediously defines methods convert Bolt
data to Perl representations.

# METHODS

- neo4j\_value\_t SV\_to\_neo4j\_value(SV \*sv)

    Attempt to create the appropriate
    [libneo4j-client](https://github.com/cleishm/libneo4j-client)
    representation of the Perl SV argument.

- SV\* neo4j\_value\_to\_SV( neo4j\_value\_t value )

    Attempt to create the appropriate Perl SV representation of the
    [libneo4j-client](https://github.com/cleishm/libneo4j-client)
    neo4j\_value\_t argument.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Bolt::NeoValue](/lib/Neo4j/Bolt/NeoValue.md), [Inline::C](https://metacpan.org/pod/Inline::C),
[libneo4j-client API](http://neo4j-client.net/doc/latest/neo4j-client_8h.html).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019-2020 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
