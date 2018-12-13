use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = new_ok('Ryu::Source');
my $buffered = $src->buffer(3);
my $target = $buffered->merge;
my $total = 0;
my $count = $target->count->each(sub { $total = $_ });
my @received;
$target->each(sub { push @received, $_ });
cmp_deeply(\@received, [], 'start with no items');
$src->emit('x');
cmp_deeply(\@received, ['x'], 'have one item');
$target->pause;
$src->emit('y');
cmp_deeply(\@received, ['x'], 'still that one item');
$target->resume;
cmp_deeply(\@received, ['x', 'y'], 'now have the next item');
$src->finish;
is($total, 2, 'have the expected 2 items');
done_testing;


