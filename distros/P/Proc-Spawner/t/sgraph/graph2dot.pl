#!/usr/bin/perl
# graph2dot.pl FILE.sg > FILE.dot -- draw a spawn graph written in the notation of item N7
# (the grammar is in lib/Proc/Spawner/Graph.pm, section "the notation").  EXPERIMENTAL.
use strict; use warnings;
use FindBin; use lib map "$FindBin::Bin/../../$_", 'lib', 'blib/arch';
use Proc::Spawner::Graph;
print Proc::Spawner::Graph::to_dot(Proc::Spawner::Graph::parse(do { local $/; <> }));
