use strict;
use warnings;

use Test::More tests => 25;

# --- Test packages defined inline ---

# 1. _before_build lifecycle ordering
{
    package LifecycleOrder;
    use Simple::Accessor qw{name status};

    my @log;

    sub get_log { [@log] }
    sub reset_log { @log = () }

    sub _before_build {
        my ($self, %opts) = @_;
        push @log, 'before_build';
    }

    sub _before_name {
        my ($self, $v) = @_;
        push @log, 'before_name';
        return 1;
    }

    sub _before_status {
        my ($self, $v) = @_;
        push @log, 'before_status';
        return 1;
    }
}

# 2. Error propagation from accessors
{
    package StrictValidator;
    use Simple::Accessor qw{age};

    sub _validate_age {
        my ($self, $v) = @_;
        die "age must be positive" if $v < 0;
        return 1;
    }
}

# 3. Falsy builder values
{
    package FalsyBuilder;
    use Simple::Accessor qw{zero_val empty_str undef_val};

    my $zero_calls = 0;
    my $empty_calls = 0;
    my $undef_calls = 0;

    sub _build_zero_val  { $zero_calls++;  return 0 }
    sub _build_empty_str { $empty_calls++; return '' }
    sub _build_undef_val { $undef_calls++; return undef }

    sub zero_call_count  { $zero_calls }
    sub empty_call_count { $empty_calls }
    sub undef_call_count { $undef_calls }
}

# === Bug 1: _before_build fires BEFORE attributes are set ===

LifecycleOrder->reset_log();
my $obj = LifecycleOrder->new(name => 'test');
my $log = LifecycleOrder->get_log();

is $log->[0], 'before_build',
    '_before_build fires first (before attribute setters)';

ok grep({ $_ eq 'before_name' } @$log),
    '_before_name fires when setting name';

# _before_build should be before any _before_* accessor hooks
my $bb_idx = 0;
for my $i (0..$#$log) {
    $bb_idx = $i if $log->[$i] eq 'before_build';
}
my $bn_idx = 0;
for my $i (0..$#$log) {
    $bn_idx = $i if $log->[$i] eq 'before_name';
}
ok $bb_idx < $bn_idx,
    '_before_build index < _before_name index (correct ordering)';

# === Bug 2: Errors from accessors now propagate ===

my $strict = eval { StrictValidator->new(age => 5) };
ok $strict, 'valid age creates object';
is $strict->age, 5, 'age is set correctly';

eval { StrictValidator->new(age => -1) };
like $@, qr/age must be positive/,
    'validation error propagates from new() (not swallowed)';

# Unknown keys should be silently ignored (no accessor for them)
my $with_unknown = StrictValidator->new(age => 10, unknown_key => 'whatever');
ok $with_unknown, 'unknown keys in new() are silently ignored';
is $with_unknown->age, 10, 'known attributes still set correctly';

# === Bug 3: Falsy builders only fire once ===

my $fb = FalsyBuilder->new();

is $fb->zero_val, 0, 'builder returning 0 works';
$fb->zero_val;  # second access
is( FalsyBuilder->zero_call_count(), 1,
    'builder returning 0 is NOT called again on second access' );

is $fb->empty_str, '', 'builder returning empty string works';
$fb->empty_str;  # second access
is( FalsyBuilder->empty_call_count(), 1,
    'builder returning empty string is NOT called again on second access' );

# undef builder — with exists check, undef IS stored (key exists), so builder fires once
my $fb2 = FalsyBuilder->new();
$fb2->undef_val;
$fb2->undef_val;  # second access
is( FalsyBuilder->undef_call_count(), 1,
    'builder returning undef fires only once (key exists after first call)' );

# Verify 0 survives round-trip through new()
my $fb3 = FalsyBuilder->new();
is $fb3->zero_val, 0, 'zero_val is 0 after build';
is $fb3->zero_val, 0, 'zero_val stays 0 on subsequent access';

# === Bug 4: Attribute initialization order is deterministic ===

{
    package DeterministicOrder;
    use Simple::Accessor qw{first second third};

    my @set_order;

    sub _before_first  { push @set_order, 'first';  return 1 }
    sub _before_second { push @set_order, 'second'; return 1 }
    sub _before_third  { push @set_order, 'third';  return 1 }

    sub set_order { [@set_order] }
    sub reset_order { @set_order = () }

    package main;

    # Run multiple times to catch hash randomization
    DeterministicOrder->reset_order();
    for my $trial (1..5) {
        DeterministicOrder->new(third => 3, first => 1, second => 2);
    }
    is_deeply( DeterministicOrder->set_order(),
        [('first', 'second', 'third') x 5],
        'attributes initialized in declaration order, not hash order' );

    # Only declared attributes are initialized (unknown keys ignored)
    DeterministicOrder->reset_order();
    my $obj = DeterministicOrder->new(second => 2, unknown => 99, first => 1);
    is_deeply( DeterministicOrder->set_order(),
        ['first', 'second'],
        'only declared attributes initialized, unknown keys skipped' );
    ok !exists $obj->{unknown}, 'unknown key not stored on object';
    is $obj->first, 1, 'declared attributes still set correctly';
}

# === Bug 5: Setter gate allows explicit undef assignment ===
{
    package UndefSetter;
    use Simple::Accessor qw{name status};

    sub _build_name { 'default' }
}

my $us = UndefSetter->new(name => 'Alice');
is $us->name, 'Alice', 'attribute set via new()';

$us->name(undef);
ok !defined($us->name), 'attribute can be explicitly set to undef';

my $us2 = UndefSetter->new(name => undef);
ok !defined($us2->name), 'attribute can be set to undef via new()';

# Verify that builder still fires when key does not exist
my $us3 = UndefSetter->new();
is $us3->name, 'default', 'builder fires when attribute not passed to new()';

# Verify that once set to undef, builder does NOT re-fire
$us3->name(undef);
ok !defined($us3->name), 'after explicit undef, builder does not re-fire';

# Verify normal setter still works after undef
$us3->name('Bob');
is $us3->name, 'Bob', 'attribute can be set back to a value after undef';
