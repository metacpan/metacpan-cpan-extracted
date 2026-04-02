use strict;
use warnings;
use Test::More tests => 18;

# Clone edge cases: prototype chain, readonly, typed

BEGIN {
    require Object::Proto;
    Object::Proto::define('Clonable', qw(x y));
    Object::Proto::define('CloneRO', 'name:Str:readonly', 'tag:Str');
    Object::Proto::define('CloneLazy', 'data:Str:lazy:builder(_build_data)', 'label:Str');
}

use Object::Proto;

# --- Clone with prototype chain ---

my $proto = new Clonable 10, 20;
my $child = new Clonable 100;
$child->set_prototype($proto);

# Verify prototype resolution works before clone
is($child->y, 20, 'child inherits y from prototype');

my $cloned = Object::Proto::clone($child);
isa_ok($cloned, 'Clonable', 'clone of child is Clonable');
is($cloned->x, 100, 'clone copies own property x');
# Clone should copy the prototype reference
my $clone_proto = $cloned->prototype;
ok(defined $clone_proto, 'clone preserves prototype reference');
is($cloned->y, 20, 'clone inherits y through preserved prototype');

# Modifying clone doesn't affect original
$cloned->x(999);
is($child->x, 100, 'modifying clone does not affect original');

# --- Clone preserves readonly constraint ---

my $ro = new CloneRO name => 'immutable', tag => 'test';
my $ro_clone = Object::Proto::clone($ro);
is($ro_clone->name, 'immutable', 'readonly clone has copied value');
is($ro_clone->tag, 'test', 'non-readonly clone field works');

# Clone should still enforce readonly
eval { $ro_clone->name('changed') };
like($@, qr/readonly|Cannot modify/i, 'clone preserves readonly constraint');

# Non-readonly is still mutable on clone
$ro_clone->tag('updated');
is($ro_clone->tag, 'updated', 'clone non-readonly field is mutable');

# Original unchanged
is($ro->tag, 'test', 'original not affected by clone setter');

# --- Clone is not frozen even if original is ---

my $frozen_obj = new Clonable 1, 2;
Object::Proto::freeze($frozen_obj);
ok(Object::Proto::is_frozen($frozen_obj), 'original is frozen');

my $thawed = Object::Proto::clone($frozen_obj);
ok(!Object::Proto::is_frozen($thawed), 'clone is not frozen');
$thawed->x(42);
is($thawed->x, 42, 'clone is mutable after cloning frozen');

# --- Clone is not locked even if original is ---

my $locked_obj = new Clonable 3, 4;
Object::Proto::lock($locked_obj);
ok(Object::Proto::is_locked($locked_obj), 'original is locked');

my $unlocked = Object::Proto::clone($locked_obj);
ok(!Object::Proto::is_locked($unlocked), 'clone is not locked');

# --- Clone of lazy slot ---

package CloneLazy;
sub _build_data { return 'built_data' }

package main;

my $lazy = new CloneLazy label => 'test';
# Don't access data yet - it should be lazy
my $lazy_clone = Object::Proto::clone($lazy);
is($lazy_clone->label, 'test', 'clone copies non-lazy field');

# Access lazy field on clone - should trigger builder
is($lazy_clone->data, 'built_data', 'clone lazy field triggers builder on access');
