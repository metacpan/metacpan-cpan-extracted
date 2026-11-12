use strict;
use warnings;
use Test::More;
use Object::Proto;

package SP;
sub upper { uc $_[0] }
sub to_int { int $_[0] }
package PC;
our @log;
sub _ptr { push @log, "tr:$_[1]" }
package main;

Object::Proto::register_type('Pos', sub { defined $_[0] && !ref $_[0] && $_[0] > 0 });

Object::Proto::define('SP',
    'neg:Int:default(-5)', 'negf:Num:default(-1.5)', 'q:default(\')',
    'tr:trigger()', 'co:Int:coerce(SP::to_int)', 'cn:coerce()', 'up:Str:coerce(SP::upper)',
    'pos:Pos:writer(set_pos)', 'plus:Int:writer(set_plus)',
);

my $o = SP->new;
is($o->neg, -5, 'a negative integer default');
is($o->negf, -1.5, 'a negative float default');
is($o->q, '', 'a lone quote as the default is the empty string');
ok(Object::Proto::slot_info('SP', 'tr')->{has_trigger}, 'trigger() with no name still marks the slot');
$o->tr(3);
is($o->tr, 3, 'and the slot sets without calling anything');
$o->co('7.9');
is($o->co, 7, 'a slot-level coerce callback runs on the setter');
is(SP->new(co => '3.5')->co, 3, 'and at construction');
ok(Object::Proto::slot_info('SP', 'cn')->{has_coerce}, 'coerce() with no name marks the slot');
$o->cn(5);
is($o->cn, 5, 'and the value passes through');
$o->up('abc');
is($o->up, 'ABC', 'a coerce callback on a Str slot');

$o->set_pos(2);
is($o->pos, 2, 'a writer on a registered type takes a passing value');
eval { $o->set_pos(-1) };
like($@, qr/Type constraint failed for 'pos': expected Pos/, 'and names the registered type when the value fails');
eval { $o->set_plus('x') };
like($@, qr/Type constraint failed for 'plus': expected Int/, 'or the builtin type');

Object::Proto::define('PC', 'co:Int:coerce(SP::to_int)', 'tr:Str:trigger(_ptr)', 'ty:Int', 'ps:Pos');
my $p = PC->new('2.5', 'x', 7, 1);
is($p->co, 2, 'positional construction coerces');
is_deeply(\@PC::log, ['tr:x'], 'and fires the trigger');
eval { PC->new('2.5', 'x', 'bad') };
like($@, qr/Type constraint failed for 'ty' in new\(\): expected Int/, 'and rejects a bad value by its builtin type');
eval { PC->new('2.5', 'x', 7, -1) };
like($@, qr/Type constraint failed for 'ps' in new\(\): expected Pos/, 'or by its registered type');

Object::Proto::define('SQ', 'trail:', 'nest:default((1))', 'dz:default()', 'e:clearer():predicate():reader():writer():arg():mystery(1)');
my $sq = SQ->new;
ok(Object::Proto::slot_info('SQ', 'trail'), 'a spec ending in a colon is a plain slot');
is($sq->nest, '(1)', 'nested parentheses in a default are kept');
ok(Object::Proto::slot_info('SQ', 'dz')->{has_default}, 'default() with nothing in it marks the slot');
ok(!defined $sq->dz, 'and leaves it undef');
$sq->e(1);
ok($sq->has_e, 'predicate() with no name takes the default name');
$sq->clear_e;
ok(!$sq->has_e, 'as does clearer()');
ok(!SQ->can('get_e'), 'reader() with no name installs nothing');
ok(!defined Object::Proto::slot_info('SQ', 'e')->{init_arg}, 'and arg() sets no init arg');
# A '(' that is never closed croaks, naming the spec, instead of the
# argument losing its last character
my $unterminated = 0;
for my $bad ('x:default(12', 'x:builder(', 'x:Str:trigger(a(b)', 'x:Int:default(1):reader(get') {
    my $class = 'Unterminated' . ++$unterminated;
    eval { Object::Proto::define($class, $bad) };
    like($@, qr/^Unterminated '\(' in slot spec '\Q$bad\E' at /, "unterminated '(' in '$bad' croaks");
}
eval { Object::Proto::role('UnterminatedRole', 'x:default(') };
like($@, qr/^Unterminated '\(' in slot spec 'x:default\(' at /, 'so does one in a role\'s slot');
Object::Proto::define('Terminated', 'a:default(12)', 'b:we)ird:default((1))', 'c(:default(3)');
my $t = Terminated->new;
is($t->a, 12, 'a closed argument keeps every character');
is($t->b, '(1)', 'a ) outside any argument is part of a modifier name, as before');
is(Terminated->can('c(')->($t), 3, 'and a ( in the property name opens nothing');

my $bare = SP::new();
isa_ok($bare, 'SP', 'new called as a plain function with no arguments');
is($bare->neg, -5, 'still fills the defaults');

my %usage = (
    define => [], prototype => [], set_prototype => [1], prototype_chain => [], has_own_property => [1],
    prototype_depth => [], lock => [], unlock => [], freeze => [], is_frozen => [], is_locked => [],
    clone => [], properties => [], slot_info => [1], parent => [], ancestors => [], register_type => [1],
    has_type => [], singleton => [], role => [], requires => [1], with => [1], does => [1],
    before => [1], after => [1], around => [1], import_accessors => [], import_accessor => [1],
);
for my $name (sort keys %usage) {
    my $f = \&{"Object::Proto::$name"};
    eval { $f->(@{ $usage{$name} }) };
    like($@, qr/^Usage: Object::Proto::$name/, "$name with too few arguments says how to call it");
}

done_testing;
