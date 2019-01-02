use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->every(sub { $_ > 5 })->each(sub {
    push @actual, $_;
});
$first->emit($_) for 6,8,9,10,5.1;
$first->finish;
cmp_deeply(\@actual, [ 1 ], 'every operation was performed');
done_testing;

