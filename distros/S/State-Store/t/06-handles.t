#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Scalar::Util qw(blessed);
use State::Store;
use HAMT::Map;

# What is and is not a store, subclasses, threads.

# ---- what is not a store ------------------------------------------------
my @not = (
    ['undef', undef], ['a string', 'State::Store'], ['a number', 42],
    ['a hash', {}], ['an array', []],
    ['a hash blessed into the class', bless({}, 'State::Store')],
    ['a scalar blessed into the class', bless(\(my $x = 12345), 'State::Store')],
    ['a HAMT map', HAMT::Map->new],
);
for my $case (@not) {
    my ($name, $thing) = @$case;
    for my $method (qw(current set swap)) {
        my @args = $method eq 'set' ? (1) : $method eq 'swap' ? (sub { 1 }) : ();
        no strict 'refs';
        ok(!eval { &{"State::Store::$method"}($thing, @args); 1 }, "$method on $name dies");
        like($@, qr/^State::Store::$method: not a store/, '  by name');
    }
}

# A forged object is refused, not dereferenced, and not freed as one.
{
    my $forged = bless \(my $address = 0xdeadbeef), 'State::Store';
    ok(!eval { $forged->current; 1 }, 'an address blessed into the class is not a store');
    undef $forged;
    pass('and dropping it frees nothing that was not its own');
}

# Storable cannot carry one.
SKIP: {
    skip 'Storable does not load', 2 unless eval { require Storable; 1 };
    my $s = State::Store->new('value');
    my $clone = eval { Storable::dclone($s) };
    ok(!eval { $clone->current; 1 }, 'a clone made by Storable is not a store');
    is($s->current, 'value', 'and the original is as it was');
}

# ---- subclasses -----------------------------------------------------------
{
    package Local::Sub;
    our @ISA = ('State::Store');
    my $destroyed = 0;
    sub DESTROY { $destroyed++ }
    sub destroyed { $destroyed }
    sub double { $_[0]->swap(sub { $_[0] * 2 }) }
    package main;

    my $s = Local::Sub->new(21);
    isa_ok($s, 'Local::Sub');
    isa_ok($s, 'State::Store');
    is($s->double->current, 42, 'a subclass method works on the store');
    isa_ok($s->set(1), 'Local::Sub', 'set returns the subclass object');
    isa_ok($s->new(5), 'Local::Sub', 'new called on an object makes one of its class');
    is($s->new(5)->current, 5, 'holding the value given and not the receiver\'s');
    my $before = Local::Sub->destroyed;
    undef $s;
    is(Local::Sub->destroyed, $before + 1, 'a subclass may have a DESTROY of its own, called once');
}
{
    my $s = State::Store->new(1);
    isa_ok(State::Store::new($s, 2), 'State::Store', 'new on a plain store object');
}

# ---- threads ----------------------------------------------------------------
SKIP: {
    skip 'this perl has no ithreads', 10 unless $Config{useithreads};
    skip 'threads.pm does not load', 10 unless eval { require threads; 1 };

    is(State::Store->CLONE_SKIP, 1, 'the class asks not to be cloned');

    my $shared = State::Store->new(HAMT::Map->new(a => 1));
    my ($seen, $own) = threads->create({ context => 'list' }, sub {
        my $fresh = State::Store->new(1)->swap(sub { $_[0] + 1 });
        my $usable = eval { $shared->current; 1 } ? 'usable' : 'dead';
        return ((blessed($shared) ? 'blessed' : 'unblessed') . " and $usable", $fresh->current);
    })->join;
    is($seen, 'unblessed and dead', 'a new thread does not get the parent\'s store');
    is($own, 2, 'and can make stores of its own');
    is($shared->current->get('a'), 1, 'the parent\'s store is intact after the thread has gone');
    is(State::Store::_live_blocks(), 1, 'and still its one block');

    # A subclass that asks to be cloned after all gets an object that is
    # blessed and dead: it must not be a second owner of the first
    # interpreter's value.
    {
        package Local::Cloned;
        our @ISA = ('State::Store');
        sub CLONE_SKIP { 0 }
    }
    my $gone = 0;
    {
        package Local::Once;
        sub DESTROY { $gone++ }
    }
    my $cloned = Local::Cloned->new(bless [], 'Local::Once');
    my ($what, $err) = threads->create({ context => 'list' }, sub {
        my $class = blessed($cloned) // 'unblessed';
        my $ok = eval { $cloned->current; 1 };
        my $e = $@;
        eval { $cloned->set(1) };
        return ($class . ($ok ? ' usable' : ' dead'), $e);
    })->join;
    is($what, 'Local::Cloned dead', 'a store cloned into a thread is blessed and unusable');
    like($err, qr/^State::Store::current: this store belongs to another thread/, 'and says whose it is');
    is($gone, 0, 'the thread ending does not destroy the parent\'s value');
    isa_ok($cloned->current, 'Local::Once', 'which the parent still holds');
    undef $cloned;
    is($gone, 1, 'and destroys once');
}

done_testing;
