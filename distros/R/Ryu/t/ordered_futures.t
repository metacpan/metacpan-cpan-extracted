
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;
use Future;

my $src = Ryu::Source->new;
my @actual;
$src->ordered_futures->each(sub {
	push @actual, $_;
});
my @f = map Future->new, 0..2;
$src->emit(@f);
$f[$_]->done($_) for 1, 2, 0;
cmp_deeply(\@actual, [ 1,2,0 ], 'ordered_futures operation was performed');
done_testing;

