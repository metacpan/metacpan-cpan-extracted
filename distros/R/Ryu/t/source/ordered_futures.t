
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;
use Future;

# Ignore failures here
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import('TAP');
};
my $src = Ryu::Source->new;
my @actual;
my $ordered = $src->ordered_futures->each(sub {
    push @actual, $_;
});
my @f = map Future->new, 0..2;
$src->emit(@f);
ok(!$ordered->completed->is_ready, 'ordered futures not yet complete');
$f[$_]->done($_) for 1, 2;
ok(!$ordered->completed->is_ready, 'ordered futures still not complete');
$src->finish;
ok(!$ordered->completed->is_ready, 'ordered futures still not complete');
$f[0]->done(0);
ok($ordered->completed->is_done, 'ordered futures complete after all Futures resolved');
cmp_deeply(\@actual, [ 1,2,0 ], 'ordered_futures operation was performed');

subtest 'handle failed Future in source' => sub {
    my $src = Ryu::Source->new;
    my $ordered = $src->ordered_futures;
    my @f = map Future->new, 0..2;
    $src->emit(@f);
    ok(!$ordered->completed->is_ready, 'ordered futures not yet complete');
    $f[0]->fail('mark as failed');
    ok($ordered->completed->is_failed, 'ordered futures marked as failed');
    ok($src->completed->is_cancelled, 'source is cancelled');
    ok($_->is_cancelled, 'pending items are cancelled') for @f[1, 2];
    done_testing;
};

subtest 'backpressure for Futures' => sub {
    my $src = Ryu::Source->new;
    my $ordered = $src->ordered_futures(
        low  => 2,
        high => 5
    );
    my @f = map { my $f = Future->new; $src->emit($f); $f } 0..2;
    ok(!$ordered->is_paused, 'not paused yet');
    push @f, map { my $f = Future->new; $src->emit($f); $f } 1..2;
    ok($ordered->is_paused, 'now paused');
    shift(@f)->done;
    ok($ordered->is_paused, 'still paused');
    shift(@f)->done for 1..3;
    ok(!$ordered->is_paused, 'no longer paused');
    done_testing;
};

subtest 'failure propagation' => sub {
    my $src = Ryu::Source->new;
    my $ordered = $src->ordered_futures;
    $src->emit(my $f = Future->new);
    $src->fail('example error');
    ok(!$ordered->completed->is_ready, 'still pending on original failure');
    $f->done(1);
    ok($ordered->completed->is_ready, 'now ready');
    is($ordered->completed->failure, 'example error', 'propagated correct error');
};

subtest 'immediate failure propagation' => sub {
    my $src = Ryu::Source->new;
    my $ordered = $src->ordered_futures;
    $src->emit(my $f = Future->new);
    # after this, should have nothing pending!
    $f->done;
    $src->fail('example error');
    ok($ordered->completed->is_ready, 'now ready');
    is($ordered->completed->failure, 'example error', 'propagated correct error');
    done_testing;
};
done_testing;
