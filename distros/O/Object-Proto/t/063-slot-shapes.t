use strict;
use warnings;
use Test::More;
use Scalar::Util qw(isweak);
use Object::Proto;

package SS;
sub id { $_[0] }
sub _bl { 11 }
package main;

BEGIN {
    Object::Proto::define('SU', 'a', 'b');
    Object::Proto::define('ST', 'a:Int', 'w:weak:writer(set_w)', 'r:reader(get_r):writer(set_r)', 'l:Int:lazy:builder(_bl):reader(get_l)', 'c:clearer', 'd:predicate');
    *ST::_bl = \&SS::_bl;
    Object::Proto::import_accessors('ST', undef, 'main');
}

my $u = SU->new(a => 1, b => 2);
$#$u = 0;
ok(!defined $u->a, 'a truncated untyped object reads undef');
is($u->a(5), 5, 'and sets');
is($u->a, 5, 'and reads the value back');
$#$u = 30;
is($u->b(6), 6, 'an untyped object extended with empty slots sets');
is($u->b, 6, 'and reads');
my $u2 = SU->new;
$#$u2 = 0;
$#$u2 = 30;
ok(!defined $u2->a, 'an empty slot reads undef');
is($u2->a(3), 3, 'and sets');

my $t = ST->new(a => 1, r => 'r');
$#$t = 0;
ok(!defined $t->a, 'a truncated typed object reads undef');
is($t->a(5), 5, 'and sets');
is($t->a, 5, 'and reads the value back');
ok(!defined $t->get_r, 'a reader on a truncated object reads undef');
is($t->set_r(7), 7, 'a writer on a truncated object sets');
is($t->get_r, 7, 'and the reader sees it');
my $ref = {};
is($t->set_w($ref), $ref, 'a weak writer on a truncated object sets');
ok(isweak($t->[Object::Proto::slot_info('ST', 'w')->{index}]), 'weakly');
ok(!defined $t->get_l, 'a lazy builder reader on a truncated object reads undef without building');
my $t2 = ST->new;
$#$t2 = 0;
$#$t2 = 30;
is($t2->set_r(8), 8, 'a writer into an empty slot');
is($t2->get_r, 8, 'is read back');
is($t2->set_w($ref), $ref, 'a weak writer into an empty slot');
ok(isweak($t2->[Object::Proto::slot_info('ST', 'w')->{index}]), 'weakly');
my $t3 = ST->new;
ok(!defined $t3->get_r, 'a reader on an unset slot with no prototype reads undef');
is($t3->get_l, 11, 'a lazy builder reader builds');
is($t3->get_l, 11, 'and reads the built value');

my $p = ST->new(r => 'from proto');
my $t4 = ST->new;
$t4->set_prototype($p);
is($t4->get_r, 'from proto', 'a reader follows the prototype chain');
$t4->set_prototype([]);
ok(!defined $t4->a, 'an empty array as prototype ends the chain');

my @chain = map { ST->new } 0 .. 101;
$chain[$_]->set_prototype($chain[$_ + 1]) for 0 .. 100;
my @warned;
{
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    ok(!defined $chain[0]->a, 'a chain over a hundred deep reads undef');
}
like($warned[0], qr/Prototype chain too deep \(max 100 levels\)/, 'and warns');
is(Object::Proto::prototype_depth($chain[0]), 100, 'prototype_depth stops at a hundred');
is(scalar @{ Object::Proto::prototype_chain($chain[0]) }, 100, 'as does prototype_chain');

my $x = ST->new;
my $y = ST->new;
$x->set_prototype($y);
$y->set_prototype($x);
is(scalar @{ Object::Proto::prototype_chain($x) }, 2, 'prototype_chain stops at a cycle');
is(Object::Proto::prototype_depth($x), 2, 'prototype_depth stops at a cycle');
eval { Object::Proto::prototype_chain(42) };
like($@, qr/Not an object/, 'prototype_chain wants an object');
eval { Object::Proto::prototype_depth(42) };
like($@, qr/Not an object/, 'prototype_depth wants an object');
Object::Proto::unlock($x);
ok(!Object::Proto::is_locked($x), 'unlocking an object never locked is fine');

eval { ST->can('get_r')->(42) };
like($@, qr/Not an object/, 'a reader wants an object');
eval { ST->can('set_r')->(42, 1) };
like($@, qr/Not an object/, 'a writer wants an object');
eval { ST->can('clear_c')->(42) };
like($@, qr/Not an object/, 'a clearer wants an object');
eval { ST->can('has_d')->(42) };
like($@, qr/Not an object/, 'a predicate wants an object');

my $f = ST->new(a => 1);
$#$f = 0;
ok(!defined a($f), 'a function accessor on a truncated object reads undef');
is(a($f, 3), 3, 'and sets');
is(a($f), 3, 'and reads it back');
my $g = ST->new(a => 1);
$#$g = 0;
ok(!defined a(SS::id($g)), 'the unoptimised function getter on a truncated object reads undef');
is(a(SS::id($g), 4), 4, 'the unoptimised function setter on a truncated object sets');
is(a(SS::id($g)), 4, 'and the unoptimised getter reads it');
my $h = ST->new(a => 1);
$#$h = 0;
$#$h = 30;
is(a($h, 5), 5, 'the function setter into an empty slot');
is(a($h), 5, 'reads back');
my $h2 = ST->new(a => 1);
$#$h2 = 0;
$#$h2 = 30;
is(a(SS::id($h2), 6), 6, 'the unoptimised function setter into an empty slot');
is(a($h2), 6, 'reads back');
eval { a(42) };
like($@, qr/Not an object/, 'the function getter wants an object');
my $sref = \my $s;
eval { a($sref) };
like($@, qr/Not an object/, 'and not a reference to a scalar');
eval { a(42, 1) };
like($@, qr/Not an object/, 'the function setter wants an object');
eval { a($sref, 1) };
like($@, qr/Not an object/, 'and not a reference to a scalar');
eval { a(SS::id(42)) };
like($@, qr/Not an object/, 'the unoptimised function getter wants an object');
eval { a(SS::id(42), 1) };
like($@, qr/Not an object/, 'as does the unoptimised setter');
my $code = \&main::a;
eval { $code->(42) };
like($@, qr/Not an object/, 'and the function accessor called as a code reference');

done_testing;
