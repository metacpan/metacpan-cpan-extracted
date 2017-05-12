use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = Ryu::Source->new;
my @actual;
$src->with_index->each(sub {
	push @actual, $_;
});
$src->emit($_) for qw(x y z);
cmp_deeply(\@actual, [
    [ x => 0 ],
    [ y => 1 ],
    [ z => 2 ]
], 'with_index operation was performed');
done_testing;

