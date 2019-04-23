use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = Ryu::Source->new;
my $batched = $src->batch(4);
my @recv;
$batched->each(sub { push @recv, $_ });
$src->emit($_) for qw(x y z);
cmp_deeply(\@recv, [], 'no items yet');
$src->emit($_) for qw(a);
cmp_deeply([ splice @recv ], [ [ qw(x y z a) ] ], 'received items');
$src->finish;
cmp_deeply([ splice @recv ], [ ], 'no trailing items');
ok($batched->is_ready, 'Future was completed') or die "something wrong";
done_testing;

