use v5.36;
use utf8;
use Test::More;
use lib 'lib', 't/lib';
use Peta::NN;
use Peta::NN::Backend;
use Peta::NN::Model;
use Synthetic qw(inflect split_pairs);

# A network that is left the choice of its backend settles it when it is
# trained, by timing a few steps on what this perl and this machine have.
# Which backend wins depends on both, so nothing here says which it has to
# be: only that it is one that is there, that it is the one that was timed
# fastest, and that the timing leaves no trace in what is trained.

my ($pairs) = split_pairs(\&inflect, 600, 10, 23);
my @available = Peta::NN::Backend::available();
my %LAYERS = (kind => 'edit', window => 4, layers => [ [ embed => 6 ], [ dense => 24 ], 'relu' ], seed => 3);
my %TRAIN  = (epochs => 2, batch => 16, lr => 0.01);
diag "backends in this perl: @available";

# --- a run that is not worth asking around for --------------------------------
my $short = Peta::NN::Model->new(%LAYERS, backend => 'auto')->fit($pairs, %TRAIN);
my $first = Peta::NN::Backend::create('auto')->name;
is($short->net->backend, $first, "a short run stays on the backend 'auto' starts on ($first)");
is_deeply([ keys %{ $short->net->settled->{seconds_per_step} } ], [$first], '... and only that one was timed');
is($short->net->settled->{steps}, 2 * 38, '... for the steps the run has: epochs times batches');

# --- a run that is ---------------------------------------------------------------
my $long;
{
    local $Peta::NN::WORTH = 0;      # every run is worth it
    $long = Peta::NN::Model->new(%LAYERS, backend => 'auto')->fit($pairs, %TRAIN);
}
my $settled = $long->net->settled;
my %seconds = %{ $settled->{seconds_per_step} };
my %is_available = map { $_ => 1 } @available;
ok(!grep({ !$is_available{$_} } keys %seconds), 'a long run: only backends that are there were timed (' . join(', ', map { sprintf '%s %.2f ms', $_, 1000 * $seconds{$_} } sort keys %seconds) . ')');
ok($seconds{$first}, '... the one it started on among them');
my ($fastest) = sort { $seconds{$a} <=> $seconds{$b} } keys %seconds;
is($settled->{backend}, $fastest, "... it settled on the one that was timed fastest ($fastest)");
is($long->net->backend, $fastest, '... and that is the backend it is on');

# The timing trains, and puts everything back: the model is the one a network
# on that backend from the start would be, to the last bit.
my $pinned = Peta::NN::Model->new(%LAYERS, backend => $fastest)->fit($pairs, %TRAIN);
is_deeply($long->net->weights, $pinned->net->weights, 'what was timed leaves no trace: the weights are those of a network that was on that backend all along');
is($pinned->net->settled, undef, 'a network whose backend was named settles nothing');

# The same work again is not timed again; other work is.
{
    local $Peta::NN::WORTH = 0;
    my $before = $long->net->settled;
    $long->tune($pairs, %TRAIN);
    is($long->net->settled, $before, 'the same work a second time: the answer stands');
    $long->tune($pairs, %TRAIN, batch => 32);
    isnt($long->net->settled, $before, 'another batch: settled anew');
    is($long->net->settled->{steps}, 2 * 19, '... for the steps it has now');
}

# Too little to time: nothing is settled, and it trains where it is.
my $few = Peta::NN::Model->new(%LAYERS, backend => 'auto')->fit([ @$pairs[ 0 .. 39 ] ], %TRAIN);
is($few->net->settled, undef, 'a handful of samples: not timed at all');
is($few->net->backend, $first, '... and trained where it started');

# A network of numbers, not tokens, and the other loss.
{
    local $Peta::NN::WORTH = 0;
    my $net = Peta::NN->new(input => 2, layers => [ [ dense => 8 ], 'tanh', [ dense => 1 ] ], loss => 'mse', backend => 'auto');
    my @xor = map { [ [ $_ & 1, $_ >> 1 ], [ ($_ & 1) ^ ($_ >> 1) ] ] } map { $_ % 4 } 1 .. 400;
    $net->train(data => \@xor, epochs => 30, batch => 8, lr => 0.05);
    ok($is_available{ $net->settled->{backend} }, 'a network of numbers with the other loss settles too (' . $net->settled->{backend} . ')');
    cmp_ok($net->loss(\@xor) / @xor, '<', 0.05, '... and learns what it is given');
}

done_testing;
