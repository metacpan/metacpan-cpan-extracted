use strict;
use warnings;

use Test::More tests => 23;
use FindBin;
use lib $FindBin::Bin . '/lib';

# =============================================================
# Test multi-feature interactions that individual test files
# don't cover: roles + inheritance + strict constructor +
# multi-import + hook resolution across the MRO.
# =============================================================

# --- Role with hooks and builder ---
{
    package IntRole::Validated;
    use Simple::Accessor qw{val};
    sub _validate_val { $_[1] > 0 }
    sub _build_val    { 42 }
}

# --- Second role with same attribute ---
{
    package IntRole::Alt;
    use Simple::Accessor qw{val};
    sub _validate_val { $_[1] > 1000 }
    sub _build_val    { 999 }
}

# --- Parent: multi-import + role + strict constructor ---
{
    package IntParent;
    use Simple::Accessor qw{a b};
    use Simple::Accessor qw{c};    # multi-import
    with 'IntRole::Validated';
    sub _strict_constructor { 1 }
    sub _build_a { 'alpha' }
}

# --- Child: inherits everything, adds own attrs ---
{
    package IntChild;
    our @ISA = ('IntParent');
    use Simple::Accessor qw{d};
    sub _build_d { 'delta' }
}

# --- Child that overrides role hooks at class level ---
{
    package IntChildOverride;
    our @ISA = ('IntParent');
    use Simple::Accessor qw{level};
    sub _validate_val { $_[1] > 100 }
}

# --- Child that opts out of strict constructor ---
{
    package IntChildRelaxed;
    our @ISA = ('IntParent');
    use Simple::Accessor qw{e};
    sub _strict_constructor { 0 }
}

# --- Child that composes a different role with same attr ---
{
    package IntChildAltRole;
    our @ISA = ('IntParent');
    use Simple::Accessor qw{f};
    with 'IntRole::Alt';    # same attr 'val', different hooks
}

# ===== 1-4: Multi-import + role + strict constructor =====

my $p = IntParent->new(a => 1, b => 2, c => 3, val => 5);
ok $p, 'parent: all attrs accepted (multi-import + role)';
is $p->a,   1, 'parent: first-import attr set';
is $p->c,   3, 'parent: second-import attr set';
is $p->val, 5, 'parent: role attr set';

# ===== 5-8: Inherited strict constructor =====

my $c = IntChild->new(a => 1, b => 2, c => 3, d => 4, val => 5);
ok $c, 'child: all parent + role + own attrs accepted';
is $c->d, 4, 'child: own attr set';

eval { IntChild->new(a => 1, bogus => 'x') };
like $@, qr/unknown attribute\(s\): bogus/,
    'child: inherits strict constructor from parent';

# Lazy builders through inheritance
my $c2 = IntChild->new();
is $c2->a, 'alpha', 'child: parent builder fires via inheritance';

# ===== 9-12: Role hooks via inherited accessor =====

my $c3 = IntChild->new(d => 1);
$c3->val(-1);    # should fail role validation (> 0)
is $c3->val, 42, 'child: role validation blocks negative, builder fires';

$c3->val(5);
is $c3->val, 5, 'child: role validation allows positive';

# Role builder fires through inheritance
my $c4 = IntChild->new();
is $c4->val, 42,      'child: role _build_val fires via inherited accessor';
is $c4->d,   'delta', 'child: own _build_d fires normally';

# ===== 13-15: Class-level hook override =====

my $c5 = IntChildOverride->new();
$c5->val(50);    # passes role validator (>0) but fails child (>100)
is $c5->val, 42, 'override: child _validate_val takes precedence over role';

$c5->val(200);
is $c5->val, 200, 'override: child _validate_val allows valid value';

my $c6 = IntChildOverride->new(val => 150);
is $c6->val, 150, 'override: constructor respects child validator';

# ===== 16-18: Opt-out of inherited strict constructor =====

my $r = IntChildRelaxed->new(a => 1, garbage => 'ok');
ok $r, 'relaxed: child opts out of inherited strict constructor';
is $r->a, 1, 'relaxed: known attr still set';

# Verify parent is still strict
eval { IntParent->new(unknown => 1) };
like $@, qr/unknown attribute/, 'relaxed: parent still strict after child opts out';

# ===== 19-21: Conflicting roles via parent and child =====
# Child composes IntRole::Alt (val with >1000 validator, builder=999)
# but parent already has 'val' accessor from IntRole::Validated.
# Parent's accessor wins — child's role composition is silently skipped.

my $c7 = IntChildAltRole->new();
is $c7->val, 42,
    'conflict: parent role accessor wins, builder from IntRole::Validated fires';

$c7->val(5);    # would fail IntRole::Alt (>1000) but passes IntRole::Validated (>0)
is $c7->val, 5,
    'conflict: validation uses parent role hooks, not child role hooks';

# ===== 22-24: Class-level builder overrides role builder via MRO =====

{
    package IntChildBuilder;
    our @ISA = ('IntParent');
    use Simple::Accessor qw{g};
    sub _build_val { 'from_child' }
}

my $c8 = IntChildBuilder->new();
is $c8->val, 'from_child',
    'mro: class-level _build_val overrides role builder via $self->can';

# But role validator still applies (from closure's $from_roles)
$c8->val(-1);    # fails role validation (> 0)
is $c8->val, 'from_child',
    'mro: role _validate_val still gates setter after builder override';

$c8->val(99);
is $c8->val, 99, 'mro: role _validate_val allows positive after builder override';
