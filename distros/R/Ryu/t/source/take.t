use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my @actual;
$first->take(2)->each(sub {
    push @actual, $_;
});
$first->emit($_) for 'a'..'z';
cmp_deeply(\@actual, [ qw(a b) ], 'take operation was performed');
done_testing;

