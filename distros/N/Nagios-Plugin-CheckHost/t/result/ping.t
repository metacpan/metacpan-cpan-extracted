#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Nagios::Plugin::CheckHost::Node;

use_ok 'Nagios::Plugin::CheckHost::Result::Ping';

my $nodes = [
    Nagios::Plugin::CheckHost::Node->new("7f000001", ['be', 'Antwerp']),
    Nagios::Plugin::CheckHost::Node->new("7f000002", ['fr', 'Paris']),
    Nagios::Plugin::CheckHost::Node->new("7f000003", ['it', 'Milan']),
];

my $pingr = new_ok 'Nagios::Plugin::CheckHost::Result::Ping',
  [nodes => $nodes, failed_allowed => 0.5];
is scalar $pingr->nodes, 3;

is $pingr->calc_loss($nodes->[0]), 1, "no result node loss";

$pingr->store_result({
        $nodes->[0]->identifier => [[["OK", 1, "127.0.0.1"], ["OK",      2]]],
        $nodes->[2]->identifier => [[["OK", 1, "127.0.0.1"], ["TIMEOUT", 5]]]
    }
);
is_deeply [$pingr->unfinished_nodes], [$nodes->[1]], "unfinished nodes list";

$pingr->store_result({$nodes->[1]->identifier => [[]]});
is_deeply [$pingr->unfinished_nodes], [], "all nodes got results";

is $pingr->calc_loss($nodes->[0]), 0, "first node loss";
is $pingr->calc_rtt($nodes->[0]), 1.5, "first node avg";

is $pingr->calc_loss($nodes->[1]), 1, "second node loss";
is $pingr->calc_rtt($nodes->[1]), undef, "second node avg";

is $pingr->calc_loss($nodes->[2]), 0.5, "third node loss";
is $pingr->calc_rtt($nodes->[2]), 1, "third node no avg";

done_testing();
