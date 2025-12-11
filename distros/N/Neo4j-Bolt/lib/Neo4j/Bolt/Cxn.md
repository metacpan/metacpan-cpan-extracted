# NAME

Neo4j::Bolt::Cxn - Container for a Neo4j Bolt connection

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
    unless ($cxn->connected) {
      die "Problem connecting: ".$cxn->errmsg;
    }
    $stream = $cxn->run_query(
      "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
    );
    if ($stream->failure) {
      print STDERR "Problem with query run: ".
                    ($stream->client_errmsg || $stream->server_errmsg);
    }

# DESCRIPTION

[Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md) is a container for a Bolt connection, instantiated by
a call to `Neo4j::Bolt->connect()`.

# METHODS

- connected()

    True if server connected successfully. If not, see ["errnum()"](#errnum) and
    ["errmsg()"](#errmsg).

- protocol\_version()

    Returns a string representing the major and minor Bolt protocol version of the 
    server, as "&lt;major>.&lt;minor>", or the empty string if not connected.

- run\_query($cypher\_query, \[$param\_hash\], \[$db\_name\])

    Run a [Cypher](https://neo4j.com/docs/cypher-manual/current/) query on
    the server. Returns a [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md) which can be iterated
    to retrieve query results as Perl types and structures. \[$param\_hash\]
    is an optional hashref of the form `{ param => $value, ... }`.
    If `$db_name` is not given, the value of the global variable
    `$Neo4j::Bolt::DEFAULT_DB` will be used instead.

- send\_query($cypher\_query, \[$param\_hash\], \[$db\_name\])

    Send a [Cypher](https://neo4j.com/docs/cypher-manual/current/) query to
    the server. All results (except error info) are discarded.

- do\_query($cypher\_query, \[$param\_hash\], \[$db\_name\])

        ($stream, @rows) = do_query($cypher_query);
        $stream = do_query($cypher_query, $param_hash);

    Run a [Cypher](https://neo4j.com/docs/cypher-manual/current/) query on
    the server, and iterate the stream to retrieve all result
    rows. `do_query` is convenient for running write queries (e.g.,
    `CREATE (a:Bloog {prop1:"blarg"})` ), since it returns the $stream
    with ["update\_counts" in Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream#update_counts.md) ready for reading.

- reset\_cxn()

    Send a RESET message to the Neo4j server. According to the [Bolt
    protocol](https://boltprotocol.org/v1/), this should force any currently
    processing query to abort, forget any pending queries, clear any
    failure state, dispose of outstanding result records, and roll back
    the current transaction.

- errnum(), errmsg()

    Current error state of the connection. If

        $cxn->connected == $cxn->errnum == 0

    then you have a virgin Cxn object that came from someplace other than
    `Neo4j::Bolt->connect()`, which would be weird.

- server\_id()

        print $cxn->server_id;  # "Neo4j/3.3.9"

    Get the server ID string, including the version number. `undef` if
    connecting wasn't successful or the server didn't identify itself.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019-2024 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
