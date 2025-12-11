# NAME

Neo4j::Bolt::Txn - Container for a Neo4j Bolt explicit transaction

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
    unless ($cxn->connected) {
      print STDERR "Problem connecting: ".$cxn->errmsg;
    }
    $txn = Neo4j::Bolt::Txn->new($cxn);
    $stream = $txn->run_query(
      "CREATE (a:booga {this:'that'}) RETURN a;"
    );
    if ($stream->failure) {
      print STDERR "Problem with query run: ".
                    ($stream->client_errmsg || $stream->server_errmsg);
      $txn->rollback;
    }
    else {
      $txn->commit;
    }

# DESCRIPTION

[Neo4j::Bolt::Txn](/lib/Neo4j/Bolt/Txn.md) is a container for a Bolt explicit transaction, a feature
available in Bolt versions 3.0 and greater.

# METHODS

- new()

    Create (begin) a new transaction. Execute within the transaction with run\_query(), send\_query(), do\_query().

- commit()

    Commit the changes staged by execution in the transaction.

- rollback()

    Rollback all changes.

- run\_query(), send\_query(), do\_query()

    Completely analogous to same functions in [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019-2024 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
