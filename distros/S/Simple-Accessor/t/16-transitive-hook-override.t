use strict;
use warnings;
use Test::More tests => 19;

# =============================================================
# Transitive role composition: intermediate role hook overrides
# must be visible to the final consumer.
#
# Before this fix, attr_origin stored only the origin role, so
# intermediate role overrides were silently bypassed.
# =============================================================

# --- Setup: Origin defines hooks, Middle overrides some ---
{
    package HookOrigin;
    use Simple::Accessor qw{val};

    sub _build_val    { 'origin_default' }
    sub _validate_val { 1 }  # accept anything
    sub _before_val   { 1 }

    my @origin_after;
    sub _after_val    { push @origin_after, 'origin'; 1 }
    sub origin_after_log { \@origin_after }
}

{
    package HookMiddle;
    use Simple::Accessor;
    with 'HookOrigin';

    # Override: stricter validation (must start with uppercase)
    sub _validate_val {
        my ($self, $v) = @_;
        return $v =~ /^[A-Z]/;
    }

    # Override: different builder
    sub _build_val { 'middle_default' }
}

{
    package HookConsumer;
    use Simple::Accessor qw{other};
    with 'HookMiddle';
}

# --- Test 1: Middle's builder override is used ---
{
    my $obj = HookConsumer->new();
    is $obj->val, 'middle_default',
       'lazy builder uses middle role override, not origin';
}

# --- Test 2: Middle's validation override is used ---
{
    my $obj = HookConsumer->new();
    $obj->val('Hello');
    is $obj->val, 'Hello', 'value starting with uppercase accepted';

    $obj->val('hello');
    is $obj->val, 'Hello',
       'middle validation rejects lowercase start (origin would accept)';
}

# --- Test 3: Constructor respects middle validation ---
{
    my $obj = HookConsumer->new(val => 'Good');
    is $obj->val, 'Good', 'constructor accepts valid value';

    my $obj2 = HookConsumer->new(val => 'bad');
    isnt $obj2->val, 'bad',
         'constructor rejects value via middle validation';
}

# --- Test 4: Hooks NOT overridden by middle still resolve to origin ---
{
    # _before_val is defined in HookOrigin but NOT in HookMiddle.
    # It should still fire (from origin).
    my $obj = HookConsumer->new();
    $obj->val('Test');
    is $obj->val, 'Test', 'non-overridden _before_val from origin still works';
}

# --- Test 5: after hook from origin fires when middle doesn't override it ---
{
    @{ HookOrigin->origin_after_log() } = ();
    my $obj = HookConsumer->new();
    $obj->val('After');
    my $log = HookOrigin->origin_after_log();
    ok scalar(@$log) > 0,
       '_after_val from origin fires through middle (not overridden)';
}

# --- Setup: four-level chain with override at level 2 ---
{
    package Deep1;
    use Simple::Accessor qw{x};
    sub _build_x    { 'deep1' }
    sub _validate_x { 1 }

    package Deep2;
    use Simple::Accessor;
    with 'Deep1';
    sub _validate_x { my ($s, $v) = @_; $v ne 'blocked' }

    package Deep3;
    use Simple::Accessor;
    with 'Deep2';

    package Deep4;
    use Simple::Accessor qw{y};
    with 'Deep3';
}

# --- Test 6: four-level chain respects Deep2's override ---
{
    my $obj = Deep4->new();
    is $obj->x, 'deep1', 'four-level: builder from Deep1 works';

    $obj->x('ok');
    is $obj->x, 'ok', 'four-level: normal value accepted';

    $obj->x('blocked');
    is $obj->x, 'ok', 'four-level: Deep2 validation blocks "blocked"';
}

# --- Setup: class-level override takes precedence over role chain ---
{
    package ChainOrigin;
    use Simple::Accessor qw{z};
    sub _build_z    { 'chain_origin' }
    sub _validate_z { 1 }

    package ChainMiddle;
    use Simple::Accessor;
    with 'ChainOrigin';
    sub _validate_z { my ($s, $v) = @_; $v ne 'middle_block' }

    package ChainClass;
    use Simple::Accessor qw{w};
    with 'ChainMiddle';

    # Class-level override: even stricter
    sub _validate_z { my ($s, $v) = @_; $v =~ /^[A-Z]/ }
}

# --- Test 7: class override wins over entire role chain ---
{
    my $obj = ChainClass->new();
    $obj->z('Hello');
    is $obj->z, 'Hello', 'class override: uppercase accepted';

    $obj->z('hello');
    is $obj->z, 'Hello', 'class override: lowercase rejected (class validation)';

    # "middle_block" starts lowercase so class override catches it first
    $obj->z('middle_block');
    is $obj->z, 'Hello', 'class override takes precedence over middle';

    $obj->z('Middle_block');
    is $obj->z, 'Middle_block',
       'starts uppercase: passes class override (middle would also accept)';
}

# --- Setup: middle overrides builder but not validate ---
{
    package BuildOrigin;
    use Simple::Accessor qw{b};
    sub _build_b    { 'build_origin' }
    sub _validate_b { my ($s, $v) = @_; length($v) > 2 }

    package BuildMiddle;
    use Simple::Accessor;
    with 'BuildOrigin';
    sub _build_b { 'build_middle' }
    # does NOT override _validate_b
}

{
    package BuildConsumer;
    use Simple::Accessor qw{c};
    with 'BuildMiddle';
}

# --- Test 8: mixed overrides — builder from middle, validate from origin ---
{
    my $obj = BuildConsumer->new();
    is $obj->b, 'build_middle',
       'builder from middle role (overridden)';

    $obj->b('long_enough');
    is $obj->b, 'long_enough', 'origin validate accepts length > 2';

    $obj->b('ab');
    is $obj->b, 'long_enough', 'origin validate rejects length <= 2';
}

# --- Test 9: constructor with chain validation ---
{
    my $obj = BuildConsumer->new(b => 'yes');
    is $obj->b, 'yes', 'constructor: valid value set';

    my $obj2 = BuildConsumer->new(b => 'no');
    isnt $obj2->b, 'no', 'constructor: short value rejected by origin validate';
}
