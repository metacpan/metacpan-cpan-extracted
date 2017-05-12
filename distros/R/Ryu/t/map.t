use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = Ryu::Source->new;
my @actual;
$src->map(sub { 2 * $_ })->each(sub {
	push @actual, $_;
});
$src->emit(1..3);
cmp_deeply(\@actual, [ map 2 * $_, 1..3 ], 'map operation was performed');
done_testing;

