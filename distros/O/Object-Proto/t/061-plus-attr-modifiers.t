use strict;
use warnings;
use Test::More;
use Scalar::Util qw(isweak);
use Object::Proto;

our @log;
package PA;
sub up { uc $_[0] }
sub _pt { push @main::log, "pt:$_[1]" }
sub _pb { 'built' }
package PB;
sub low { lc $_[0] }
sub _ct { push @main::log, "ct:$_[1]" }
package main;

Object::Proto::define('PA',
    't:Str:trigger(_pt)', 'c:Str:coerce(PA::up)', 'b:Str:lazy:builder(_pb)', 'w:weak',
    'k:clearer(clr_k):predicate(has_k_p)', 'r:reader(get_r):writer(set_r):arg(rr)',
    'n:Int:default(1)', 'x', 'y');
Object::Proto::define('PB', extends => 'PA',
    '+t:trigger(_ct)', '+c:coerce(PB::low)', '+n:Num:required',
    '+k:clearer(clr_k2):predicate(has_k2)', '+r:reader(get_r2):writer(set_r2):arg(rr2)',
    '+x:weak', '+y:Int');

my $pa = PA->new(t => 'z', c => 'MiXed', rr => 'r1');
is_deeply(\@log, ['pt:z'], 'the parent trigger fires for the parent');
is($pa->c, 'MIXED', 'the parent coercion');
is($pa->get_r, 'r1', 'the parent reader and init arg');
is($pa->b, 'built', 'the parent lazy builder');

@log = ();
my $pb = PB->new(t => 'a', c => 'MiXed', rr2 => 'r2', n => 2.5);
is_deeply(\@log, ['ct:a'], 'the child trigger replaces the parent one');
is($pb->c, 'mixed', 'the child coercion replaces the parent one');
is($pb->get_r2, 'r2', 'the child reader and init arg replace the parent ones');
is($pb->set_r2('r3'), 'r3', 'the child writer');
is($pb->get_r2, 'r3', 'writes the slot');
is($pb->n, 2.5, 'the child type replaces the parent one');
eval { $pb->n('abc') };
like($@, qr/Type constraint failed for 'n': expected Num/, 'and is checked');
is(PB->new(rr2 => 1)->n, 1, 'a required slot with an inherited default is satisfied by the default');
$pb->k(1);
ok($pb->has_k2, 'the child predicate name');
$pb->clr_k2;
ok(!$pb->has_k2, 'the child clearer name');
my $ref = {};
$pb->x($ref);
ok(isweak($pb->[Object::Proto::slot_info('PB', 'x')->{index}]), 'weak added to an inherited slot');
eval { $pb->y('abc') };
like($@, qr/Type constraint failed for 'y': expected Int/, 'a type added to an inherited slot');
is($pb->b, 'built', 'the inherited lazy builder still builds');

Object::Proto::define('PC2', 'c2', 'b2:Str:builder(_pb)', 'k2:clearer:predicate', 'x2', 'y2', 'z2');
*PC2::_pb = \&PA::_pb;
Object::Proto::define('PD', extends => 'PC2', '+c2:coerce(PB::low)', '+b2:builder(_cb)', '+x2:lazy', '+y2:private',
    '+k2:clearer(ck2):predicate(pk2)', '+z2:reader(get_z2):writer(set_z2):arg(zz)');
package PD;
sub _cb { 'child built' }
sub peek_y2 { $_[0]->y2 }
package main;
my $pd = PD->new(zz => 'z');
is($pd->c2('MiXed'), 'mixed', 'coerce added to a slot that had none');
is($pd->b2, 'child built', 'a builder replaced');
is($pd->get_z2, 'z', 'a reader, writer and init arg added to a plain slot');
is($pd->set_z2('zz'), 'zz', 'the writer');
$pd->k2(1);
ok($pd->pk2, 'a predicate name given to a bare predicate');
$pd->ck2;
ok(!$pd->pk2, 'and a clearer name to a bare clearer');
ok(Object::Proto::slot_info('PD', 'x2')->{is_lazy}, 'lazy added');
is($pd->peek_y2, undef, 'private added, readable from the class');
eval { $pd->y2 };
like($@, qr/cannot call private attribute y2 on PD from main/, 'and not from outside');
Object::Proto::define('PE', extends => 'PC2', '+k2:clearer:predicate');
my $pe = PE->new(k2 => 1);
ok($pe->has_k2, 'a bare predicate on a slot that had one keeps the default name');
$pe->clear_k2;
ok(!$pe->has_k2, 'as does a bare clearer');

package UD;
sub x { 'mine' }
package main;
Object::Proto::define('UD', 'x:Int', 'y');
is(UD->new->x, 'mine', 'a sub of the class with the name of a typed slot is kept');
Object::Proto::define('UE', extends => ['PC2', 42, undef], 'own');
is_deeply([Object::Proto::parent('UE')], ['PC2'], 'entries of an extends list that are not names are passed over');

my $info = Object::Proto::slot_info('PB', 'r');
is($info->{init_arg}, 'rr2', 'slot_info shows the replaced init arg');
is(Object::Proto::slot_info('PB', 'n')->{is_required}, 1, 'and the added required flag');

done_testing;
