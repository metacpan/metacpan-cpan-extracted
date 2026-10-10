use v5.36;
use utf8;
use Test::More;
use lib 'lib';
use Peta::NN::Backend;
use Peta::NN::Model;
use Peta::NN::Parallel qw(in_parallel workers);

plan skip_all => 'Parallel::ForkManager is not installed' if !eval { require Parallel::ForkManager; 1 };

# Work in processes of its own: results come back in order, as plain data,
# and a model crosses from one process to another as its training state.

my @squares = in_parallel(3, map { my $n = $_; sub { { n => $n, square => $n * $n, pid => $$ } } } 1 .. 7);
is_deeply([ map { $_->{square} } @squares ], [ map { $_ * $_ } 1 .. 7 ], 'results come back in the order of the tasks');
ok(!(grep { $_->{pid} == $$ } @squares), 'each task ran in another process');

my @here = in_parallel(1, map { my $n = $_; sub { $$ } } 1 .. 3);
is_deeply(\@here, [ ($$) x 3 ], 'with one worker everything runs here');
is_deeply([ in_parallel(4, sub { [ 1, 2 ] }) ], [ [ 1, 2 ] ], 'and so does a single task');
is_deeply([ in_parallel(2, sub { undef }, sub { 0 }) ], [ undef, 0 ], 'a task may return nothing, or something false');

ok(!eval { in_parallel(2, sub { 1 }, sub { die "no luck\n" }, sub { 3 }); 1 }, 'a task that dies fails the call');
like($@, qr/task 1: no luck/, 'and the call says which task, and why');

{
    local $ENV{PETA_NN_WORKERS};
    is(workers(), 1, 'workers: one unless asked');
    $ENV{PETA_NN_WORKERS} = 4;
    is(workers(), 4, 'workers: what PETA_NN_WORKERS names');
    $ENV{PETA_NN_WORKERS} = 'many';
    ok(!eval { workers(); 1 }, 'workers: anything but a count is refused');
}

# Two models trained in two processes, and the same two trained here.
my @pairs = map { my $n = $_; my $w = join '', map { ('a' .. 'z')[ ($_ * 7 + $n * $_) % 26 ] } 1 .. 5; [ $w, $w . ($w =~ /[aeiou]\z/ ? 'n' : 'en') ] } 1 .. 400;
my $train = sub ($seed) {
    Peta::NN::Model->new(kind => 'edit', window => 3, layers => [ [ embed => 4 ], [ dense => 8 ], 'relu' ], seed => $seed)
                   ->fit(\@pairs, epochs => 3, batch => 16)
};
my @states = in_parallel(2, map { my $seed = $_; sub { $train->($seed)->state } } 1, 2);
for my $seed (1, 2) {
    my $back = Peta::NN::Model->from_state($states[ $seed - 1 ]);
    is_deeply($back->net->weights, $train->($seed)->net->weights, "seed $seed: a model trained in another process has the weights it gets here, to the last bit");
}
ok(!eval { Peta::NN::Model->from_state({ format => 'something else' }); 1 }, 'what is not a training state is refused');

# The graphics card and processes: a device does not cross a fork, so a child
# computes on one of its own, and the parent's goes on working.
SKIP: {
    my $gpu = Peta::NN::Backend::try('gpu') or skip 'no graphics card to compute on in this perl', 3;
    my $double = sub ($backend) { $backend->flat($backend->affine($backend->tensor([ 1, 2, 3, 4 ], 2), $backend->tensor([ 2, 0, 0, 2 ], 2), $backend->tensor([ 0, 0 ], 2))) };
    my $here   = $double->($gpu);
    my @there  = in_parallel(2, map { sub { $double->(Peta::NN::Backend::create('gpu')) } } 1, 2);
    is_deeply(\@there, [ $here, $here ], 'gpu: children of a process that has the card open compute on it too');
    is_deeply($double->($gpu), [ 2, 4, 6, 8 ], 'gpu: and the parent still does afterwards');
    my ($kept) = in_parallel(2, map { sub { Peta::NN::Backend::create('gpu'); eval { $double->($gpu); 1 } ? 'computed' : 'refused' } } 1, 2);
    is($kept, 'computed', 'gpu: a backend object made before the fork works in the child, on the child\'s device');
}

done_testing;
