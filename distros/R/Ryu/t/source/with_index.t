use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = Ryu::Source->new;
my @actual;
my $with_index = $src->with_index->each(sub {
    push @actual, $_;
});
$src->emit($_) for qw(x y z);
cmp_deeply(\@actual, [
    [ x => 0 ],
    [ y => 1 ],
    [ z => 2 ]
], 'with_index operation was performed');
ok(!$with_index->completed->is_ready, 'child source still active');
$src->finish;
ok($with_index->completed->is_done, 'child source now complete');
done_testing;

