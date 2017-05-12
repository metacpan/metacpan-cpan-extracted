#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Nagios::Plugin::CheckHost::Node;

use_ok 'Nagios::Plugin::CheckHost::Result::Http';

my $nodes = [
    Nagios::Plugin::CheckHost::Node->new("7f000001", ['be', 'Antwerp']),
    Nagios::Plugin::CheckHost::Node->new("7f000002", ['fr', 'Paris']),
    Nagios::Plugin::CheckHost::Node->new("7f000003", ['it', 'Milan']),
];

my $httpr = new_ok 'Nagios::Plugin::CheckHost::Result::Http',
  [nodes => $nodes];
is scalar $httpr->nodes, 3;

$httpr->store_result({
        $nodes->[0]->identifier => [[1, 0.13, "OK", "200", "94.242.206.94"]],
        $nodes->[2]->identifier => [[0, 0.17, "Not Found", "404", "94.242.206.94"]]
    }
);
is_deeply [$httpr->unfinished_nodes], [$nodes->[1]], "unfinished nodes list";

$httpr->store_result({$nodes->[1]->identifier => [[0, 0.07, "No such device or address", undef, undef]]});
is_deeply [$httpr->unfinished_nodes], [], "all nodes got results";

ok $httpr->request_ok($nodes->[0]), "first node status";
ok not($httpr->request_ok($nodes->[1])), "second node status";
ok not($httpr->request_ok($nodes->[2])), "third node status";

is $httpr->request_time($nodes->[0]), 0.13, "first node request time";
is $httpr->request_time($nodes->[1]), 0.07, "second node request time";
is $httpr->request_time($nodes->[2]), 0.17, "third node request time";

done_testing();
