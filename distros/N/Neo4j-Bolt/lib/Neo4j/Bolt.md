# NAME

Neo4j::Bolt - query Neo4j using Bolt protocol

[![Build Status](https://travis-ci.org/majensen/perlbolt.svg?branch=master)](https://travis-ci.org/majensen/perlbolt)

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
    $stream = $cxn->run_query(
      "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
      {} # parameter hash required
    );
    @names = $stream->field_names;
    while ( my @row = $stream->fetch_next ) {
      print "For label '$row[0]' there are $row[1] nodes.\n";
    }
    $stream = $cxn->run_query(
      "MATCH (a) RETURN labels(a) as lbls, count(a) as ct",
      {} # parameter hash required
    );
    while ( my @row = $stream->fetch_next ) {
      print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
    }

# DESCRIPTION

[Neo4j::Bolt](/lib/Neo4j/Bolt.md) is a Perl wrapper around Chris Leishmann's excellent
[libneo4j-client](https://github.com/cleishm/libneo4j-client) library
implementing the Neo4j [Bolt](https://boltprotocol.org/) network
protocol. It uses Ingy's [Inline::C](https://metacpan.org/pod/Inline::C) to do all the hard XS work.

## Return Types

[Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md) returns rows resulting from queries made 
via a [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md). These rows are simple arrays of scalars and/or
references. These represent Neo4j types according to the following:

    Neo4j type       Perl representation
    ----- ----       ---- --------------
    Null             undef
    Bool             JSON::PP::Boolean (acts like 0 or 1)
    Int              scalar
    Float            scalar
    String           scalar
    Bytes            scalar
    List             arrayref
    Map              hashref
    Node             hashref  (Neo4j::Bolt::Node)
    Relationship     hashref  (Neo4j::Bolt::Relationship)
    Path             arrayref (Neo4j::Bolt::Path)

[Nodes](/lib/Neo4j/Bolt/Node.md), [Relationships](/lib/Neo4j/Bolt/Relationship.md) and
[Paths](/lib/Neo4j/Bolt/Path.md) are represented in the following formats:

    # Node:
    bless {
      id => $node_id,  labels => [$label1, $label2, ...],
      properties => {prop1 => $value1, prop2 => $value2, ...}
    }, 'Neo4j::Bolt::Node'

    # Relationship:
    bless {
      id => $reln_id,  type => $reln_type,
      start => $start_node_id,  end => $end_node_id,
      properties => {prop1 => $value1, prop2 => $value2, ...}
    }, 'Neo4j::Bolt::Relationship'

    # Path:
    bless [
      $node1, $reln12, $node2, $reln23, $node3, ...
    ], 'Neo4j::Bolt::Path'

# METHODS

- connect($url), connect\_tls($url,$tls\_hash)

    Class method, connect to Neo4j server. The URL scheme must be `'bolt'`, as in

        $url = 'bolt://localhost:7687';

    Returns object of type [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md), which accepts Cypher queries and
    returns a [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md).

    To connect by SSL/TLS, use connect\_tls, with a hashref with keys as follows

        ca_dir => <path/to/dir/of/CAs
        ca_file => <path/to/file/of/CAs
        pk_file => <path/to/private/key.pm
        pk_pass => <private/key.pm passphrase>

    Example:

        $cxn = Neo4j::Bolt->connect_tls('bolt://all-the-young-dudes.us:7687', { ca_cert => '/etc/ssl/cert.pem' });

    When neither `ca_dir` nor `ca_file` are specified, an attempt will
    be made to use the default trust store instead.
    This requires [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) or [Mozilla::CA](https://metacpan.org/pod/Mozilla::CA) to be installed.

- set\_log\_level($LEVEL)

    When $LEVEL is set to one of the strings `ERROR WARN INFO DEBUG` or `TRACE`,
    libneo4j-client native logger will emit log messages at or above the given
    level, on STDERR.

    Set to `NONE` to turn off completely (the default).

# SEE ALSO

[Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md), [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# CONTRIBUTORS

- Arne Johannessen (@johannessen)

# LICENSE

This software is Copyright (c) 2019-2021 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
