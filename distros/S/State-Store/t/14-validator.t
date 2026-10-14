#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;
use HAMT::Map;

# The validator: asked before a set or a swap, and nothing changes when it
# says no.

{
    my $s = State::Store->new(1);
    is($s->validator, undef, 'a store has no validator unless given one');
    my $code = sub { $_[0] > 0 };
    is(refaddr($s->validator($code)), refaddr($s), 'setting one returns the store');
    is($s->validator, $code, 'and it is the sub given');

    $s->set(5);
    is($s->current, 5, 'a value it accepts is stored');
    ok(!eval { $s->set(-1); 1 }, 'a value it refuses dies');
    like($@, qr/^State::Store::set: the validator refused the value/, 'naming the method');
    is($s->current, 5, 'and the store holds what it held');
    is($s->undo_count, 1, 'with no step recorded');

    ok(!eval { $s->swap(sub { $_[0] - 100 }); 1 }, 'a swap to a refused value dies');
    like($@, qr/^State::Store::swap: the validator refused the value/, 'naming swap');
    is($s->current, 5, 'and changes nothing');

    is(refaddr($s->validator(undef)), refaddr($s), 'removing it returns the store');
    is($s->validator, undef, 'and it is gone');
    $s->set(-1);
    is($s->current, -1, 'after which anything is stored');
}

# What it is shown.
{
    my @seen;
    my $s = State::Store->new('old', validator => sub { push @seen, [@_]; 1 });
    is_deeply($seen[0], ['old', undef, undef], 'new shows it the first value, with undef before it and no store');
    @seen = ();
    $s->set('new');
    is(scalar @seen, 1, 'set asks it once');
    is_deeply([@{ $seen[0] }[0, 1]], ['new', 'old'], 'with the value proposed and the value held');
    is(refaddr($seen[0][2]), refaddr($s), 'and the store');
    is(scalar @{ $seen[0] }, 3, 'and nothing else');

    my $addr;
    my $ro;
    $s->validator(sub { $addr = refaddr(\$_[0]); $ro = Internals::SvREADONLY($_[0]); 1 });
    $s->set('newer');
    is($addr, refaddr(\$s->current), 'it is shown the very scalar that is then stored');
    ok($ro, 'read-only');
    ok(!eval { $s->validator(sub { $_[0] = 'changed'; 1 }); $s->set('x'); 1 }, 'so it cannot change it');
    is($s->current, 'newer', 'and the store is as it was');
}

# A die is the validator's own error.
{
    my $s = State::Store->new(1, validator => sub { die "too big\n" if $_[0] > 10; 1 });
    ok(!eval { $s->set(11); 1 }, 'a validator that dies');
    is($@, "too big\n", 'refuses with its own error');
    is($s->current, 1, 'and the store is as it was');
    my $err = bless {}, 'Local::Refusal';
    $s->validator(sub { die $err });
    ok(!eval { $s->set(2); 1 }, 'an exception object');
    is($@, $err, 'arrives as itself');
}

# Refused, nothing else happens either.
{
    my $s = State::Store->new(0, validator => sub { $_[0] ne 'bad' });
    my $told = 0;
    $s->watch(sub { $told++ });
    $s->set(1)->set(2);
    $s->undo;
    is($s->redo_count, 1, 'one undone');
    eval { $s->set('bad') };
    is($told, 3, 'a refused change calls no watcher');
    is($s->redo_count, 1, 'and leaves the redo stack');
    is($s->undo_count, 1, 'and records no step');
    eval { $s->swap(sub { 'bad' }) };
    is($s->redo_count, 1, 'a refused swap likewise');
}

# What it is not asked about.
{
    my $asked = 0;
    my $s = State::Store->new(1);
    $s->set(2)->set(3);
    $s->validator(sub { $asked++; $_[0] < 0 });
    is($asked, 0, 'setting a validator does not check the value held');
    $s->set(3);
    is($asked, 0, 'a change that is no change does not ask it');
    $s->undo(2);
    $s->redo;
    is($asked, 0, 'nor do undo and redo, though it would refuse every value they arrive at');
    is($s->current, 2, 'which they arrive at');
    $s->clear_history;
    $s->history_limit(5);
    is($asked, 0, 'nor clear_history nor history_limit');
}

# new with a validator.
{
    ok(!eval { State::Store->new(-1, validator => sub { $_[0] > 0 }); 1 }, 'a first value the validator refuses');
    like($@, qr/^State::Store::new: the validator refused the value/, 'makes no store');
    is(State::Store::_live_blocks(), 0, 'and nothing is left allocated');
    ok(!eval { State::Store->new(validator => sub { 1 }); 1 }, 'new needs the value before the options');
    my $s = State::Store->new(undef, validator => sub { 1 });
    is($s->current, undef, 'undef can be a first value');
    is(State::Store->new(1, validator => undef)->validator, undef, 'validator => undef is none');
    for my $bad ('name', 1, [], {}) {
        ok(!eval { State::Store->new(1, validator => $bad); 1 }, 'validator => ' . (ref $bad || "'$bad'") . ' dies');
        like($@, qr/^State::Store::new: the validator is not a code reference/, 'saying so');
        my $t = State::Store->new(1);
        ok(!eval { $t->validator($bad); 1 }, '  as does validator(' . (ref $bad || "'$bad'") . ')');
    }
    ok(!eval { State::Store->new(1)->validator(sub { 1 }, 2); 1 }, 'validator with two arguments dies');
}

# It may not change the store.
for my $case (
    [set           => sub { $_[0]->set(9) }],
    [swap          => sub { $_[0]->swap(sub { 9 }) }],
    [undo          => sub { $_[0]->undo }],
    [redo          => sub { $_[0]->redo }],
    [clear_history => sub { $_[0]->clear_history }],
    [history_limit => sub { $_[0]->history_limit(1) }],
    [validator     => sub { $_[0]->validator(undef) }],
    [txn           => sub { $_[0]->txn(sub { 1 }) }],
) {
    my ($method, $do) = @$case;
    my $s = State::Store->new(0);
    $s->set(1);
    $s->undo; $s->redo;
    my $err;
    $s->validator(sub { eval { $do->($_[2]) }; $err = $@; 1 });
    $s->set(2);
    like($err, qr/^State::Store::$method: the validator may not change the store/, "$method inside the validator dies");
    is($s->current, 2, '  and the change being validated goes ahead');
    is($s->undo_count, 2, '  with only its own step');
}
{
    my $s = State::Store->new(0);
    my ($got, $count, $ok);
    $s->validator(sub { my $st = $_[2]; $got = $st->current; $count = $st->undo_count; $ok = eval { my $id = $st->watch(sub {}); $st->unwatch($id); 1 }; 1 });
    $s->set(1);
    is($got, 0, 'it may read the store');
    is($count, 0, 'and its history');
    ok($ok, 'and add and remove a watcher');
    $s->validator(sub { die "no\n" });
    eval { $s->set(5) };
    ok(eval { $s->validator(undef); $s->set(5); 1 }, 'after a validator dies, the store can be changed again') or diag $@;
}

# Called in scalar context.
{
    my $context;
    my $s = State::Store->new(1, validator => sub { $context = wantarray; my @one = (0); @one });
    is($context, '', 'the validator is called in scalar context');
    $s->set(2);
    is($s->current, 2, 'so an array of one false element is its length, and true');
}

# Inside the validator, a swap's sub is never called.
{
    my $ran = 0;
    my $err;
    my $s = State::Store->new(0, validator => sub { eval { $_[2]->swap(sub { $ran++; 5 }) }; $err = $@; 1 });
    $s->set(1);
    like($err, qr/^State::Store::swap: the validator may not change the store/, 'a swap inside the validator dies');
    is($ran, 0, 'before its sub is called');
}

# The validator goes with its store.
{
    my $gone = 0;
    {
        package Local::Gone;
        sub DESTROY { $gone++ }
    }
    {
        my $held = bless [], 'Local::Gone';
        my $s = State::Store->new(0, validator => sub { my $x = $held; 1 });
    }
    is($gone, 1, 'a validator\'s sub goes when its store does, and what it closed over with it');
    {
        my $held = bless [], 'Local::Gone';
        my $s = State::Store->new(0);
        $s->validator(sub { my $x = $held; 1 });
        undef $held;
        $s->validator(undef);
        is($gone, 2, 'and when it is removed');
    }
}

# The store dropped from inside the validator.
{
    my $s = State::Store->new(0);
    $s->validator(sub { undef $s; 1 });
    my $kept = State::Store->new(0);
    eval { $s->set(1) };
    ok(!defined $s, 'a validator that undefs the only variable holding its store');
    pass('does not crash the set');
}
is(State::Store::_live_blocks(), 0, 'and every store in this file is gone') or diag State::Store::_live_blocks();

# With a map.
{
    my $s = State::Store->new(HAMT::Map->new(count => 0), validator => sub { $_[0]->get('count') <= 3 });
    $s->swap(sub { $_[0]->set(count => $_[0]->get('count') + 1) }) for 1 .. 3;
    ok(!eval { $s->swap(sub { $_[0]->set(count => 4) }); 1 }, 'a map over the limit is refused');
    is($s->current->get('count'), 3, 'and the store holds the last one accepted');
}

done_testing;
