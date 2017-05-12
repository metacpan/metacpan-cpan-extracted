# tests sugar functions exported by TPath::Forester::Ref

use strict;
use warnings;
use Test::More tests => 6;
use TPath::Forester::Ref;

my $ref = {
    a => 'b',
    c => [ 1, { foo => 'bar' } ]
};

my $tree = tfr->wrap($ref);
ok defined $tree, 'wrap wraps a ref';

my $index = tfr->index($tree);
ok defined $index, 'able to index wrapped tree';

my @nodes = tfr->path(q{//*})->dsel($tree);
is @nodes, 6, 'found correct number of nodes using dsel';
is $nodes[1], 'b', 'correct second node from dsel';
is ref $nodes[-2], 'HASH', 'penultimate node from dsel';
is ref $nodes[-4], 'ARRAY', 'proantepenultimate node from dsel';

done_testing();
