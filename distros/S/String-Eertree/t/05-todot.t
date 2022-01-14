#!/usr/bin/perl
use Test2::V0;
plan 1;

use String::Eertree::ToDot;

my $tree = 'String::Eertree::ToDot'->new(string => 'eertree');
is [$tree->to_dot], [split /\n/, << '__DOT__'];
digraph { rankdir = BT;
0 [shape=record, label="0|-1"]
0->0[color=blue]
1 [shape=record, label="1|0"]
1->0[color=blue]
2 [shape=record, label="2|e"]
2->1[color=blue]
3 [shape=record, label="3|ee"]
3->2[color=blue]
4 [shape=record, label="4|r"]
4->1[color=blue]
5 [shape=record, label="5|t"]
5->1[color=blue]
6 [shape=record, label="6|rtr"]
6->4[color=blue]
7 [shape=record, label="7|ertre"]
7->2[color=blue]
8 [shape=record, label="8|eertree"]
8->3[color=blue]
0->2[label=e, constraint=false]
0->4[label=r, constraint=false]
0->5[label=t, constraint=false]
1->3[label=e, constraint=false]
5->6[label=r, constraint=false]
6->7[label=e, constraint=false]
7->8[label=e, constraint=false]
}
__DOT__
