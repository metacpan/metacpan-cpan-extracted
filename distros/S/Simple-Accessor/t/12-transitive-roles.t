use strict;
use warnings;
use Test::More tests => 16;
use FindBin;
use lib "$FindBin::Bin/lib";

# =============================================================
# Transitive role composition: hooks from origin roles must
# propagate through intermediate roles to the final consumer.
# =============================================================

# --- Setup: three-level role chain ---
{
    package BaseRole;
    use Simple::Accessor qw{color};

    my @validated;
    sub _build_color     { 'red' }
    sub _validate_color  { my ($self, $v) = @_; $v ne 'invalid' }
    sub _before_color    { my ($self, $v) = @_; push @validated, $v; 1 }

    sub validated_log { [@validated] }
}

{
    package MiddleRole;
    use Simple::Accessor qw{size};
    with 'BaseRole';

    sub _build_size { 'medium' }
}

{
    package FinalConsumer;
    use Simple::Accessor qw{name};
    with 'MiddleRole';
}

# --- Test lazy builder transitivity ---
{
    my $obj = FinalConsumer->new();
    ok $obj, 'three-level composition: object created';
    is $obj->color, 'red',    'transitive builder: _build_color from BaseRole works';
    is $obj->size,  'medium', 'direct builder: _build_size from MiddleRole works';
}

# --- Test validator transitivity ---
{
    my $obj = FinalConsumer->new( color => 'blue' );
    is $obj->color, 'blue', 'transitive constructor arg accepted';

    $obj->color('green');
    is $obj->color, 'green', 'transitive setter accepted';

    $obj->color('invalid');
    is $obj->color, 'green', 'transitive _validate_color rejects bad value';
}

# --- Test before hook transitivity ---
{
    # Reset log
    @{ BaseRole->validated_log() } = ();
    my $obj = FinalConsumer->new( color => 'cyan' );
    $obj->color('magenta');
    my $log = BaseRole->validated_log();
    ok scalar(@$log) >= 2, 'transitive _before_color fires on set';
    is $log->[-1], 'magenta', '_before_color receives correct value';
}

# --- Diamond composition: two paths to same origin ---
{
    package DiamondLeft;
    use Simple::Accessor qw{left_attr};
    with 'BaseRole';
}

{
    package DiamondRight;
    use Simple::Accessor qw{right_attr};
    with 'BaseRole';
}

{
    package DiamondConsumer;
    use Simple::Accessor qw{own};
    with 'DiamondLeft';
    with 'DiamondRight';  # color already exists, should be skipped
}

{
    my $obj = DiamondConsumer->new();
    ok $obj, 'diamond composition: object created';
    is $obj->color, 'red', 'diamond: builder still works (from first path)';

    $obj->color('invalid');
    is $obj->color, 'red', 'diamond: validator still works (from first path)';
}

# --- Transitive after hook ---
{
    package AfterRole;
    use Simple::Accessor qw{counter};

    my $after_count = 0;
    sub _build_counter { 0 }
    sub _after_counter { $after_count++ }

    sub after_count { $after_count }

    package AfterMiddle;
    use Simple::Accessor qw{mid};
    with 'AfterRole';

    package AfterConsumer;
    use Simple::Accessor qw{top};
    with 'AfterMiddle';
}

{
    ${ \AfterRole::after_count() } = 0;  # won't actually reset, but let's check
    my $obj = AfterConsumer->new();
    my $before = AfterRole->after_count();
    $obj->counter(1);
    my $after = AfterRole->after_count();
    ok $after > $before, 'transitive _after_counter fires through intermediate role';
}

# --- Four-level chain ---
{
    package Level1;
    use Simple::Accessor qw{deep};
    sub _build_deep { 'from_level1' }

    package Level2;
    use Simple::Accessor qw{l2};
    with 'Level1';

    package Level3;
    use Simple::Accessor qw{l3};
    with 'Level2';

    package Level4;
    use Simple::Accessor qw{l4};
    with 'Level3';
}

{
    my $obj = Level4->new();
    ok $obj, 'four-level chain: object created';
    is $obj->deep, 'from_level1', 'four-level chain: builder resolves to Level1';
    is $obj->l2,   undef,         'four-level chain: attr without builder is undef';
    is $obj->l4,   undef,         'four-level chain: own attr without builder is undef';
}
