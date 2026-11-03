# The hand-written spawn graphs (t/sgraph/*.sg): every process gets exactly the fds and pipe contents drawn.
use strict; use warnings; use Test::More;
my $out = qx{$^X t/sgraph/run-graph.pl @{[sort glob 't/sgraph/*.sg']} 2>&1};
like $out, qr/^(\d+) of \1 processes as drawn$/m, 'hand-written graphs' or diag $out;
done_testing;
