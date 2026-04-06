use strict;
use warnings;
use Test::More tests => 49;

# Deep clone: references must not be shared between original and clone

BEGIN {
    require Object::Proto;
    Object::Proto::define('DeepFlat',   qw(name age));
    Object::Proto::define('DeepArray',  qw(name tags));
    Object::Proto::define('DeepHash',   qw(name meta));
    Object::Proto::define('DeepNested', qw(name data));
    Object::Proto::define('DeepObj',    qw(name child));
    Object::Proto::define('DeepCirc',   qw(name peers));
    Object::Proto::define('DeepMixed',  qw(name scores meta notes));
}

use Object::Proto;

# ---------------------------------------------------------------
# 1. Scalars are independent (sanity check - should pass already)
# ---------------------------------------------------------------

my $flat = new DeepFlat name => 'Alice', age => 30;
my $flat_clone = Object::Proto::clone($flat);

$flat_clone->name('Bob');
$flat_clone->age(99);

is($flat->name, 'Alice', 'scalar: original name unchanged after clone mutation');
is($flat->age,  30,      'scalar: original age unchanged after clone mutation');
is($flat_clone->name, 'Bob', 'scalar: clone name updated');
is($flat_clone->age,  99,    'scalar: clone age updated');

# ---------------------------------------------------------------
# 2. Array reference - mutations must NOT leak to original
# ---------------------------------------------------------------

my $orig_tags = ['perl', 'xs'];
my $arr = new DeepArray name => 'Foo', tags => $orig_tags;
my $arr_clone = Object::Proto::clone($arr);

push @{ $arr_clone->tags }, 'deep';

is(scalar @{ $arr->tags }, 2,
    'array: push on clone does not grow original array');
is($arr->tags->[0], 'perl', 'array: original first element intact');
is($arr->tags->[1], 'xs',   'array: original second element intact');

is(scalar @{ $arr_clone->tags }, 3,  'array: clone has new element');
is($arr_clone->tags->[2], 'deep',    'array: clone new element correct');

# ---------------------------------------------------------------
# 3. Hash reference - mutations must NOT leak to original
# ---------------------------------------------------------------

my $orig_meta = { lang => 'perl', level => 'xs' };
my $hash = new DeepHash name => 'Bar', meta => $orig_meta;
my $hash_clone = Object::Proto::clone($hash);

$hash_clone->meta->{level} = 'pure';
$hash_clone->meta->{extra} = 'new_key';

is($hash->meta->{level}, 'xs',  'hash: original level unchanged');
ok(!exists $hash->meta->{extra}, 'hash: new key not in original');
is($hash_clone->meta->{level}, 'pure',    'hash: clone level updated');
is($hash_clone->meta->{extra}, 'new_key', 'hash: clone has new key');

# ---------------------------------------------------------------
# 4. Nested data structure (arrayref of hashrefs)
# ---------------------------------------------------------------

my $orig_data = [ { x => 1, y => 2 }, { x => 3, y => 4 } ];
my $nested = new DeepNested name => 'Baz', data => $orig_data;
my $nested_clone = Object::Proto::clone($nested);

$nested_clone->data->[0]{x} = 99;
push @{ $nested_clone->data }, { x => 5, y => 6 };

is($nested->data->[0]{x}, 1,  'nested: original inner hash value unchanged');
is(scalar @{ $nested->data }, 2, 'nested: original array length unchanged');
is($nested_clone->data->[0]{x}, 99, 'nested: clone inner value updated');
is(scalar @{ $nested_clone->data }, 3, 'nested: clone has extra element');

# ---------------------------------------------------------------
# 5. Object reference slot - clone gets its own independent copy
# ---------------------------------------------------------------

Object::Proto::define('Child', qw(val));

my $child_obj = new Child val => 42;
my $parent = new DeepObj name => 'Parent', child => $child_obj;
my $parent_clone = Object::Proto::clone($parent);

$parent_clone->child->val(999);

is($parent->child->val, 42,  'obj-ref: original child val unchanged');
is($parent_clone->child->val, 999, 'obj-ref: clone child val updated');

# ---------------------------------------------------------------
# 6. Scalars inside deep structure remain independent
# ---------------------------------------------------------------

my $orig_scores = [10, 20, 30];
my $mix = new DeepMixed
    name   => 'Mix',
    scores => $orig_scores,
    meta   => { a => 1 },
    notes  => undef;

my $mix_clone = Object::Proto::clone($mix);

$mix_clone->scores->[0] = 99;
$mix_clone->meta->{a}   = 99;
$mix_clone->name('MixClone');

is($mix->scores->[0], 10,   'mixed: original scores[0] unchanged');
is($mix->meta->{a},   1,    'mixed: original meta.a unchanged');
is($mix->name,        'Mix','mixed: original name unchanged');

# ---------------------------------------------------------------
# 7. Circular reference in array slot does not cause infinite loop
# ---------------------------------------------------------------

my $circ = new DeepCirc name => 'C1', peers => [];
push @{ $circ->peers }, $circ;   # circular: peers[0] points back to itself

my $circ_clone;
eval { $circ_clone = Object::Proto::clone($circ) };
ok(!$@, "circular ref: clone does not die ($@)");
SKIP: {
    skip 'clone died', 3 unless $circ_clone;
    isa_ok($circ_clone, 'DeepCirc', 'circular ref: clone is correct class');
    is($circ_clone->name, 'C1', 'circular ref: scalar slot copied');
    # The clone's peers array should not be the same reference as original
    isnt($circ_clone->peers, $circ->peers,
        'circular ref: peers array is a distinct reference');
}

# ---------------------------------------------------------------
# 8. Cloning plain scalars - should just return the value
# ---------------------------------------------------------------

my $str = 'hello';
my $str_clone = Object::Proto::clone($str);
is($str_clone, 'hello', 'plain scalar string: value returned');

my $num = 42;
my $num_clone = Object::Proto::clone($num);
is($num_clone, 42, 'plain scalar number: value returned');

my $undef_clone = Object::Proto::clone(undef);
ok(!defined $undef_clone, 'plain scalar undef: undef returned');

# ---------------------------------------------------------------
# 9. Cloning a plain scalarref - returns independent copy
# ---------------------------------------------------------------

my $sref = \(my $sv = 'original');
my $sref_clone = Object::Proto::clone($sref);

ok(ref($sref_clone) eq 'SCALAR', 'scalarref: clone is a SCALAR ref');
is($$sref_clone, 'original', 'scalarref: cloned value correct');
isnt($sref_clone, $sref, 'scalarref: clone is a distinct reference');

$$sref_clone = 'modified';
is($$sref, 'original', 'scalarref: mutating clone does not affect original');

# ---------------------------------------------------------------
# 10. Cloning a plain arrayref - returns independent deep copy
# ---------------------------------------------------------------

my $aref = [1, 2, [3, 4]];
my $aref_clone = Object::Proto::clone($aref);

ok(ref($aref_clone) eq 'ARRAY', 'arrayref: clone is an ARRAY ref');
isnt($aref_clone, $aref, 'arrayref: clone is a distinct reference');
is($aref_clone->[0], 1, 'arrayref: first element correct');
is($aref_clone->[1], 2, 'arrayref: second element correct');

# nested array is also deep copied
isnt($aref_clone->[2], $aref->[2], 'arrayref: nested arrayref is distinct');
is($aref_clone->[2][0], 3, 'arrayref: nested value correct');

push @$aref_clone, 99;
$aref_clone->[2][0] = 99;

is(scalar @$aref,      3, 'arrayref: push on clone does not affect original length');
is($aref->[2][0],      3, 'arrayref: nested mutation does not affect original');

# ---------------------------------------------------------------
# 11. Cloning a plain hashref - returns independent deep copy
# ---------------------------------------------------------------

my $href = { a => 1, b => { c => 2 } };
my $href_clone = Object::Proto::clone($href);

ok(ref($href_clone) eq 'HASH', 'hashref: clone is a HASH ref');
isnt($href_clone, $href, 'hashref: clone is a distinct reference');
is($href_clone->{a}, 1, 'hashref: top-level value correct');

# nested hash is also deep copied
isnt($href_clone->{b}, $href->{b}, 'hashref: nested hashref is distinct');
is($href_clone->{b}{c}, 2, 'hashref: nested value correct');

$href_clone->{a}    = 99;
$href_clone->{b}{c} = 99;
$href_clone->{new}  = 'added';

is($href->{a},    1, 'hashref: top-level mutation does not affect original');
is($href->{b}{c}, 2, 'hashref: nested mutation does not affect original');
ok(!exists $href->{new}, 'hashref: new key not present in original');
