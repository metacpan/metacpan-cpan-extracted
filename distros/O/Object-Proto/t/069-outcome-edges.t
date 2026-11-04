use strict;
use warnings;
use Test::More;
use Scalar::Util qw(isweak);
use Object::Proto;

package OE;
our @log;
sub id { $_[0] }
sub up { uc $_[0] }
sub to_int { int $_[0] }
sub _build_undef { undef }
sub _build_lzb { 7 }
BEGIN {
    Object::Proto::define('OE', 'plain', 'typed:Int', 'wk:weak', 'wt:Int:weak', 'ro:Int:readonly',
        'ar:ArrayRef', 'hr:HashRef', 'cr:CodeRef', 'bo:Bool', 'nu:Num', 'wh:Whatever',
        'tw:trigger():writer(set_tw)', 'rw:required:writer(set_rw)', 'cw:Int:coerce(OE::to_int):writer(set_cw)', 'ww:weak:writer(set_ww)',
        'lr:lazy:reader(get_lr)', 'lb:Int:lazy:builder(_build_undef)', 'le:lazy:default():clearer', 'lt:Int:lazy:default():clearer',
        'rd:reader(get_rd)', 'c:clearer', 'd:predicate', 'ro2:readonly', 'lzb:Int:lazy:builder(_build_lzb):reader(get_lzb)', 'tn:trigger()');
    Object::Proto::define('OP2', 'tn:trigger()', 'x');
    Object::Proto::import_accessors('OE', 'f_', 'main');
}
sub get_plain { plain($_[0]) }
sub set_plain { plain($_[0], $_[1]) }
sub set_typed { typed($_[0], $_[1]) }
sub set_wk_const { wk($_[0], 'c') }
sub set_ro_const { ro($_[0], 1) }
sub set_wt_const { wt($_[0], 1) }
sub set_tn { tn($_[0], $_[1]) }

package Twice;
BEGIN { Object::Proto->import; Object::Proto->import }

package main;

my $o = OE->new(rw => 1);
my $h = bless {}, 'OE';
my %wrong = (
    'the untyped function getter' => sub { OE::get_plain($h) },
    'the untyped function setter' => sub { OE::set_plain($h, 1) },
    'the typed function setter'   => sub { OE::set_typed($h, 1) },
    'the untyped accessor'        => sub { OE->can('plain')->($h) },
    'the typed accessor'          => sub { OE->can('typed')->($h) },
    'a reader'                    => sub { OE->can('get_rd')->($h) },
    'a writer'                    => sub { OE->can('set_tw')->($h, 1) },
    'a clearer'                   => sub { OE->can('clear_c')->($h) },
    'a predicate'                 => sub { OE->can('has_d')->($h) },
    'the function accessor'       => sub { f_plain($h) },
    'the unoptimised function accessor' => sub { my $code = \&main::f_plain; $code->($h) },
    'prototype'                   => sub { Object::Proto::prototype($h) },
    'set_prototype'               => sub { Object::Proto::set_prototype($h, 1) },
    'prototype_chain'             => sub { Object::Proto::prototype_chain($h) },
    'prototype_depth'             => sub { Object::Proto::prototype_depth($h) },
    'has_own_property'            => sub { Object::Proto::has_own_property($h, 'plain') },
);
for my $what (sort keys %wrong) {
    eval { $wrong{$what}->() };
    like($@, qr/Not an object/, "$what refuses a hash blessed into the class");
}

my $l = OE->new(rw => 1);
Object::Proto::lock($l);
is(OE::set_plain($l, 1), 1, 'a locked object takes the untyped function setter');
is(OE::set_typed($l, 2), 2, 'and the typed one');
is($l->plain(3), 3, 'and the untyped method');
is($l->typed(4), 4, 'and the typed method');
is($l->set_tw(5), 5, 'and a writer');
is($l->clear_c, $l, 'and a clearer');
$l->set_prototype(undef);
ok(!defined $l->prototype, 'and set_prototype');
ok(!Object::Proto::is_frozen($l), 'and is not frozen');

is(OE->new(rw => 1, tw => 1)->tw, 1, 'a trigger() slot with no callback is set by name at construction');
is($o->set_tw(5), 5, 'and by its writer');
is(OE::set_tn($o, 6), 6, 'and by the typed function setter');
is(OP2->new(7, 8)->tn, 7, 'and positionally at construction');
is($o->set_rw(2), 2, 'a required writer takes a defined value');
is($o->set_ww('s'), 's', 'a weak writer takes a plain value');
my $n = OE->new(rw => 1);
$#$n = 0;
$#$n = 30;
is($n->set_ww('s'), 's', 'into an empty slot too');
ok(!defined $o->get_lr, 'a lazy reader with nothing to build reads undef');
ok(!defined $o->lb, 'a typed lazy builder may return undef');
$o->clear_le;
ok(!defined f_le($o), 'a lazy default() with nothing in it reads undef through the function getter');
my $o2 = OE->new(rw => 1);
$o2->clear_le;
ok(!defined f_le(OE::id($o2)), 'and through the unoptimised one');
$o->clear_lt;
ok(!defined $o->lt, 'and through a typed accessor');
is($o->set_cw('7.9'), 7, 'a writer coerces');
is($o->wk('str'), 'str', 'a weak slot takes a plain value by method');
is(OE::set_wk_const($o), 'c', 'a constant on an untyped weak slot goes through the typed setter');
eval { OE::set_ro_const($o) };
like($@, qr/Cannot modify readonly slot 'ro'/, 'a constant on a readonly slot is refused at runtime');
is(OE::set_wt_const($o), 1, 'a constant on a typed weak slot goes through the typed setter');
is(f_plain($o, 1, 2), 1, 'a function setter with two values falls back and sets the first');

ok(Twice->can('object'), 'importing twice into a package keeps the first import');
ok(Twice->can('with'), 'for every exported name');
Object::Proto::import_accessors('OE', 'g_', undef);
ok(main->can('g_plain'), 'import_accessors with an undef package uses the caller');
Object::Proto::import_accessor('OE', 'plain', undef);
ok(main->can('plain'), 'import_accessor with an undef alias uses the property name');
ok(Object::Proto::register_type('NoCoerce', sub { 1 }, undef), 'register_type with an undef coercion');

is(Object::Proto::slot_info('OE', 'wh')->{has_type}, 0, 'an eight letter name that is not ArrayRef is no type');
eval { $o->typed('99999999999999999999999') };
like($@, qr/expected Int/, 'Int rejects a number too large to parse');
eval { $o->nu('1e999') };
like($@, qr/expected Num/, 'Num rejects a number too large to parse');
eval { $o->bo('0') };
like($@, qr/expected Bool/, 'Bool rejects the string 0');
$o->bo(undef);
ok(!defined $o->bo, 'Bool takes undef');
eval { $o->bo(0.0) };
like($@, qr/expected Bool/, 'Bool rejects a float zero');
eval { $o->ar('x') };
like($@, qr/expected ArrayRef/, 'ArrayRef rejects a plain value');
eval { $o->hr('x') };
like($@, qr/expected HashRef/, 'HashRef rejects a plain value');
eval { $o->cr([]) };
like($@, qr/expected CodeRef/, 'CodeRef rejects an array reference');

Object::Proto::define('OK9', 'dash:default(-)', 'p9:abcdefghi(1)', 'w6:abcdef(1)', 'a3:abc(1)', 's9:abcdefghi');
my $k = OK9->new;
is($k->dash, '-', 'a lone minus as a default is the string');
ok(!defined $k->p9, 'an unknown nine letter modifier with an argument is ignored');
ok(!defined $k->w6, 'as is a six letter one');
ok(!defined $k->a3, 'and a three letter one');
ok(!Object::Proto::slot_info('OK9', 's9')->{has_type}, 'and a nine letter word is no type');

package OL;
sub _t { push @OE::log, 't' }
package main;
Object::Proto::define('OL', 'd:default(5)', 't:trigger(_t)', 'c:coerce(OE::up)');
Object::Proto::define('OM', extends => 'OL', '+d:default()', '+t:trigger()', '+c:coerce()');
my $m = OM->new;
ok(!defined $m->d, 'default() on an inherited slot drops the default');
$m->t(1);
is_deeply(\@OE::log, [], 'trigger() on an inherited slot drops the trigger');
is($m->c('abc'), 'abc', 'coerce() on an inherited slot drops the coercion');
Object::Proto::define('OL2', 'pt:trigger(_t)', 'pc:coerce(OE::up)', 'pro:readonly', 'pl:lazy', 'pq:required');
Object::Proto::define('OM2', extends => 'OL2', 'own');
my $m2 = OM2->new(pq => 1);
eval { $m2->pro(1) };
like($@, qr/Cannot modify readonly slot 'pro'/, 'an inherited readonly slot without a type');
is($m2->pc('abc'), 'ABC', 'an inherited coerce slot without a type');

Object::Proto::define('OS', 'a');
Object::Proto::singleton('OS');
my $s = OS->instance;
is(OS->instance, $s, 'a singleton without BUILD');

my $e = OE->new(rw => 1);
$#$e = -1;
ok(!defined $e->plain, 'an emptied object reads undef by method');
ok(!defined $e->get_rd, 'and by reader');
ok(!defined Object::Proto::prototype($e), 'and has no prototype');
ok(!Object::Proto::has_own_property($e, 'plain'), 'and no own property');
ok(!defined $n->typed, 'an empty slot reads undef by a typed method');
ok(!defined OE::get_plain($n), 'and by the untyped function getter');
ok(!defined f_plain($n), 'and by the function accessor');
ok(!defined f_plain(OE::id($n)), 'and by the unoptimised function accessor');
ok(!defined f_le(OE::id($n)), 'and a lazy slot with nothing to build by the unoptimised function accessor');
ok(!defined $n->get_rd, 'and by a reader');
ok(!$n->has_d, 'and a predicate is false');
is($n->get_lzb, 7, 'a lazy builder reader builds into an empty slot');
my $p = OE->new(rw => 1);
$p->set_prototype({});
ok(!defined OE::get_plain($p), 'a hash as prototype ends the chain for the function getter');
ok(!defined $p->plain, 'and the method');
ok(!defined $p->typed, 'and the typed method');
ok(!defined $p->get_rd, 'and a reader');
is(scalar @{ Object::Proto::prototype_chain($p) }, 1, 'and prototype_chain');
is(Object::Proto::prototype_depth($p), 0, 'and prototype_depth');
my @holes;
$holes[2] = 1;
is_deeply(Object::Proto::clone(\@holes), [undef, undef, 1], 'clone fills the holes of an array');

Object::Proto::define('OMany', map { "p$_" } 1 .. 70);
Object::Proto::import_accessors('OMany', 'm_', 'main');
ok(main->can('m_p70'), 'seventy function accessors fit the registry');
Object::Proto::define('OP3', 'x', 'y');
is(OP3::new(42)->x, 42, 'new as a plain function with a number first takes it as a value');
is(OP3::new($o)->x, $o, 'and a reference');

package OX;
BEGIN { *OX::x = \&Object::Proto::clone }
package main;
Object::Proto::define('OX', 'x:Int', 'y');
isa_ok(OX->new->x, 'OX', 'an XSUB of another kind with the name of a typed slot is kept, so x clones');

package OD;
sub DEMOLISH { 1 }
package OA;
sub m { (1, 2) }
sub n { (4, 5) }
package main;
Object::Proto::define('OD', 'a');
my @warned;
{
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    my $d = OD->new;
    undef $d;
}
is_deeply(\@warned, [], 'a DEMOLISH that returns warns nothing');
Object::Proto::define('OA', 'a');
Object::Proto::around('OA::m', sub { my $orig = shift; ($orig->(@_), 3) });
is_deeply([OA->new->m], [1, 2, 3], 'an around modifier in list context');
my @after;
Object::Proto::before('OA::n', sub { push @after, 'b' });
for my $i (1 .. 3) {
    Object::Proto::after('OA::n', sub { push @after, $i });
}
is_deeply([OA->new->n], [4, 5], 'a modified method in list context');
is_deeply(\@after, ['b', 1, 2, 3], 'three after modifiers run in order');
for my $kind (qw(before after around)) {
    my $f = \&{"Object::Proto::$kind"};
    eval { $f->('OA::n', []) };
    like($@, qr/Second argument must be a code reference/, "$kind refuses a reference that is not code");
}
eval { Object::Proto::define('OF', extends => \'OL', 'a') };
like($@, qr/parent class 'SCALAR\(/, 'extends with a reference to a scalar names it as a class');
is_deeply([Object::Proto::ancestors('Nope')], [], 'ancestors of an undefined class is empty');

done_testing;
