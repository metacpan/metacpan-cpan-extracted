# NAME

Neo4j::Bolt - query Neo4j using Bolt protocol

[![Build Status](https://github.com/majensen/perlbolt/actions/workflows/tests.yaml/badge.svg)](https://github.com/majensen/perlbolt/actions/workflows/tests.yaml)

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

The Alien module [Neo4j::Client](https://metacpan.org/pod/Neo4j::Client) provides the library. A Perl warning
in the `Neo4j::Bolt` category is emitted at load time if an outdated
library version is detected.

## Return Types

[Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md) returns rows resulting from queries made 
via a [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md). These rows are simple arrays of scalars and/or
references. These represent Neo4j types according to the following:

    Neo4j type       Perl representation
    ----- ----       ---- --------------
    Null             undef
    Bool             Perl core bool (v5.36+) or JSON::PP::Boolean
    Int              scalar
    Float            scalar
    String           scalar
    Bytes            scalarref (Neo4j::Bolt::Bytes)
    DateTime         hashref   (Neo4j::Bolt::DateTime)
    Duration         hashref   (Neo4j::Bolt::Duration)
    Point            hashref   (Neo4j::Bolt::Point)
    List             arrayref
    Map              hashref
    Node             hashref   (Neo4j::Bolt::Node)
    Relationship     hashref   (Neo4j::Bolt::Relationship)
    Path             arrayref  (Neo4j::Bolt::Path)

[Nodes](/lib/Neo4j/Bolt/Node.md), [Relationships](/lib/Neo4j/Bolt/Relationship.md) and
[Paths](/lib/Neo4j/Bolt/Path.md) are represented in the following formats:

    # Node:
    bless {
      id => $node_id,  element_id => $node_eid,
      labels => [$label1, $label2, ...],
      properties => {prop1 => $value1, prop2 => $value2, ...}
    }, 'Neo4j::Bolt::Node'

    # Relationship:
    bless {
      id    => $reln_id,        element_id       => $reln_eid,
      start => $start_node_id,  start_element_id => $start_node_eid,
      end   => $end_node_id,    end_element_id   => $end_node_eid,
      type  => $reln_type,
      properties => {prop1 => $value1, prop2 => $value2, ...}
    }, 'Neo4j::Bolt::Relationship'

    # Path:
    bless [
      $node1, $reln12, $node2, $reln23, $node3, ...
    ], 'Neo4j::Bolt::Path'

For further details, see the individual modules:

- [Neo4j::Bolt::Bytes](/lib/Neo4j/Bolt/Bytes.md)
- [Neo4j::Bolt::DateTime](/lib/Neo4j/Bolt/DateTime.md)
- [Neo4j::Bolt::Duration](/lib/Neo4j/Bolt/Duration.md)
- [Neo4j::Bolt::Node](/lib/Neo4j/Bolt/Node.md)
- [Neo4j::Bolt::Path](/lib/Neo4j/Bolt/Path.md)
- [Neo4j::Bolt::Point](/lib/Neo4j/Bolt/Point.md)
- [Neo4j::Bolt::Relationship](/lib/Neo4j/Bolt/Relationship.md)

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

[Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md), [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md), [Neo4j::Types](https://metacpan.org/pod/Neo4j::Types).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# CONTRIBUTORS

- Arne Johannessen ([AJNN](https://metacpan.org/author/AJNN))

# LICENSE

This software is Copyright (c) 2019-2024 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
