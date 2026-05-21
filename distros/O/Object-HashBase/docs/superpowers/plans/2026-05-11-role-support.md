# Object::HashBase Role Support — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `@Class` parent prefix and `&Role` Role::Tiny role prefix to Object::HashBase import; skip `new` injection when imported into a role.

**Architecture:** Pre-process import args to split off `@`/`&` prefixes before existing single-char SPEC dispatch. `@` requires module and pushes onto `@ISA`. `&` eagerly copies role constants for compile-time `+FOO` visibility, then defers `Role::Tiny->apply_roles_to_package` to end of consumer compile scope via a blessed `%^H` object whose DESTROY fires the compose call. Role detection (`_is_role($pkg)`) checks `Role::Tiny->is_role` and skips `_build_new`.

**Tech Stack:** Perl 5.8.1+ (with `&` requiring 5.10+), `Role::Tiny` 1.003000+ (soft, loaded only when `&` used), `Test::More`.

**Spec:** `docs/superpowers/specs/2026-05-11-role-support-design.md`

---

## File Structure

**Modified:**
- `lib/Object/HashBase.pm` — single-file module; all logic lives here.
  - New: `_is_role`, prefix preprocessing in `do_import`, role-constant copy, `%^H` registration.
  - New: inline `Object::HashBase::_RoleApplier` package at bottom of file.
  - New: `attr_list` extended to include role attrs from `%Object::HashBase::ROLE_ATTRS`.
  - Modified: `do_import` to gate `_build_new` on `_is_role`.
  - Modified: POD — new sections.
- `Changes` — entry under current version block.

**Created:**
- `t/parent_prefix.t` — `@` prefix tests
- `t/role_define.t` — declaring HashBase attrs in a Role::Tiny role
- `t/role_consume.t` — `&` prefix consumption: constants, deferred apply, attr_list, conflicts
- `t/role_old_perl.t` — `&` croak on perl < 5.10 (skipped on 5.10+)

---

## Task 1: Add `Changes` entry and bump version note

**Files:**
- Modify: `Changes`
- Reference: `lib/Object/HashBase.pm` line 5 (`our $VERSION = '0.016';`)

- [ ] **Step 1: Read current Changes file**

Run: `head -20 Changes`

- [ ] **Step 2: Add entry for new version**

Edit `Changes`. Above the current top entry, add:

```
{{$NEXT}}
    - Add '@Class::Name' parent prefix to import (shortcut for `use parent`)
    - Add '&Role::Name' role prefix to import (compose Role::Tiny role)
    - Skip `new` injection when Object::HashBase is imported into a Role::Tiny role
    - Role::Tiny is a soft requirement, loaded only when '&' prefix used
    - '&' prefix requires Perl 5.10+
```

(Dist::Zilla's `NextRelease` plugin handles `{{$NEXT}}` substitution.)

- [ ] **Step 3: Commit**

```bash
git add Changes
git commit -m "Add Changes entry for role support feature"
```

---

## Task 2: Test for `@` parent prefix (TDD red)

**Files:**
- Create: `t/parent_prefix.t`

- [ ] **Step 1: Write failing test file**

Create `t/parent_prefix.t`:

```perl
use strict;
use warnings;
use Test::More;

# Define parent BEFORE child (Perl compile-order matters)
BEGIN {
    package My::Parent;
    use Object::HashBase qw/pa/;
    $INC{'My/Parent.pm'} = __FILE__;
}

BEGIN {
    package My::Child;
    use Object::HashBase qw/@My::Parent ch/;
}

isa_ok('My::Child', 'My::Parent', 'child ISA parent');

can_ok('My::Child', qw/PA CH pa ch set_pa set_ch new/);

is(My::Child::PA(), 'pa', 'PA constant inherited');
is(My::Child::CH(), 'ch', 'CH constant');

my $obj = My::Child->new(pa => 'P', ch => 'C');
is($obj->pa, 'P', 'pa accessor');
is($obj->ch, 'C', 'ch accessor');
$obj->set_pa('PP');
is($obj->pa, 'PP', 'set_pa works');

# Multiple parents via repeated @ prefix
BEGIN {
    package My::P1;
    use Object::HashBase qw/p1a/;
    $INC{'My/P1.pm'} = __FILE__;

    package My::P2;
    use Object::HashBase qw/p2a/;
    $INC{'My/P2.pm'} = __FILE__;
}

BEGIN {
    package My::MultiChild;
    use Object::HashBase qw/@My::P1 @My::P2 mc/;
}

isa_ok('My::MultiChild', 'My::P1');
isa_ok('My::MultiChild', 'My::P2');
can_ok('My::MultiChild', qw/P1A P2A MC/);

# Idempotent: re-adding same parent doesn't double-list
{
    no strict 'refs';
    my @isa = @{'My::Child::ISA'};
    my @parent_count = grep { $_ eq 'My::Parent' } @isa;
    is(scalar @parent_count, 1, 'parent listed once in @ISA');
}

# Bogus parent: require failure croaks from caller
{
    my $err;
    eval {
        package My::BadChild;
        Object::HashBase->import('@Bogus::NonExistent::Class');
        1;
    } or $err = $@;
    like($err, qr/Could not load parent class 'Bogus::NonExistent::Class'/, 'bogus parent croaks');
}

done_testing;
```

- [ ] **Step 2: Run test, expect failure**

Run: `prove -lv t/parent_prefix.t`
Expected: failure (compile error or undefined behavior — `@My::Parent` not yet recognized).

---

## Task 3: Implement `@` parent prefix

**Files:**
- Modify: `lib/Object/HashBase.pm` — `do_import` (lines 58-96)

- [ ] **Step 1: Read current `do_import`**

Run: `sed -n '58,96p' lib/Object/HashBase.pm`

- [ ] **Step 2: Add arg preprocessing**

In `lib/Object/HashBase.pm`, replace the body of `do_import` so it splits args before existing logic. After `my $into = shift;` and the `$ver` block, before `my $isa = _isa($into);`, insert preprocessing:

```perl
    my (@parents, @attrs);
    for my $arg (@_) {
        if (defined($arg) && length($arg) && substr($arg, 0, 1) eq '@') {
            push @parents, substr($arg, 1);
        }
        else {
            push @attrs, $arg;
        }
    }

    for my $parent (@parents) {
        my $pm = $parent;
        $pm =~ s{::}{/}g;
        $pm .= '.pm';
        unless ($INC{$pm}) {
            local ($@);
            unless (eval { require $pm; 1 }) {
                Carp::croak("Could not load parent class '$parent': $@");
            }
        }
        no strict 'refs';
        push @{"$into\::ISA"}, $parent unless grep { $_ eq $parent } @{"$into\::ISA"};
    }
```

Then change `$isa = _isa($into);` to run AFTER the `@ISA` updates (it already does textually — but verify). Replace the existing line `my $attr_list = $Object::HashBase::ATTR_LIST{$into} ||= [];` and following — change the `args_to_subs` call to pass `\@attrs` instead of `\@_`:

Find:
```perl
        ($class->args_to_subs($attr_list, $attr_subs, \@_, $into)),
```

Replace with:
```perl
        ($class->args_to_subs($attr_list, $attr_subs, \@attrs, $into)),
```

- [ ] **Step 3: Run test, expect pass**

Run: `prove -lv t/parent_prefix.t`
Expected: all subtests pass.

- [ ] **Step 4: Run existing test suite to verify no regression**

Run: `prove -l t/`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/Object/HashBase.pm t/parent_prefix.t
git commit -m "Add '\@' parent prefix to Object::HashBase import"
```

---

## Task 4: Test role definition (Role::Tiny role uses HashBase, no `new`)

**Files:**
- Create: `t/role_define.t`

- [ ] **Step 1: Write failing test**

Create `t/role_define.t`:

```perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Role::Tiny; 1 } or plan skip_all => 'Role::Tiny required';
}

BEGIN {
    package My::HBRole;
    use Role::Tiny;
    use Object::HashBase qw/ra -rb/;
}

ok(Role::Tiny->is_role('My::HBRole'), 'role registered with Role::Tiny');

# Accessors and constants installed on role
can_ok('My::HBRole', qw/RA RB ra rb set_ra set_rb/);
is(My::HBRole::RA(), 'ra', 'RA constant');
is(My::HBRole::RB(), 'rb', 'RB constant');

# new and init helpers NOT installed on role
ok(!My::HBRole->can('new'),           'role has no new()');
ok(!My::HBRole->can('add_pre_init'),  'role has no add_pre_init');
ok(!My::HBRole->can('add_post_init'), 'role has no add_post_init');

done_testing;
```

- [ ] **Step 2: Run test, expect failure**

Run: `prove -lv t/role_define.t`
Expected: `new()` test fails because Object::HashBase still injects `new` into role.

---

## Task 5: Implement role detection (skip `new` injection for roles)

**Files:**
- Modify: `lib/Object/HashBase.pm`

- [ ] **Step 1: Add `_is_role` helper**

In `lib/Object/HashBase.pm`, after the `_isa` declaration (around line 39, end of the `BEGIN` block) and before `my %SPEC`, add:

```perl
sub _is_role {
    my $pkg = shift;
    return 0 unless $INC{'Role/Tiny.pm'};
    return Role::Tiny->is_role($pkg) ? 1 : 0;
}
```

- [ ] **Step 2: Gate `_build_new` on role detection**

In `do_import`, find:

```perl
    my $add_new = 1;

    if (my $have_new = $into->can('new')) {
        my $new_lookup = $Object::HashBase::NEW_LOOKUP //= {};
        $add_new = 0 unless $new_lookup->{$have_new};
    }
```

Replace with:

```perl
    my $add_new = _is_role($into) ? 0 : 1;

    if ($add_new && (my $have_new = $into->can('new'))) {
        my $new_lookup = $Object::HashBase::NEW_LOOKUP //= {};
        $add_new = 0 unless $new_lookup->{$have_new};
    }
```

- [ ] **Step 3: Run role_define test, expect pass**

Run: `prove -lv t/role_define.t`
Expected: all pass.

- [ ] **Step 4: Run full test suite**

Run: `prove -l t/`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/Object/HashBase.pm t/role_define.t
git commit -m "Skip new() injection when imported into a Role::Tiny role"
```

---

## Task 6: Test `&` role prefix — basic constant copy and accessor composition

**Files:**
- Create: `t/role_consume.t`

- [ ] **Step 1: Write failing test (initial subset)**

Create `t/role_consume.t`:

```perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Role::Tiny; 1 } or plan skip_all => 'Role::Tiny required';
    plan skip_all => "& prefix requires perl 5.10+" if $] < 5.010;
}

BEGIN {
    package My::CRole;
    use Role::Tiny;
    use Object::HashBase qw/cr/;
    $INC{'My/CRole.pm'} = __FILE__;
}

# Consumer uses +CR constant at compile time — must resolve
BEGIN {
    package My::CClass;
    use Object::HashBase qw/&My::CRole own/;

    sub uses_constants {
        my $self = shift;
        return [ $self->{+CR}, $self->{+OWN} ];
    }
}

ok(Role::Tiny::does_role('My::CClass', 'My::CRole'), 'role composed into consumer');

can_ok('My::CClass', qw/CR OWN cr own set_cr set_own new uses_constants/);
is(My::CClass::CR(), 'cr', 'CR constant copied to consumer');
is(My::CClass::OWN(), 'own', 'OWN constant');

my $obj = My::CClass->new(cr => 'role-val', own => 'own-val');
is($obj->cr, 'role-val', 'role accessor works on consumer instance');
is($obj->own, 'own-val', 'own accessor works');
is_deeply($obj->uses_constants, ['role-val', 'own-val'], '+CONSTANT resolves at compile in consumer sub');

done_testing;
```

- [ ] **Step 2: Run, expect failure**

Run: `prove -lv t/role_consume.t`
Expected: compile failure on `+CR` (constant not present at compile) or `&` arg treated as attribute.

---

## Task 7: Implement `&` prefix scaffolding — auto-load Role::Tiny, version + perl checks, eager constant copy

**Files:**
- Modify: `lib/Object/HashBase.pm`

- [ ] **Step 1: Extend arg preprocessing to capture `&` prefix**

In `do_import`, replace the preprocessing block from Task 3 with:

```perl
    my (@parents, @roles, @attrs);
    for my $arg (@_) {
        if (defined($arg) && length($arg)) {
            my $p = substr($arg, 0, 1);
            if ($p eq '@') {
                push @parents, substr($arg, 1);
                next;
            }
            if ($p eq '&') {
                push @roles, substr($arg, 1);
                next;
            }
        }
        push @attrs, $arg;
    }
```

- [ ] **Step 2: Add role processing block AFTER the existing install loop**

In `do_import`, AFTER the existing `while (my ($k, $v) = each %subs) { ... *{"$into\::$k"} = $v ... }` install loop (i.e., at the very end of `do_import`), add the block below. Placing it after the install loop ensures the "existing sub wins" check sees subs that have just been installed for own/inherited attrs, so role constants only fill gaps:

```perl
    if (@roles) {
        Carp::croak("Object::HashBase '&' role prefix requires Perl 5.010 or newer (this is $])")
            if $] < 5.010;

        unless ($INC{'Role/Tiny.pm'}) {
            local ($@);
            unless (eval { require Role::Tiny; 1 }) {
                Carp::croak("Object::HashBase '&' role prefix requires Role::Tiny but it could not be loaded: $@");
            }
        }

        unless (Role::Tiny->can('is_role')) {
            Carp::croak("Object::HashBase '&' role prefix requires Role::Tiny 1.003000 or newer (is_role missing)");
        }

        for my $role (@roles) {
            my $pm = $role;
            $pm =~ s{::}{/}g;
            $pm .= '.pm';
            unless ($INC{$pm}) {
                local ($@);
                unless (eval { require $pm; 1 }) {
                    Carp::croak("Could not load role '$role': $@");
                }
            }
            Carp::croak("'$role' is not a Role::Tiny role")
                unless Role::Tiny->is_role($role);
            my $role_subs = $Object::HashBase::ATTR_SUBS{$role};
            Carp::croak("'$role' does not use Object::HashBase")
                unless $role_subs && %$role_subs;

            no strict 'refs';
            for my $const (keys %$role_subs) {
                next if defined &{"$into\::$const"};   # keep existing sub, no override, no warn
                *{"$into\::$const"} = $role_subs->{$const};
            }
        }
    }
```

- [ ] **Step 3: Defer `apply_roles_to_package` via `%^H`**

After the constant copy in the `for my $role (@roles)` loop (inside the `if (@roles)` block, after the role loop ends), append:

```perl
        my $key = "Object::HashBase::role_applier::$into";
        my $applier = $^H{$key} ||= Object::HashBase::_RoleApplier->new($into);
        $applier->add($_) for @roles;
```

- [ ] **Step 4: Add `_RoleApplier` inline package at end of file**

Before the final `1;` in `lib/Object/HashBase.pm`, insert:

```perl
package    # hide from PAUSE indexer
    Object::HashBase::_RoleApplier;

sub new {
    my ($class, $into) = @_;
    return bless { into => $into, roles => [] }, $class;
}

sub add {
    my ($self, $role) = @_;
    push @{$self->{roles}}, $role
        unless grep { $_ eq $role } @{$self->{roles}};
}

sub DESTROY {
    my $self = shift;
    return unless @{$self->{roles}};
    Role::Tiny->apply_roles_to_package($self->{into}, @{$self->{roles}});
}
```

- [ ] **Step 5: Run test, expect pass**

Run: `prove -lv t/role_consume.t`
Expected: all subtests pass. The consumer's `uses_constants` sub compiled with `+CR` resolved (constant copied eagerly); `does_role` true (compose happened at end of `BEGIN` block scope).

- [ ] **Step 6: Run full test suite, no regression**

Run: `prove -l t/`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/Object/HashBase.pm t/role_consume.t
git commit -m "Add '&' role prefix: eager constant copy + deferred Role::Tiny compose"
```

---

## Task 8: Test conflict resolution (existing sub wins, no override)

**Files:**
- Modify: `t/role_consume.t` (append tests)

- [ ] **Step 1: Append conflict tests**

Add to `t/role_consume.t` before `done_testing;`:

```perl
# Conflict: consumer already has CR sub before & prefix processed
BEGIN {
    package My::ConflictRole;
    use Role::Tiny;
    use Object::HashBase qw/cflict/;
    $INC{'My/ConflictRole.pm'} = __FILE__;
}

BEGIN {
    package My::ConflictConsumer;
    sub CFLICT { 'overridden-value' }
    use Object::HashBase qw/&My::ConflictRole/;
}

is(My::ConflictConsumer::CFLICT(), 'overridden-value',
    'existing sub kept, role constant not copied over it');

# No warnings emitted
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    eval q{
        package My::SilentConflict;
        sub CFLICT { 'mine' }
        use Object::HashBase qw/&My::ConflictRole/;
        1;
    } or do { fail("compile failed: $@") };
    is_deeply(\@warns, [], 'no warnings on silent conflict');
}
```

- [ ] **Step 2: Run, expect pass**

Run: `prove -lv t/role_consume.t`
Expected: pass — implementation from Task 7 step 2 already includes `next if defined &{"$into\::$const"};`.

- [ ] **Step 3: Commit**

```bash
git add t/role_consume.t
git commit -m "Test '&' role prefix conflict resolution (existing sub wins)"
```

---

## Task 9: Test and implement attr_list including role attrs

**Files:**
- Modify: `t/role_consume.t` (append)
- Modify: `lib/Object/HashBase.pm` — track role attrs, extend `attr_list`

- [ ] **Step 1: Append attr_list test**

Add to `t/role_consume.t` before `done_testing;`:

```perl
# attr_list includes role attrs for array-form constructor
{
    my @attrs = Object::HashBase::attr_list('My::CClass');
    is_deeply(
        [ sort @attrs ],
        [ sort qw/cr own/ ],
        'attr_list includes role + own attrs'
    );

    # Array-form constructor uses ordered attr_list
    # Order: role attrs first (composed earlier), then own
    my @ordered = Object::HashBase::attr_list('My::CClass');
    my $obj = My::CClass->new([ map { "v_$_" } @ordered ]);
    for my $a (@ordered) {
        is($obj->{$a}, "v_$a", "array-form set $a from attr_list order");
    }
}
```

- [ ] **Step 2: Run, expect failure**

Run: `prove -lv t/role_consume.t`
Expected: attr_list test fails because role attrs not tracked for consumer.

- [ ] **Step 3: Track role->consumer attrs in `%ROLE_ATTRS`**

In `lib/Object/HashBase.pm`, inside the `for my $role (@roles)` loop in `do_import`, after the constant-copy loop, add:

```perl
            my $role_attr_list = $Object::HashBase::ATTR_LIST{$role} || [];
            push @{$Object::HashBase::ROLE_ATTRS{$into} ||= []}, @$role_attr_list;
```

- [ ] **Step 4: Update `attr_list` to merge role attrs**

In `lib/Object/HashBase.pm`, modify `attr_list` (around line 159). Replace its body so it merges `ROLE_ATTRS` for the class:

```perl
sub attr_list {
    my $class = shift;

    my $isa = _isa($class);

    my %seen;
    my @list;
    for my $pkg (reverse @$isa) {
        if (0.004 > ($Object::HashBase::VERSION{$pkg} || 0)) {
            Carp::carp("$pkg uses an inlined version of Object::HashBase too old to support attr_list()");
            next;
        }
        my $own = $Object::HashBase::ATTR_LIST{$pkg};
        my $role_attrs = $Object::HashBase::ROLE_ATTRS{$pkg} || [];
        for my $a (@$role_attrs, ($own ? @$own : ())) {
            push @list, $a unless $seen{$a}++;
        }
    }

    return @list;
}
```

This places role attrs before own attrs in each level of the ISA walk, matching role-composition order.

- [ ] **Step 5: Run, expect pass**

Run: `prove -lv t/role_consume.t`
Expected: pass.

- [ ] **Step 6: Run full test suite**

Run: `prove -l t/`
Expected: all pass (including existing `t/HashBase.t` since the new path only adds entries when `%ROLE_ATTRS` populated).

- [ ] **Step 7: Commit**

```bash
git add lib/Object/HashBase.pm t/role_consume.t
git commit -m "Include role-composed attrs in attr_list() for array-form constructor"
```

---

## Task 10: Test multiple roles and method modifiers / required methods

**Files:**
- Modify: `t/role_consume.t` (append)

- [ ] **Step 1: Append multi-role + modifier tests**

Add to `t/role_consume.t` before `done_testing;`:

```perl
# Multiple roles composed at once
BEGIN {
    package My::RA;
    use Role::Tiny;
    use Object::HashBase qw/ra_attr/;
    sub ra_method { 'RA' }
    $INC{'My/RA.pm'} = __FILE__;

    package My::RB;
    use Role::Tiny;
    use Object::HashBase qw/rb_attr/;
    sub rb_method { 'RB' }
    $INC{'My/RB.pm'} = __FILE__;
}

BEGIN {
    package My::Multi;
    use Object::HashBase qw/&My::RA &My::RB own_attr/;
}

ok(Role::Tiny::does_role('My::Multi', 'My::RA'), 'role RA composed');
ok(Role::Tiny::does_role('My::Multi', 'My::RB'), 'role RB composed');
is(My::Multi->new->ra_method, 'RA', 'RA method');
is(My::Multi->new->rb_method, 'RB', 'RB method');

# Method modifier (around) sees consumer method (deferred compose)
BEGIN {
    package My::AroundRole;
    use Role::Tiny;
    use Object::HashBase qw/wrapped/;
    around 'do_it' => sub {
        my ($orig, $self, @args) = @_;
        return "wrapped(" . $self->$orig(@args) . ")";
    };
    $INC{'My/AroundRole.pm'} = __FILE__;
}

BEGIN {
    package My::AroundConsumer;
    use Object::HashBase qw/&My::AroundRole/;
    sub do_it { 'inner' }
}

is(My::AroundConsumer->new->do_it, 'wrapped(inner)',
    'around modifier wraps consumer method (deferred compose worked)');

# Required method satisfied by consumer's later sub
BEGIN {
    package My::ReqRole;
    use Role::Tiny;
    use Object::HashBase qw/req_attr/;
    requires 'must_have';
    $INC{'My/ReqRole.pm'} = __FILE__;
}

BEGIN {
    package My::ReqConsumer;
    use Object::HashBase qw/&My::ReqRole/;
    sub must_have { 'present' }
}

ok(Role::Tiny::does_role('My::ReqConsumer', 'My::ReqRole'),
    'required method satisfied by later-defined sub');
is(My::ReqConsumer->new->must_have, 'present', 'required method callable');
```

- [ ] **Step 2: Run, expect pass**

Run: `prove -lv t/role_consume.t`
Expected: all subtests pass. The modifier and required tests verify deferred compose semantics.

- [ ] **Step 3: Commit**

```bash
git add t/role_consume.t
git commit -m "Test multiple roles, method modifiers, required methods with '&' prefix"
```

---

## Task 11: Test error cases for `&` prefix

**Files:**
- Modify: `t/role_consume.t` (append)

- [ ] **Step 1: Append error tests**

Add to `t/role_consume.t` before `done_testing;`:

```perl
# Non-existent role
{
    my $err;
    eval q{
        package My::BadRoleConsumer;
        use Object::HashBase '&Bogus::Role::Name';
        1;
    } or $err = $@;
    like($err, qr/Could not load role 'Bogus::Role::Name'/, 'non-existent role croaks');
}

# Plain class (not a Role::Tiny role)
BEGIN {
    package My::PlainClass;
    use Object::HashBase qw/pcattr/;
    $INC{'My/PlainClass.pm'} = __FILE__;
}
{
    my $err;
    eval q{
        package My::BadConsumer1;
        use Object::HashBase '&My::PlainClass';
        1;
    } or $err = $@;
    like($err, qr/'My::PlainClass' is not a Role::Tiny role/, 'plain class as role croaks');
}

# Role without Object::HashBase
BEGIN {
    package My::NoHBRole;
    use Role::Tiny;
    $INC{'My/NoHBRole.pm'} = __FILE__;
}
{
    my $err;
    eval q{
        package My::BadConsumer2;
        use Object::HashBase '&My::NoHBRole';
        1;
    } or $err = $@;
    like($err, qr/'My::NoHBRole' does not use Object::HashBase/, 'role without HashBase croaks');
}
```

- [ ] **Step 2: Run, expect pass**

Run: `prove -lv t/role_consume.t`
Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add t/role_consume.t
git commit -m "Test '&' prefix error cases"
```

---

## Task 12: Perl 5.10 gate test (`&` croak on old perl)

**Files:**
- Create: `t/role_old_perl.t`

- [ ] **Step 1: Write test**

Create `t/role_old_perl.t`:

```perl
use strict;
use warnings;
use Test::More;

if ($] >= 5.010) {
    plan skip_all => "this test only runs on perl < 5.10";
}

my $err;
eval q{
    package My::TooOld;
    use Object::HashBase '&Some::Role';
    1;
} or $err = $@;

like($err, qr/'&' role prefix requires Perl 5\.010/, 'croak on old perl');

done_testing;
```

- [ ] **Step 2: Run (skipped on modern perl)**

Run: `prove -lv t/role_old_perl.t`
Expected: skipped with message on perl 5.10+; on 5.8.x would pass.

- [ ] **Step 3: Commit**

```bash
git add t/role_old_perl.t
git commit -m "Test '&' prefix requires Perl 5.10"
```

---

## Task 13: Test auto-load of Role::Tiny (consumer didn't load it)

**Files:**
- Modify: `t/role_consume.t` (append)

- [ ] **Step 1: Append auto-load test**

Append to `t/role_consume.t` before `done_testing;`:

```perl
# Auto-load Role::Tiny: simulate by checking it loads on demand.
# We can't fully simulate "Role::Tiny not loaded" in a process that already
# loaded it via the role definitions above, but we can verify the require
# path works by ensuring no croak when consumer omits `use Role::Tiny::With;`.
BEGIN {
    package My::AutoRole;
    use Role::Tiny;
    use Object::HashBase qw/auto/;
    $INC{'My/AutoRole.pm'} = __FILE__;
}

BEGIN {
    package My::AutoConsumer;
    # No `use Role::Tiny` here — Object::HashBase auto-loads it for &
    use Object::HashBase qw/&My::AutoRole/;
}

ok(Role::Tiny::does_role('My::AutoConsumer', 'My::AutoRole'),
    'consumer composed role without explicitly loading Role::Tiny');
```

- [ ] **Step 2: Run, expect pass**

Run: `prove -lv t/role_consume.t`
Expected: pass.

- [ ] **Step 3: Commit**

```bash
git add t/role_consume.t
git commit -m "Test '&' prefix auto-loads Role::Tiny"
```

---

## Task 14: POD updates

**Files:**
- Modify: `lib/Object/HashBase.pm` — POD sections

- [ ] **Step 1: Add new section "ISA AND ROLE PREFIXES" before "SUBCLASSING"**

In `lib/Object/HashBase.pm`, find the `=head1 SUBCLASSING` line and insert before it:

```pod
=head1 ISA AND ROLE PREFIXES

Two import prefixes provide shortcuts for declaring parent classes and
consuming roles.

=head2 PARENT PREFIX: @

    use Object::HashBase qw/@Some::Parent::Class foo bar/;

This loads C<Some::Parent::Class> and pushes it onto C<@ISA>. Equivalent to:

    use parent 'Some::Parent::Class';
    use Object::HashBase qw/foo bar/;

Multiple parents can be declared:

    use Object::HashBase qw/@Parent::A @Parent::B foo/;

The prefix may be combined freely with attribute declarations in any order;
parents are processed first regardless of position.

=head2 ROLE PREFIX: &

    use Object::HashBase qw/&Some::Role::Name foo/;

This consumes a L<Role::Tiny> role that itself uses L<Object::HashBase>. The
role's constants are copied into the consumer immediately so the
C<< $self->{+FOO} >> pattern resolves at compile time. The actual role
composition via C<< Role::Tiny->apply_roles_to_package >> is deferred until
the end of the consumer's compile scope, so the consumer's own methods are
present when role methods are composed (correct method-modifier and
required-method semantics).

Requirements:

=over 4

=item *

L<Role::Tiny> 1.003000 or newer must be installed. It is not a hard
dependency of L<Object::HashBase>; it is loaded on demand when the C<&>
prefix is used.

=item *

Perl 5.10 or newer. The compile-scope deferral relies on the lexically-scoped
C<%^H> hints hash, which was made reliable in 5.10.

=item *

The target package must be a Role::Tiny role that itself uses
L<Object::HashBase>.

=back

If a sub of the same name as a role constant already exists in the consumer
package, the existing sub is kept and the role constant is not copied. No
warning is issued.

=cut

```

- [ ] **Step 2: Add "USING IN A ROLE" section**

Find the `=head1 GETTING A LIST OF ATTRIBUTES FOR A CLASS` line. Insert before it:

```pod
=head1 USING IN A ROLE

Object::HashBase can be used inside a L<Role::Tiny> role:

    package My::Role;
    use Role::Tiny;
    use Object::HashBase qw/foo -bar/;

    sub greet { "hello " . $_[0]->{+FOO} }

When the package being imported into is a Role::Tiny role, Object::HashBase
skips injection of C<new()>, C<add_pre_init>, C<add_post_init>,
C<_pre_init>, and C<_post_init>. Only accessor methods and constants are
installed.

Consumers compose the role with the C<&> prefix (recommended) or with a
direct C<with()> call. The C<&> prefix copies the role's constants into the
consumer at compile time, which is required for the C<< $self->{+FOO} >>
pattern in consumer methods to resolve.

=cut

```

- [ ] **Step 3: Update `attr_list` POD to note role attrs included**

Find the `=item @list = $class->Object::HashBase::attr_list()` line and the paragraph after it. Append to that paragraph:

```pod
Attributes from roles composed via the C<&> prefix are included in the
returned list, ordered before the consumer's own attributes at the same ISA
level.
```

- [ ] **Step 4: Verify POD parses**

Run: `podchecker lib/Object/HashBase.pm`
Expected: no errors.

- [ ] **Step 5: Run full suite (including pod tests)**

Run: `prove -l t/ xt/`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/Object/HashBase.pm
git commit -m "Document '@' parent and '&' role prefixes; document role usage"
```

---

## Task 15: Final verification

- [ ] **Step 1: Run full test suite from clean state**

Run: `prove -lr t/`
Expected: all tests pass.

- [ ] **Step 2: Verify dist files**

Run: `perl -c lib/Object/HashBase.pm`
Expected: `lib/Object/HashBase.pm syntax OK`

- [ ] **Step 3: Confirm no new runtime deps in dist.ini / cpanfile**

Run: `grep -i role::tiny dist.ini cpanfile`
Expected: no output (Role::Tiny remains a soft requirement).

- [ ] **Step 4: Review commits**

Run: `git log --oneline @{u}..HEAD`
Expected: ordered commits per task above.

---

## Addendum: 2026-05-11 Review Findings

### 1. Architectural Validation: `attr_list` Ordering
The implementation in Task 9 correctly places role-composed attributes *before* the consumer's own attributes at the same inheritance level. This ensures that role attributes behave predictably in array-ref constructors, effectively feeling like they are part of the class's baseline definition before its own local extensions.

### 2. Inlining Isolation via `%^H`
The choice of `"Object::HashBase::role_applier::$into"` as the hint key in `%^H` is validated. Because the inliner (`Inline.pm`) performs a global string replacement of `Object::HashBase` with the target prefix, different inlined versions of HashBase within the same process will use isolated keys and isolated `_RoleApplier` packages. This prevents race conditions or cross-version interference during deferred role composition.

### 3. Constant Conflict Policy: Consumer Wins
The logic `next if defined &{"$into\::$const"}` in Task 7 establishes a "Consumer Wins" policy. This is consistent with standard Perl role/mixin patterns where local definitions or existing inherited methods take precedence over composed role constants. This policy is idempotent and safe for repeated imports.

### 4. Role::Tiny Soft Dependency & Versioning
The plan correctly implements Role::Tiny as a soft dependency. The check for `Role::Tiny->can('is_role')` immediately following the on-demand `require` ensures that older versions of Role::Tiny (pre-1.003000) are caught gracefully with a clear error message before they can cause runtime failures.
