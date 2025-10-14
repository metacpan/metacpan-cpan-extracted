#!/usr/bin/env perl

=head1 DESCRIPTION

Test Resource::Silo::Metadata::DAG in isolation.

=cut

use strict;
use warnings;
use Test::More;

use Resource::Silo::Metadata::DAG;

subtest 'add random edges to the graph' => sub {
    my $graph = Resource::Silo::Metadata::DAG->new;

    $graph->add_edges(['a'] => ['b', 'c', 'd']);
    $graph->add_edges(['b'] => ['c']);
    $graph->add_edges(['d'] => ['e']);

    my $discrepancies = $graph->self_check;
    ok !$discrepancies, "graph is consistent"
        or diag $discrepancies;
    is $graph->size, 5, "5 nodes in the graph";

    is_deeply [ sort $graph->list ], [ qw( a b c d e ) ], "nodes as expected";

    ok $graph->contains('a'), "a in the graph";
    ok $graph->contains('e'), "e in the graph";
    ok !$graph->contains('f'), "f in not in the graph";

    is_deeply [ sort $graph->list_sinks ], [ qw[c e]], "list_sinks";
    is_deeply [ sort $graph->list_predecessors([ 'd', 'e']) ], [qw [a]], "go one step upwards...";
    is_deeply [ sort $graph->list_predecessors([ 'c', 'e']) ], [qw [a b d]], "go one step upwards...";
    is_deeply [ sort $graph->list_predecessors([ 'e' ]) ], [qw [d]], "go one step upwards...";

    subtest "found loop (e->a)" => sub {
        my $loop = $graph->find_loop('e', [ 'a' ], {}) || [];
        is_deeply [ sort @$loop ], [ qw[a d e] ], "loop found (e depends on a)";
    };

    subtest "no loop (e->b)" => sub {
        my $loop = $graph->find_loop('e', [ 'b' ], {}) || [];
        is_deeply [ sort @$loop ], [], "no loop found (e depends on b)";
    };

    subtest "no loop (e->f)" => sub {
        my $loop = $graph->find_loop('e', [ 'f', 'g' ], {}) || [];
        is_deeply [ sort @$loop ], [], "no loop found (e depends on f)";
    };

    $graph->drop_sink_cascade('e');
    is_deeply [ sort $graph->list ], [ qw( a b c ) ], "e now provided, d is also completed";

    ok !$graph->self_check, "graph is consistent"
        or diag $graph->self_check;
};

done_testing;
