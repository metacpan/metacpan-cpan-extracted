#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use State::Store;

# A transaction that fails puts the store back exactly as it was.

sub state_of {
    my $s = shift;
    my ($p, $f) = State::Store::_stacks($s);
    return { value => $s->current, past => "@$p", future => "@$f", txn => $s->in_txn ? 1 : 0 };
}

{
    my $s = State::Store->new(0);
    $s->set($_) for 1 .. 5;
    $s->undo(2);
    my $before = state_of($s);
    my $told = 0;
    $s->watch(sub { $told++ });
    ok(!eval { $s->txn(sub { $s->set(10)->set(11); $s->swap(sub { 12 }); die "stop\n" }); 1 }, 'a transaction whose sub dies');
    is($@, "stop\n", 'dies with the sub\'s error');
    is_deeply(state_of($s), $before, 'and the value and both stacks are as they were, the redo stack included');
    is($told, 0, 'with nobody told');
    my $err = bless { n => 1 }, 'Local::Error';
    ok(!eval { $s->txn(sub { $s->set(99); die $err }); 1 }, 'an exception object');
    is($@, $err, 'arrives as itself');
    is_deeply(state_of($s), $before, 'and the store is as it was');
    is($s->redo, 1, 'and works afterwards');
}

# Values made inside are let go.
{
    my %gone;
    {
        package Local::Counted;
        sub new { bless { n => $_[1] }, $_[0] }
        sub DESTROY { $gone{ $_[0]{n} }++ }
    }
    my $s = State::Store->new(Local::Counted->new('before'));
    eval { $s->txn(sub { $s->set(Local::Counted->new("in$_")) for 1 .. 3; die "no\n" }) };
    is(join(',', sort keys %gone), 'in1,in2,in3', 'every value made inside a failed transaction is destroyed');
    is(scalar(grep { $_ != 1 } values %gone), 0, 'once');
    is($gone{before}, undef, 'and the value before it is kept');
    $s->txn(sub { $s->set(Local::Counted->new("ok$_")) for 1 .. 3 });
    is(join(',', grep { /^ok/ } sort keys %gone), 'ok1,ok2', 'in one that works, the values passed through are destroyed');
    is($gone{before}, undef, 'and the one before is kept as the step');
}

# What a transaction keeps is let go when it is over.
{
    my %gone;
    {
        package Local::Kept;
        sub new { bless { n => $_[1] }, $_[0] }
        sub DESTROY { $gone{ $_[0]{n} }++ }
    }
    {
        my $s = State::Store->new(Local::Kept->new('start'), history => 0);
        $s->txn(sub {
            $s->set(Local::Kept->new('outer'));
            $s->txn(sub { $s->set(Local::Kept->new('inner')) });
        });
        is($gone{start}, 1, 'with no history, the value a transaction began with is let go when it ends');
        is($gone{outer}, 1, 'and so is the one an inner transaction began with');
        is($gone{inner}, undef, 'while the value it ended with is held');
    }
    is(scalar(grep { $_ == 1 } values %gone), 3, 'every value destroyed once');
}

# Nested failures.
{
    my $s = State::Store->new(0);
    my $mid;
    $s->txn(sub {
        $s->set(1);
        eval { $s->txn(sub { $s->set(2)->set(3); die "inner\n" }) };
        $mid = $s->current;
        $s->set(4);
    });
    is($mid, 1, 'an inner transaction that fails and is caught undoes only what it did');
    is($s->current, 4, 'and the outer one carries on');
    is($s->undo_count, 1, 'to one step');

    my $t = State::Store->new(0);
    ok(!eval { $t->txn(sub { $t->set(1); $t->txn(sub { $t->set(2); die "deep\n" }); $t->set(3) }); 1 },
       'an inner failure that is not caught');
    is($@, "deep\n", 'fails the outer one with its error');
    is($t->current, 0, 'and everything is undone');
    is($t->undo_count, 0, 'with no step');
    ok(!$t->in_txn, 'and no transaction left open');
}

# Leaving the sub some other way. The warnings perl gives for it are what
# perl does; they are not under test here.
{
    no warnings 'exiting';
    my $s = State::Store->new(0);
    my $r = $s->txn(sub { $s->set(1); return 'early'; $s->set(2) });
    is($r, 'early', 'return from the sub ends the transaction');
    is($s->current, 1, 'and it is kept');
    ok(!$s->in_txn, 'closed');

    # The subs a store calls cannot leave by a loop outside them: there is
    # none to be found from where they run, so it is an error, and the store
    # deals with it as with any other.
    for my $how (qw(last next)) {
        my $t = State::Store->new(0);
        my ($ok, $err, $after_loop);
        for my $i (1) {
            no warnings 'exiting';
            $ok = eval { $t->txn(sub { $t->set(5); $how eq 'last' ? (last) : (next) }); 1 };
            $err = $@;
            $after_loop = 1;
        }
        ok(!$ok, "$how out of a transaction's sub is an error");
        like($err, qr/^Can't "$how" outside a loop block/, "  perl's own");
        ok($after_loop, '  and the loop around the call carries on as after any error');
        ok(!$t->in_txn, '  no transaction is left open');
        is($t->current, 0, '  the store is put back');
        is($t->undo_count, 0, '  with no step');
    }
    for my $case (
        [swap      => sub { my $s = shift; $s->swap(sub { last }) }],
        [watcher   => sub { my $s = shift; $s->watch(sub { last }); $s->set(1) }],
        [validator => sub { my $s = shift; $s->validator(sub { last }); $s->set(1) }],
    ) {
        my ($name, $do) = @$case;
        my $t = State::Store->new(0);
        my ($ok, $err, $after_loop);
        for my $i (1) {
            no warnings 'exiting';
            $ok = eval { $do->($t); 1 };
            $err = $@;
            $after_loop = 1;
        }
        ok(!$ok, "last out of a $name is an error");
        like($err, qr/^Can't "last" outside a loop block/, "  perl's own");
        ok($after_loop, '  and the loop around the call carries on');
    }
    {
        my $t = State::Store->new(0);
        for my $i (1) { no warnings 'exiting'; eval { $t->swap(sub { last }) } }
        is($t->current, 0, 'a swap left by last changes nothing');
        my $u = State::Store->new(0);
        $u->watch(sub { last });
        for my $i (1) { no warnings 'exiting'; eval { $u->set(1) } }
        is($u->current, 1, 'a watcher left by last does not undo the change');
        my $v = State::Store->new(0);
        $v->validator(sub { last });
        for my $i (1) { no warnings 'exiting'; eval { $v->set(1) } }
        is($v->current, 0, 'a validator left by last refuses the change');
        ok(eval { $v->validator(undef); $v->set(2); 1 }, 'and the store can be changed again afterwards');
    }

    my $t = State::Store->new(0);
    sub Local::elsewhere { 'went' }
    my $g = $t->txn(sub { $t->set(6); goto &Local::elsewhere });
    is($g, 'went', 'goto out of the sub returns what it went to');
    is($t->current, 6, 'and the transaction is kept');
    ok(!$t->in_txn, 'closed');
}

# The caller's $@ is left alone by a call that works.
{
    my $s = State::Store->new(0);
    $s->watch(sub { 1 });
    $s->validator(sub { 1 });
    eval { die "earlier\n" };
    $s->swap(sub { $_[0] + 1 });
    is($@, "earlier\n", 'a swap, its watcher and its validator leave $@ as they found it');
    $s->txn(sub { $s->set(5) });
    is($@, "earlier\n", 'and so does a transaction');
    $s->undo;
    is($@, "earlier\n", 'and an undo told to a watcher');
}

# A watcher that dies at the end of a transaction: the transaction stands.
{
    my $s = State::Store->new(0);
    $s->watch(sub { die "watcher\n" });
    ok(!eval { $s->txn(sub { $s->set(1) }); 1 }, 'a watcher that dies after a transaction');
    is($@, "watcher\n", 'dies with its error from txn');
    is($s->current, 1, 'and the transaction stands, as a change does');
    is($s->undo_count, 1, 'as one step');
}

# The store dropped inside.
{
    my $s = State::Store->new(0);
    eval { $s->txn(sub { undef $s; $_[0]->set(1) }) };
    ok(!defined $s, 'the only variable holding the store undefined inside a transaction');
    pass('does not crash it');
}
is(State::Store::_live_blocks(), 0, 'every store in this file is gone');

# Many, nothing left on the temporaries stack.
{
    my $s = State::Store->new(0);
    my $tmps = State::Store::_tmps_ix();
    for my $i (1 .. 2000) {
        $s->txn(sub { $s->set($i) });
        eval { $s->txn(sub { $s->set(-$i); die "x\n" }) };
    }
    is($s->current, 2000, '4,000 transactions, half failed');
    cmp_ok(State::Store::_tmps_ix() - $tmps, '<', 10, 'leave nothing on the temporaries stack');
}

done_testing;
