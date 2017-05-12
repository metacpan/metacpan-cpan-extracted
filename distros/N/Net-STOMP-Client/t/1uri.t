#!perl

use strict;
use warnings;
use Net::STOMP::Client::Connection qw();
use Test::More tests => 12;

sub test ($$) {
    my($ok, $uri) = @_;

    eval { Net::STOMP::Client::Connection::_parse_uri($uri) };
    if ($ok) {
        ok(!$@, "parse_uri(\"$uri\")");
    } else {
        ok($@, "parse_uri(\"$uri\")");
    }
}

test(0, ""); # empty
test(1, "stomp://foo-bar.com:123");
test(1, "tcp://foo:123");
test(1, "ssl://foo:123");
test(1, "stomp://foo:123");
test(1, "stomp+ssl://foo:123");
test(0, "stmp://foo:123"); # bad scheme
test(0, "stomp://foo;123"); # typo
test(1, "failover:tcp://foo:123,ssl://bar:123");
test(1, "failover:(tcp://foo:123,ssl://bar:123)");
test(1, "failover://(tcp://foo:123,ssl://bar:123)");
test(1, "failover://(tcp://appint:61613,tcp://appext:61613)?" .
        "randomize=false&maxReconnectAttempts=3&initialReconnectDelay=3000");
