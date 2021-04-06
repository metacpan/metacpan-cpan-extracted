use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my $second = Ryu::Source->new;
my @actual;
my $merged = Ryu::Source->new->each(sub {
    push @actual, $_;
});
$merged->emit_from(
    $first,
    $second
);
$first->emit(1);
$second->emit(2);
$first->emit(3);
$first->emit(4);
$second->emit(5);
$first->finish;
$second->finish;
cmp_deeply(\@actual, [ 1..5 ], 'merge operation was performed');
done_testing;

