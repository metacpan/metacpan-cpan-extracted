use strict;
use warnings;
use Test::More;
use Object::Proto;

package LZ;
sub id { $_[0] }
sub half { int($_[0] / 2) }
sub _build_lb { 'lb' }
sub _build_rb { $_[0]->rb_source }
sub _build_nb { $_[0]->nb_source }
sub _build_bad { 'abc' }
package main;

BEGIN {
    Object::Proto::register_type('Pos', sub { defined $_[0] && !ref $_[0] && $_[0] > 0 });
    Object::Proto::define('LZ',
        'ld:lazy:default(5):clearer', 'la:lazy:default([]):clearer', 'lh:lazy:default({}):clearer', 'ln:lazy',
        'lb:lazy:builder(_build_lb):clearer',
        'rb_source', 'rb:Int:lazy:builder(_build_rb):coerce(LZ::half):reader(get_rb)',
        'nb_source', 'nb:Int:builder(_build_nb):coerce(LZ::half)',
        'rq:Int:lazy:builder(_build_bad):reader(get_rq)',
        'nb2:builder(_build_lb)', 'rb2:lazy:builder(_build_lb):reader(get_rb2)', 'lz:Int:lazy',
    );
    Object::Proto::define('LB', 'nq:Int:builder(_build_bad)');
    *LB::_build_bad = \&LZ::_build_bad;
    Object::Proto::import_accessors('LZ', undef, 'main');
}

my $o = LZ->new(rb_source => 9, nb_source => 8);
is($o->nb, 4, 'a builder value is coerced at construction');
is($o->nb2, 'lb', 'a builder without a type');
is($o->get_rb2, 'lb', 'a lazy builder reader without a type');
ok(!defined $o->lz, 'a typed lazy slot with nothing to build reads undef');
$o->clear_ld;
is(ld($o), 5, 'a lazy default through the function getter');
is(ld($o), 5, 'and it stays');
$o->clear_la;
is_deeply(la($o), [], 'a lazy array default through the function getter');
$o->clear_lh;
is_deeply(lh($o), {}, 'a lazy hash default through the function getter');
ok(!defined ln($o), 'a lazy slot with nothing to build reads undef');
$o->clear_lb;
is(lb($o), 'lb', 'a lazy builder through the function getter');
is($o->get_rb, 4, 'a lazy builder reader coerces what it builds');

my $u = LZ->new(rb_source => 9, nb_source => 8);
$u->clear_ld;
is(ld(LZ::id($u)), 5, 'a lazy default through the unoptimised function getter');
$u->clear_la;
is_deeply(la(LZ::id($u)), [], 'a lazy array default through the unoptimised function getter');
$u->clear_lh;
is_deeply(lh(LZ::id($u)), {}, 'a lazy hash default through the unoptimised function getter');
ok(!defined ln(LZ::id($u)), 'nothing to build through the unoptimised function getter');
$u->clear_lb;
is(lb(LZ::id($u)), 'lb', 'a lazy builder through the unoptimised function getter');

eval { $o->get_rq };
like($@, qr/Type constraint failed for 'rq' in builder: expected Int/, 'a lazy builder reader checks the type');
eval { LB->new };
like($@, qr/Type constraint failed for 'nq' in builder: expected Int/, 'a builder at construction checks the type');

Object::Proto::define('LT', 'x:Int:lazy:default(5):clearer', 'y:ArrayRef:lazy:default([]):clearer',
    'z:HashRef:lazy:default({}):clearer', 'bad:Int:lazy:default(abc):clearer', 'pos:Pos:lazy:default(-1):clearer',
    'rp:Pos:lazy:builder(_build_rp):reader(get_rp):clearer', 'np:Pos:builder(_build_np)', 'np_source');
sub LT::_build_rp { -1 }
sub LT::_build_np { $_[0]->np_source }
my $t = LT->new(np_source => 1);
$t->clear_x;
is($t->x, 5, 'a typed lazy default');
$t->clear_y;
is_deeply($t->y, [], 'a typed lazy array default');
$t->clear_z;
is_deeply($t->z, {}, 'a typed lazy hash default');
$t->clear_bad;
eval { $t->bad };
like($@, qr/Type constraint failed for lazy 'bad': expected Int/, 'a lazy default is checked against the builtin type');
$t->clear_pos;
eval { $t->pos };
like($@, qr/Type constraint failed for lazy 'pos': expected Pos/, 'and against a registered type');
eval { $t->get_rp };
like($@, qr/Type constraint failed for 'rp' in builder: expected Pos/, 'a lazy builder reader names a registered type');
eval { LT->new(np_source => -1) };
like($@, qr/Type constraint failed for 'np' in builder: expected Pos/, 'as does a builder at construction');

done_testing;
