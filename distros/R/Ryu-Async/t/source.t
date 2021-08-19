use strict;
use warnings;

use IO::Async::Loop;
use Ryu::Async;

use Test::More;
use Test::Deep;

my $loop = new_ok('IO::Async::Loop');
my $ryu = new_ok('Ryu::Async');
$loop->add($ryu);

my $src = $ryu->from([qw(x y z)]);
isa_ok($src, 'Ryu::Source');
my @out;
$src->each(sub { push @out, @_ });
cmp_deeply(\@out, [], 'no items to start with');
$loop->loop_once;
cmp_deeply(\@out, ['x'], 'one iteration, one item');
$loop->loop_once;
cmp_deeply(\@out, [qw(x y)], 'iteration yields expected item');
$loop->loop_once;
cmp_deeply(\@out, [qw(x y z)], 'iteration yields expected item');
# We don't check the next item until the loop has had a chance to tick over
$loop->loop_once;
ok($src->completed->is_ready, 'source is marked as finished');

done_testing;

