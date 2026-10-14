#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;
use HAMT::Map;

# Named checkpoints.

{
    my $s = State::Store->new('a');
    is(scalar($s->checkpoints), 0, 'a new store has no checkpoints');
    is_deeply([$s->checkpoints], [], 'and lists none');
    ok(!$s->has_checkpoint('x'), 'has_checkpoint is false for one that is not there');

    is(refaddr($s->checkpoint('first')), refaddr($s), 'checkpoint returns the store');
    ok($s->has_checkpoint('first'), 'and has_checkpoint is true for it');
    $s->set('b')->set('c');
    is(refaddr($s->restore('first')), refaddr($s), 'restore returns the store');
    is($s->current, 'a', 'and the value named is current');
    is($s->undo_count, 3, 'as a step of its own');
    $s->undo;
    is($s->current, 'c', 'which can be undone');
    $s->redo;
    is($s->current, 'a', 'and redone');
}

# Restore is a change: it empties the redo stack and tells the watchers.
{
    my $s = State::Store->new(1);
    $s->checkpoint('one');
    $s->set(2)->set(3);
    $s->undo;
    my @told;
    $s->watch(sub { push @told, "$_[0]>$_[1]" });
    $s->restore('one');
    is("@told", '2>1', 'the watchers are told of a restore');
    is($s->redo_count, 0, 'and it throws away what could have been redone');
    @told = ();
    $s->restore('one');
    is("@told", '', 'restoring the value already held tells nobody');
    is($s->undo_count, 2, 'and is not a step');
}

# The validator is not asked.
{
    my $s = State::Store->new(5);
    $s->checkpoint('five');
    $s->set(10);
    my $asked = 0;
    $s->validator(sub { $asked++; $_[0] > 7 });
    $s->restore('five');
    is($s->current, 5, 'a restore makes current a value the validator would now refuse');
    is($asked, 0, 'without asking it');
}

# A checkpoint outlives the history.
{
    my %gone;
    {
        package Local::Counted;
        sub new { bless { n => $_[1] }, $_[0] }
        sub DESTROY { $gone{ $_[0]{n} }++ }
    }
    {
        my $s = State::Store->new(Local::Counted->new('kept'), history => 1);
        $s->checkpoint('k');
        $s->set(Local::Counted->new($_)) for 1 .. 5;
        is($gone{kept}, undef, 'a checkpoint keeps its value alive past a history limit of one');
        $s->clear_history;
        is($gone{kept}, undef, 'and past clear_history');
        $s->restore('k');
        isa_ok($s->current, 'Local::Counted', 'and it can be restored');
        is($s->current->{n}, 'kept', 'to that value');

        $s->checkpoint('k');
        $s->set(Local::Counted->new('other'));
        $s->checkpoint('k');
        $s->clear_history;
        is($gone{kept}, 1, 'naming a checkpoint again lets go of the value it named before, once');
        $s->drop_checkpoint('k');
        is($gone{other}, undef, 'dropping a checkpoint on the current value leaves the value');
        is(scalar($s->checkpoints), 0, 'and the checkpoint is gone');
    }
    is(scalar(grep { $_ != 1 } values %gone), 0, 'every value destroyed exactly once');
    is(scalar(keys %gone), 7, 'all seven of them');
}

# Several, listed and dropped.
{
    my $s = State::Store->new(0);
    for my $n (qw(gamma alpha beta)) { $s->set($n)->checkpoint($n) }
    is_deeply([$s->checkpoints], [qw(alpha beta gamma)], 'checkpoints lists the names, sorted');
    is(scalar($s->checkpoints), 3, 'and counts them in scalar context');
    is(refaddr($s->drop_checkpoint('beta')), refaddr($s), 'drop_checkpoint returns the store');
    is_deeply([$s->checkpoints], [qw(alpha gamma)], 'and the name is gone');
    $s->restore('alpha');
    is($s->current, 'alpha', 'the others still restore');
    ok(!eval { $s->restore('beta'); 1 }, 'restoring one dropped dies');
    like($@, qr/^State::Store::restore: no checkpoint named "beta"/, 'naming it');
    ok(!eval { $s->drop_checkpoint('beta'); 1 }, 'dropping it again dies');
    like($@, qr/^State::Store::drop_checkpoint: no checkpoint named "beta"/, 'naming it');
    ok(!eval { State::Store->new->restore('none'); 1 }, 'restoring on a store that never had one dies');
    ok(!eval { $s->checkpoint(undef); 1 }, 'an undef name dies');
    like($@, qr/^State::Store::checkpoint: a checkpoint's name cannot be undef/, 'saying so');
}

# Names.
{
    my $s = State::Store->new(0);
    my %names = (empty => '', wide => "sm\x{263a}le", long => 'n' x 5000, number => 42, space => 'a b');
    for my $k (sort keys %names) { $s->set($k)->checkpoint($names{$k}) }
    for my $k (sort keys %names) {
        $s->restore($names{$k});
        is($s->current, $k, "a name that is $k works");
    }
    my $latin = "caf\x{e9}";
    my $up = $latin;
    utf8::upgrade($up);
    $s->set('latin')->checkpoint($latin);
    ok($s->has_checkpoint($up), 'the two encodings of one string are one name');
    $s->set('upgraded')->checkpoint($up);
    is(scalar(grep { $_ eq $latin } $s->checkpoints), 1, 'naming it in the other replaces it, not adds');
    $s->restore($latin);
    is($s->current, 'upgraded', 'and restoring by either finds the newer');
    is($s->set(1)->restore('42')->current, 'number', 'the number 42 and the string "42" are one name');
    my ($wide) = grep { /\x{263a}/ } $s->checkpoints;
    ok(utf8::is_utf8($wide), 'a wide name comes back as a character string');
}

# A name that is a temporary: a sub's return value. Read once, it must still
# be there to read again.
{
    sub name_for { my $n = shift; return "made-$n" }
    my $s = State::Store->new(0);
    $s->checkpoint(name_for(1));
    ok($s->has_checkpoint(name_for(1)), 'a checkpoint named by what a sub returns');
    $s->set(5)->restore(name_for(1));
    is($s->current, 0, 'restored by it');
    ok(eval { $s->drop_checkpoint(name_for(1)); 1 }, 'and dropped by it') or diag $@;
    ok(!$s->has_checkpoint('made-1'), 'which is gone');
    is($s->set(1)->set(2)->undo(two()), 2, 'a count that is a sub\'s return value');
    sub two { return 1 + 1 }
    $s->history_limit(limit_of());
    sub limit_of { return '' . 3 }
    is($s->history_limit, 3, 'and a limit');
}

# A tied name is read once.
{
    package Local::Name;
    sub TIESCALAR { my $n = 0; bless \$n, shift }
    sub FETCH { ${ $_[0] }++; 'tied' }
    sub STORE { }
    package main;
    tie my $name, 'Local::Name';
    my $s = State::Store->new(0);
    $s->checkpoint($name);
    is(${ tied $name }, 1, 'checkpoint reads a tied name once');
    ok($s->has_checkpoint('tied'), 'under what it read');
}

# Checkpoints are let go with their store, and by transactions.
{
    my %gone;
    {
        package Local::Held;
        sub new { bless { n => $_[1] }, $_[0] }
        sub DESTROY { $gone{ $_[0]{n} }++ }
    }
    my $hamt = HAMT::_live_blocks();
    {
        my $s = State::Store->new(Local::Held->new('a'), history => 0);
        $s->checkpoint('a');
        $s->set(Local::Held->new('b'));
        $s->checkpoint('b');
        $s->txn(sub { $s->txn(sub { $s->set(Local::Held->new('c')) }) });
        $s->txn(sub { $s->checkpoint('c') });
        is($gone{a}, undef, 'a value held only by a checkpoint is alive');
    }
    is(join(',', map { "$_=$gone{$_}" } sort keys %gone), 'a=1,b=1,c=1',
       'every value is destroyed once when a store with checkpoints goes, after transactions inner and outer');
    is(HAMT::_live_blocks(), $hamt, 'and every block of the checkpoints is given back');
}

# Inside a transaction.
{
    my $s = State::Store->new(0);
    $s->checkpoint('before');
    eval { $s->txn(sub { $s->set(1)->checkpoint('inside'); $s->drop_checkpoint('before'); die "no\n" }) };
    ok($s->has_checkpoint('before'), 'a dropped checkpoint comes back when the transaction fails');
    ok(!$s->has_checkpoint('inside'), 'and one named inside is gone');
    $s->txn(sub { $s->set(2)->checkpoint('inside'); $s->drop_checkpoint('before') });
    ok($s->has_checkpoint('inside'), 'in one that works, one named inside stays');
    ok(!$s->has_checkpoint('before'), 'and one dropped stays dropped');
    $s->txn(sub { $s->checkpoint('noop'); $s->set(5)->set(2) });
    ok($s->has_checkpoint('noop'), 'even when the value ends where it began');
    my $err;
    $s->txn(sub { eval { $s->restore('inside') }; $err = $@ });
    like($err, qr/^State::Store::restore: not inside a transaction/, 'restore inside a transaction dies');
}

# Not from inside the validator.
for my $case ([checkpoint => sub { $_[0]->checkpoint('v') }],
              [restore => sub { $_[0]->restore('base') }],
              [drop_checkpoint => sub { $_[0]->drop_checkpoint('base') }]) {
    my ($method, $do) = @$case;
    my $s = State::Store->new(0);
    $s->checkpoint('base');
    my $err;
    $s->validator(sub { eval { $do->($_[2]) }; $err = $@; 1 });
    $s->set(1);
    like($err, qr/^State::Store::$method: the validator may not change the store/, "$method inside the validator dies");
    ok($s->has_checkpoint('base'), '  and leaves the checkpoints alone');
    is_deeply([$s->checkpoints], ['base'], '  every one of them');
}

# A map, which is what it is for.
{
    my $s = State::Store->new(HAMT::Map->new(n => 0));
    $s->checkpoint('zero');
    $s->swap(sub { $_[0]->set(n => $_[0]->get('n') + 1) }) for 1 .. 100;
    my $before = refaddr($s->current);
    $s->restore('zero');
    is($s->current->get('n'), 0, 'a map restored');
    $s->undo;
    is(refaddr($s->current), $before, 'and the restore undone to the very map before it');
}
is(State::Store::_live_blocks(), 0, 'every store in this file is gone');

done_testing;
