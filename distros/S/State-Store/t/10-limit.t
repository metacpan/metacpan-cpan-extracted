#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;
use HAMT::Map;

# A history limit: exactly the newest N steps can be undone, and what falls
# off the end is let go.

is(State::Store->new(1)->history_limit, undef, 'a store has no limit unless given one');
is(State::Store->new(1, history => 5)->history_limit, 5, 'history => 5 is a limit of five');
is(State::Store->new(1, history => undef)->history_limit, undef, 'history => undef is none');
is(State::Store->new(1, history => '7')->history_limit, 7, 'a string of digits is a number');

for my $limit (0, 1, 2, 31, 32, 33, 1000) {
    my $s = State::Store->new(0, history => $limit);
    $s->set($_) for 1 .. 1100;
    my $want = $limit < 1100 ? $limit : 1100;
    is($s->undo_count, $want, "limit $limit: $want steps kept of 1,100");
    is($s->undo(5000), $want, "limit $limit: all of them can be undone");
    is($s->current, 1100 - $want, "limit $limit: back to the oldest kept, " . (1100 - $want));
    is($s->undo, 0, "limit $limit: and no further");
    is($s->redo(5000), $want, "limit $limit: and all redone");
    is($s->current, 1100, "limit $limit: to the newest");
    is(State::Store::_check($s), 0, "limit $limit: both stacks well formed");
}

# Zero keeps nothing at all.
{
    my $s = State::Store->new('a', history => 0);
    $s->set('b');
    ok(!$s->can_undo, 'with a limit of 0 there is nothing to undo');
    is($s->undo, 0, 'and undo takes no step');
    is($s->current, 'b', 'the value is the last set');
}

# Values that fall off the end are destroyed.
{
    my %gone;
    {
        package Local::Counted;
        sub new { bless { n => $_[1] }, $_[0] }
        sub DESTROY { $gone{ $_[0]{n} }++ }
    }
    my $s = State::Store->new(Local::Counted->new(0), history => 3);
    $s->set(Local::Counted->new($_)) for 1 .. 100;
    is($s->undo_count, 3, 'a limit of 3 after 100 changes: three steps to undo');
    is(join(',', grep { $gone{$_} } 97 .. 100), '', 'the values of those steps and the current one are alive');
    is(scalar(grep { !$gone{$_} } 0 .. 100 - 3 - 32 - 1), 0, 'and every value more than 32 changes beyond the limit has been let go');
    is(scalar(grep { $_ != 1 } values %gone), 0, 'each once');
    $s->history_limit(1);
    is(join(',', grep { !$gone{$_} } 0 .. 100), '99,100', 'lowering the limit lets go at once of everything it no longer keeps');
    undef $s;
    is(scalar(keys %gone), 101, 'and the store going lets go of the rest');
    is(scalar(grep { $_ != 1 } values %gone), 0, 'all of them once');
}

# Setting the limit later.
{
    my $s = State::Store->new(0);
    $s->set($_) for 1 .. 20;
    is(refaddr($s->history_limit(5)), refaddr($s), 'history_limit with an argument returns the store');
    is($s->history_limit, 5, 'and the limit is set');
    is($s->undo_count, 5, 'twenty steps cut to five at once');
    $s->undo(5);
    is($s->current, 15, 'the five newest');
    $s->redo(5);
    $s->history_limit(50);
    is($s->undo_count, 5, 'raising the limit brings nothing back');
    $s->set($_) for 21 .. 30;
    is($s->undo_count, 15, 'and later steps are kept up to it');
    $s->history_limit(undef);
    is($s->history_limit, undef, 'undef removes the limit');
    $s->set($_) for 31 .. 200;
    is($s->undo_count, 185, 'and every step is kept again');
}

# A lower limit while there is something to redo.
{
    my $s = State::Store->new(0);
    $s->set($_) for 1 .. 10;
    $s->undo(8);
    is($s->current, 2, 'eight undone');
    $s->history_limit(3);
    is($s->undo_count, 2, 'a limit above what is behind cuts nothing behind');
    is($s->redo_count, 8, 'and nothing ahead');
    is($s->undo(2), 2, 'what is behind can still be undone');
    is($s->redo_count, 10, 'and an undo is not cut by the limit: all ten can be redone');
    $s->redo(2);
    is($s->redo(8), 8, 'everything ahead can still be redone');
    is($s->current, 10, 'to the last value');
    is($s->undo_count, 3, 'and only three of the steps passed over are kept to undo');
    $s->undo(3);
    is($s->current, 7, 'the three newest');
    is(State::Store::_check($s), 0, 'with both stacks well formed');
}

# A change that is no change does not push anything off.
{
    my $s = State::Store->new(0, history => 2);
    $s->set(1)->set(2);
    $s->set(2) for 1 .. 5;
    $s->undo(2);
    is($s->current, 0, 'setting the same value does not cost a step');
}

# Bad limits.
for my $bad (-1, 1.5, 'lots', '', [3]) {
    my $label = ref $bad ? 'a reference' : "'$bad'";
    ok(!eval { State::Store->new(1, history => $bad); 1 }, "history => $label dies");
    like($@, qr/^State::Store::new: the history limit/, 'naming the option');
    my $s = State::Store->new(1, history => 4);
    ok(!eval { $s->history_limit($bad); 1 }, "history_limit($label) dies");
    is($s->history_limit, 4, 'and leaves the limit as it was');
}
ok(!eval { State::Store->new(1)->history_limit(1, 2); 1 }, 'history_limit with two arguments dies');
{
    my $made = State::Store::_live_blocks();
    eval { State::Store->new(1, history => -1) };
    is(State::Store::_live_blocks(), $made, 'a bad option leaves no store half made');
}

# The model, under limits of 1 and 50.
for my $limit (1, 50) {
    srand(1000 + $limit);
    my $s = State::Store->new(0, history => $limit);
    my (@past, @future);
    my $value = 0;
    my $bad = 0;
    my $next = 1;
    for my $step (1 .. 20_000) {
        my $r = rand;
        if ($r < 0.45) {
            $s->set($next);
            push @past, $value; shift @past while @past > $limit;
            @future = (); $value = $next++;
        }
        elsif ($r < 0.70) {
            my $n = 1 + int rand 3;
            my $took = $s->undo($n);
            my $want = $n < @past ? $n : @past;
            $bad++ if $took != $want;
            for (1 .. $want) { push @future, $value; $value = pop @past }
        }
        elsif ($r < 0.95) {
            my $n = 1 + int rand 3;
            my $took = $s->redo($n);
            my $want = $n < @future ? $n : @future;
            $bad++ if $took != $want;
            for (1 .. $want) { push @past, $value; shift @past while @past > $limit; $value = pop @future }
        }
        else {
            $s->clear_history;
            @past = @future = ();
        }
        $bad++ if $s->current != $value;
        next if $step % 200;
        my ($p, $f) = State::Store::_stacks($s);
        $bad++, diag("limit $limit step $step: past @$p, wanted @past") if "@$p" ne "@past";
        $bad++, diag("limit $limit step $step: future differs") if "@$f" ne "@future";
        $bad++ if State::Store::_check($s);
    }
    is($bad, 0, "the model under a limit of $limit agrees for 20,000 steps");
}

# Steps beyond the limit, kept a while before they are cut, are never
# offered: not to undo, not after undoing everything, not under a new limit.
{
    my $s = State::Store->new(0, history => 5);
    $s->set($_) for 1 .. 20;
    is($s->undo(100), 5, 'twenty changes under a limit of 5: five undone');
    is($s->current, 15, 'to the oldest kept');
    is($s->undo, 0, 'and nothing further, though older steps are not cut yet');
    $s->redo(5);
    $s->history_limit(50);
    is($s->undo_count, 5, 'a higher limit does not bring them back');
    $s->history_limit(undef);
    is($s->undo_count, 5, 'nor does no limit');
    my $t = State::Store->new(0, history => 5);
    $t->set($_) for 1 .. 20;
    $t->txn(sub { $t->set(99) });
    is($t->undo_count, 5, 'a transaction is a step within the limit');
    eval { $t->txn(sub { $t->set(98); die "x\n" }) };
    is($t->undo(100), 5, 'and a failed one leaves exactly the steps there were');
    is($t->current, 16, 'back to the oldest kept');
}

# Memory stays level under a limit.
{
    my $s = State::Store->new(HAMT::Map->new(map { ("k$_" => $_) } 1 .. 1000), history => 10);
    $s->swap(sub { $_[0]->set(k1 => $_) }) for 1 .. 1000;
    my $hamt = HAMT::_live_blocks();
    # The past is cut 32 steps after it passes the limit, so what is held
    # swings by that many steps' worth; it does not grow.
    $s->swap(sub { $_[0]->set(k1 => $_) }) for 1 .. 50_000;
    my $half = HAMT::_live_blocks();
    $s->swap(sub { $_[0]->set(k1 => $_) }) for 1 .. 50_000;
    cmp_ok(abs($half - $hamt), '<', 400, '50,000 more changes under a limit of 10 hold about what 1,000 did');
    cmp_ok(abs(HAMT::_live_blocks() - $hamt), '<', 400, 'and so do 100,000');
    is($s->undo_count, 10, 'with ten steps to undo');
}

done_testing;
