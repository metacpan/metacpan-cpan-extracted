#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed);
use State::Store;
use HAMT::Map;
use HAMT::Vector;

# new, get and set, over every kind of value a scalar can be.

{
    my $s = State::Store->new;
    isa_ok($s, 'State::Store');
    is($s->current, undef, 'a store made with nothing holds undef');
    my @got = $s->current;
    is(scalar @got, 1, 'which is one value in list context, not none');

    is(State::Store->new(undef)->current, undef, 'as does one made with undef');
    is(State::Store->new(0)->current, 0, 'a false value is a value');
    is(State::Store->new('')->current, '', 'so is the empty string');
}

{
    my $s = State::Store->new(1);
    is($s->current, 1, 'new with a value holds it');
    is(refaddr($s->set(2)), refaddr($s), 'set returns the store');
    is($s->current, 2, 'and the value is the new one');
    is($s->set(3)->set(4)->current, 4, 'so calls chain');
    $s->set(5);
    is($s->current, 5, 'set in void context has done its work');
    is($s->set(undef)->current, undef, 'a value can be set back to undef');
}

for my $case (['an integer', 42], ['a negative', -7], ['a float', 1.5],
              ['a string', 'hello'], ['a wide string', "sm\x{263a}le"],
              ['a string with a nul', "a\0b"], ['a long string', 'x' x 100_000]) {
    my ($name, $value) = @$case;
    my $s = State::Store->new('start');
    $s->set($value);
    is($s->current, $value, "$name is held");
    is(length($s->current), length($value), '  at its full length');
}

{
    my $s = State::Store->new("caf\x{e9}");
    my $up = "caf\x{e9}";
    utf8::upgrade($up);
    is($s->current, $up, 'a string compares the same in either encoding');
    ok(!utf8::is_utf8($s->current), 'and is held as it was given');
}

{
    my $array = [1, 2, 3];
    my $hash  = { a => 1 };
    my $code  = sub { 'called' };
    my $obj   = bless { n => 1 }, 'Local::Thing';
    my $s = State::Store->new;
    is($s->set($array)->current, $array, 'an array reference is held as that reference');
    is($s->set($hash)->current, $hash, 'a hash reference');
    is($s->set($code)->current->(), 'called', 'a code reference');
    is($s->set($obj)->current, $obj, 'an object');
    is(blessed($s->current), 'Local::Thing', 'still blessed');
    my $sref = \"text";
    is($s->set($sref)->current, $sref, 'a scalar reference');
    is(${ $s->current }, 'text', 'to what it referred to');
    my $glob = \*STDOUT;
    is($s->set($glob)->current, $glob, 'a glob reference');
    my $re = qr/a+/;
    ok('caaat' =~ $s->set($re)->current, 'a regexp');
}

# The intended case.
{
    my $m = HAMT::Map->new(a => 1, b => 2);
    my $s = State::Store->new($m);
    isa_ok($s->current, 'HAMT::Map');
    is($s->current->get('b'), 2, 'a HAMT map in a store is still that map');
    is($s->current->count, 2, 'with its count');
    ok($s->current->equals($m), 'equal to the one stored');
    is(refaddr($s->current), refaddr($m), 'and the same object');
    $s->set($s->current->set(c => 3));
    is($s->current->count, 3, 'an update stored back is the new version');
    is($m->count, 2, 'and the first version is what it was');

    my $v = HAMT::Vector->new(1 .. 100);
    $s->set($v);
    is($s->current->get(99), 100, 'a vector likewise');
}

# A store is a value like any other.
{
    my $inner = State::Store->new('deep');
    my $outer = State::Store->new($inner);
    is($outer->current->current, 'deep', 'a store inside a store');
    $inner->set('deeper');
    is($outer->current->current, 'deeper', 'which is the same store, seen through it');
}

# What the variable is and what the store holds are two things.
{
    my $value = 'first';
    my $s = State::Store->new($value);
    $value = 'changed';
    is($s->current, 'first', 'changing the variable a value came from does not change the store');
    my $got = $s->current;
    $got .= ' and more';
    is($s->current, 'first', 'nor does changing a copy of what get returned');
}

# Tied and magical values are read once.
{
    package Local::Counter;
    sub TIESCALAR { my $n = 0; bless \$n, shift }
    sub FETCH { ${ $_[0] }++; 'fetched' }
    sub STORE { }
    package main;
    tie my $tied, 'Local::Counter';
    my $s = State::Store->new('start');
    $s->set($tied);
    is($s->current, 'fetched', 'a tied scalar stores what it fetches');
    is(${ tied $tied }, 1, 'and is fetched once');
    ok(!tied(${ \$s->current }), 'the stored value is not tied');

    # A tied scalar that has never been read looks undefined until it is.
    tie my $unread, 'Local::Counter';
    my $u = State::Store->new(undef);
    $u->set($unread);
    is($u->current, 'fetched', 'a tied scalar stored over undef is read, not taken for undef');
    is(${ tied $unread }, 1, 'once');
    $u->swap(sub { $unread });
    is($u->current, 'fetched', 'and one returned from a swap that holds the same string is no change');
}

# Arguments.
ok(!eval { State::Store->new(1, 'history'); 1 }, 'an option with no value dies');
like($@, qr/^State::Store::new: odd number of options/, 'saying so');
ok(!eval { State::Store->new(1, colour => 'red'); 1 }, 'an unknown option dies');
like($@, qr/^State::Store::new: unknown option "colour"/, 'naming it');
ok(!eval { State::Store->new->set; 1 }, 'set with no value dies');
like($@, qr/Usage: State::Store::set\(self, value\)/, 'with the usage');
ok(!eval { State::Store->new->current(1); 1 }, 'current with an argument dies');
like($@, qr/Usage: State::Store::current\(self\)/, 'with the usage');
ok(!State::Store->can('get'), 'and there is no get: the value is read with current');

done_testing;
