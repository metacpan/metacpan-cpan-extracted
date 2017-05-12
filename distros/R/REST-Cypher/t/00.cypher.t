#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;

use FindBin::libs;
use Try::Tiny;

use REST::Cypher;

my $rc;
lives_ok {
    $rc = REST::Cypher->new;
} 'created new REST::Cypher instance';

is(
    $rc->server,
    'localhost',
    "'server' defaults to 'localhost'"
);

is(
    $rc->server_port,
    7474,
    "'server_port' defaults to '7474'"
);

is(
    $rc->rest_base_url,
    'http://localhost:7474',
    "'rest_base_url' default value is 'http://localhost:7474'",
);

# this should (currently) fail, as the response succeeds even though we can't
# actually reach the server
dies_ok {
    # use a server that we definitely can't have running, otherwise this test
    # fails when someone really is running a local neo4j
    $rc->server('example.com');
    $rc->query(
        query_string => 'MATCH (n:Foo) RETURN count(n)',
    );
} '->query call fails (unknown server: http://localhost:7474)';


# XXX archdev
$rc = REST::Cypher->new( server => 'some.other.server' );
is(
    $rc->rest_base_url,
    'http://some.other.server:7474',
    "'rest_base_url' default value is 'http://some.other.server:7474'",
);

# this should NOT live ... we don't have a sensible server to connect to
dies_ok {
    $rc->query({
        query_string => 'MATCH (n:Foo) RETURN count(n)',
    });
} '->query call fails (unknown server: http://some.other.server:7474)';


# this SHOULD live ... we catch the exception and see if it looks sensible,
# but don't die.
lives_ok {

    my $response;
    try {
        $response = $rc->query({
            query_string => 'MATCH (n:Foo) RETURN count(n)',
        });
    }
    catch {
        use Data::Dump 'pp';
        warn "caught error: " . pp($_); # not $@
    }

} '->query call survives with try/catch (unknown server: http://some.other.server:7474)';

done_testing;
