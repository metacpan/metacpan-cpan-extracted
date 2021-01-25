# NAME

Neo4j::Bolt::ResultStream - Iterator on Neo4j Bolt query response

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");

    $stream = $cxn->run_query(
      "MATCH (a) RETURN labels(a) as lbls, count(a) as ct"
    );
    while ( my @row = $stream->fetch_next ) {
      print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
    }
    # check that the stream emptied cleanly...
    unless ( $stream->success ) {
      print STDERR "Uh oh: ".($stream->client_errmsg || $stream->server_errmsg);
    }

# DESCRIPTION

[Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md) objects are created by a successful query 
performed on a [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md). They are iterated to obtain the rows
of the response as Perl arrays (not arrayrefs).

# METHODS

- fetch\_next()

    Obtain the next row of results as an array. Returns false when done.

- update\_counts()

    If a write query is successful, returns a hashref containing the
    numbers of items created or removed in the query. The keys indicate
    the items, as follows:

        nodes_created
        nodes_deleted
        relationships_created
        relationships_deleted
        properties_set
        labels_added
        labels_removed
        indexes_added
        indexes_removed
        constraints_added
        constraints_removed

    If query is unsuccessful, or the stream is not completely fetched yet,
    returns undef (check ["server\_errmsg()"](#server_errmsg)).

- field\_names()

    Obtain the column names of the response as an array (not arrayref).

- nfields()

    Obtain the number of fields in the response row as an integer.

- success(), failure()

    Use these to check whether fetch\_next() succeeded. They indicate the 
    current error state of the result stream. If 

        $stream->success == $stream->failure == -1

    then the stream has been exhausted.

- client\_errnum()
- client\_errmsg()
- server\_errcode()
- server\_errmsg()

    If `$stream->success` is false, these will indicate what happened.

    If the error occurred within the `libneo4j-client` code,
    `client_errnum()` will provide the `errno` and `client_errmsg()`
    the associated error message. This is a probably a good time to file a
    bug report.

    If the error occurred at the server, `server_errcode()` and
    `server_errmsg()` will contain information sent by the server. In
    particular, Cypher syntax errors will appear here.

- result\_count\_()
- available\_after()
- consumed\_after()

    These are performance numbers that the server provides after the 
    stream has been fetched out. result\_count\_() is the number of rows
    returned, available\_after() is the time in ms it took the server to 
    provide the stream, and consumed\_after() is the time it took the 
    client (you) to pull them all.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019-2021 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
