#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use State::Store;

# What watchers hold is let go: their subs, the changes queued for them, and
# their places in the list.

my %gone;
{
    package Local::Counted;
    sub new { bless { n => $_[1] }, $_[0] }
    sub DESTROY { $gone{ $_[0]{n} }++ }
}

# A watcher's sub, and what it closes over, go with the store.
{
    %gone = ();
    {
        my $s = State::Store->new(0);
        my $held = Local::Counted->new('captured');
        $s->watch(sub { my $x = $held });
    }
    is($gone{captured}, 1, 'a watcher\'s sub goes when its store does, and with it what it closed over');
}

# And with unwatch.
{
    %gone = ();
    my $s = State::Store->new(0);
    my $id;
    {
        my $held = Local::Counted->new('unwatched');
        $id = $s->watch(sub { my $x = $held });
    }
    is($gone{unwatched}, undef, 'a watcher\'s sub is alive while it is attached');
    $s->unwatch($id);
    is($gone{unwatched}, 1, 'and goes when it is removed');
}

# Removed during a round, swept out after it.
{
    my $s = State::Store->new(0);
    my @ids;
    push @ids, $s->watch(sub { $_[2]->unwatch($ids[1]); $_[2]->unwatch($ids[2]) });
    push @ids, $s->watch(sub { });
    push @ids, $s->watch(sub { });
    $s->set(1);
    is($s->watchers, 1, 'two removed during a round');
    is(State::Store::_watcher_slots($s), 1, 'and their places are gone once it is over');
    $s->unwatch($ids[0]);
    is(State::Store::_watcher_slots($s), 0, 'one removed outside a round goes at once');
    for (1 .. 1000) { my $id = $s->watch(sub { }); $s->unwatch($id) }
    is(State::Store::_watcher_slots($s), 0, 'a thousand added and removed leave no places behind');
}

# Removing twice during a round, and counting during one.
{
    my $s = State::Store->new(0);
    my (@results, $count);
    my @ids;
    push @ids, $s->watch(sub {
        push @results, $_[2]->unwatch($ids[1]), $_[2]->unwatch($ids[1]);
        $count = $_[2]->watchers;
    });
    push @ids, $s->watch(sub { });
    push @ids, $s->watch(sub { });
    $s->set(1);
    is_deeply(\@results, [1, ''], 'during a round, removing a watcher twice is true once');
    is($count, 2, 'and watchers counts only those left, though their places are not yet swept');
    is($s->watchers, 2, 'as it does afterwards');
}

# A watcher removed during a round is not called, and nobody is called in
# its place.
{
    my $s = State::Store->new(0);
    my @order;
    my @ids;
    push @ids, $s->watch(sub { push @order, 'A'; $_[2]->unwatch($ids[2]) if $_[1] == 1 });
    push @ids, $s->watch(sub { push @order, 'B' });
    push @ids, $s->watch(sub { push @order, 'C' });
    $s->set(1);
    is("@order", 'A B', 'the first removes the third: the second is called, and nothing more');
}

# A round abandoned by the loop guard lets go of what was queued.
{
    %gone = ();
    my $made = 0;
    {
        my $s = State::Store->new(Local::Counted->new($made++), history => 0);
        my $w1 = $s->watch(sub { $_[2]->set(Local::Counted->new($made++)) });
        my $w2 = $s->watch(sub { $_[2]->set(Local::Counted->new($made++)) });
        ok(!eval { $s->set(Local::Counted->new($made++)); 1 }, 'two watchers that each change the store every time');
        like($@, qr/10000 times in one round/, 'are stopped');
        $s->unwatch($_) for $w1, $w2;
        my $n = 0;
        $s->watch(sub { $n++ });
        $s->set('after');
        is($n, 1, 'and nothing that was queued when they were is told afterwards');
    }
    is(scalar(keys %gone), $made, "all $made values made are destroyed");
    is(scalar(grep { $_ != 1 } values %gone), 0, 'each once');
}

is(State::Store::_live_blocks(), 0, 'every store in this file is gone');

done_testing;
