use strict;
use warnings;

use Test::More tests => 45;

# ===================================================================
# Test coverage for Simple::Accessor features not covered elsewhere:
#   - _after_build callback
#   - build() vs initialize() precedence
#   - build()/initialize() returning false => new() returns undef
#   - _before_* returning false blocks set
#   - class isolation (two classes don't share attributes)
#   - role hooks (_before_*, _validate_*, _after_*) inherited from role
#   - with() accepting multiple roles in one call
#   - overwriting an already-set attribute
#   - new() with only unknown keys
#   - import with no attributes (standalone)
# ===================================================================

# --- _after_build callback ---
{
    package AfterBuildTest;
    use Simple::Accessor qw{name status};

    my $after_called = 0;
    my %after_opts;

    sub _after_build {
        my ($self, %opts) = @_;
        $after_called++;
        %after_opts = %opts;
        $self->{status} = 'initialized';
    }

    sub after_called { $after_called }
    sub after_opts   { \%after_opts }

    package main;

    my $obj = AfterBuildTest->new(name => 'test');
    ok $obj, '_after_build: object created';
    is( AfterBuildTest->after_called(), 1, '_after_build was called once' );
    is( $obj->status, 'initialized', '_after_build can modify object state' );
    is_deeply( AfterBuildTest->after_opts(), { name => 'test' },
        '_after_build receives constructor opts' );
}

# --- build() callback (modern alternative to initialize()) ---
{
    package WithBuildCallback;
    use Simple::Accessor qw{x y};

    my $build_called = 0;

    sub build {
        my ($self, %opts) = @_;
        $build_called++;
        $self->y(99) unless defined $opts{y};
        return 1;
    }

    sub build_called { $build_called }

    package main;

    my $obj = WithBuildCallback->new(x => 10);
    ok $obj, 'build() callback: object created';
    is( $obj->x, 10, 'build(): constructor arg preserved' );
    is( $obj->y, 99, 'build(): callback set default for y' );
    is( WithBuildCallback->build_called(), 1, 'build() was called once' );
}

# --- build() and initialize() both run (build first, then initialize) ---
{
    package BuildVsInit;
    use Simple::Accessor qw{source};

    my @call_order;

    sub build {
        my ($self, %opts) = @_;
        push @call_order, 'build';
        return 1;
    }

    sub initialize {
        my ($self, %opts) = @_;
        push @call_order, 'initialize';
        return 1;
    }

    sub call_order { [@call_order] }

    package main;

    my $obj = BuildVsInit->new();
    ok $obj, 'build + initialize: both run, object created';
    is_deeply( BuildVsInit->call_order(), ['build'],
        'build() takes precedence, initialize() is not called' );
}

# --- build() returning false => new() returns undef ---
{
    package BuildReturnsFalse;
    use Simple::Accessor qw{val};

    sub build {
        my ($self, %opts) = @_;
        return 0;  # false
    }

    package main;

    my $obj = BuildReturnsFalse->new(val => 42);
    is( $obj, undef, 'build() returning false makes new() return undef' );
}

# --- initialize() returning false => new() returns undef ---
{
    package InitReturnsFalse;
    use Simple::Accessor qw{val};

    sub initialize {
        my ($self, %opts) = @_;
        return 0;  # false
    }

    package main;

    my $obj = InitReturnsFalse->new(val => 42);
    is( $obj, undef, 'initialize() returning false makes new() return undef' );
}

# --- _before_* returning false blocks set ---
{
    package BeforeBlocksSet;
    use Simple::Accessor qw{guarded open_attr};

    sub _before_guarded {
        my ($self, $v) = @_;
        return 0;  # always block
    }

    sub _before_open_attr {
        my ($self, $v) = @_;
        return 1;  # always allow
    }

    package main;

    my $obj = BeforeBlocksSet->new();
    $obj->guarded('try');
    is( $obj->guarded, undef, '_before_* returning false blocks the set' );

    $obj->open_attr('hello');
    is( $obj->open_attr, 'hello', '_before_* returning true allows the set' );
}

# --- _before_* blocks set even from constructor ---
{
    package BeforeBlocksCtor;
    use Simple::Accessor qw{locked};

    sub _before_locked {
        my ($self, $v) = @_;
        return 0;
    }

    package main;

    my $obj = BeforeBlocksCtor->new(locked => 'attempt');
    ok $obj, 'object created despite _before blocking attr';
    is( $obj->locked, undef, '_before_* blocks set even from constructor' );
}

# --- class isolation: two classes don't share attributes ---
{
    package IsoClassA;
    use Simple::Accessor qw{alpha};

    package IsoClassB;
    use Simple::Accessor qw{beta};

    package main;

    my $a = IsoClassA->new(alpha => 1);
    my $b = IsoClassB->new(beta => 2);

    is( $a->alpha, 1, 'class A has its own attribute' );
    is( $b->beta, 2, 'class B has its own attribute' );
    ok !$a->can('beta'), 'class A cannot access class B attributes';
    ok !$b->can('alpha'), 'class B cannot access class A attributes';
}

# --- overwriting an already-set attribute ---
{
    package OverwriteTest;
    use Simple::Accessor qw{field};

    package main;

    my $obj = OverwriteTest->new(field => 'first');
    is( $obj->field, 'first', 'attribute initially set' );
    $obj->field('second');
    is( $obj->field, 'second', 'attribute overwritten' );
    $obj->field('third');
    is( $obj->field, 'third', 'attribute overwritten again' );
}

# --- new() with only unknown keys ---
{
    package UnknownKeysOnly;
    use Simple::Accessor qw{real};

    package main;

    my $obj = UnknownKeysOnly->new(fake => 1, also_fake => 2);
    ok $obj, 'new() with only unknown keys still creates object';
    is( $obj->real, undef, 'known attribute is undef when not provided' );
}

# --- import with no attributes creates new() and with() ---
{
    package BareImport;
    use Simple::Accessor;

    package main;

    ok( BareImport->can('new'), 'bare import still provides new()' );
    my $obj = BareImport->new();
    ok $obj, 'bare import: new() creates object';
    isa_ok $obj, 'BareImport';
}

# --- role hooks (_before_*, _validate_*, _after_*) from role ---
{
    package Role::Validated;
    use Simple::Accessor qw{score};

    sub _validate_score {
        my ($self, $v) = @_;
        return ($v >= 0 && $v <= 100) ? 1 : 0;
    }
    $INC{"Role/Validated.pm"} = 1;

    package ScoreKeeper;
    use Simple::Accessor qw{name};
    with 'Role::Validated';

    package main;

    my $obj = ScoreKeeper->new(name => 'player', score => 50);
    is( $obj->score, 50, 'role _validate_*: valid value accepted' );
    is( $obj->name, 'player', 'own attribute still works' );

    $obj->score(150);  # out of range
    is( $obj->score, 50, 'role _validate_*: invalid value rejected (keeps old)' );

    $obj->score(0);
    is( $obj->score, 0, 'role _validate_*: boundary value 0 accepted' );
}

# --- role _before_* hook ---
{
    package Role::Logged;
    use Simple::Accessor qw{entry};

    my @log;
    sub _before_entry {
        my ($self, $v) = @_;
        push @log, $v;
        return 1;
    }
    sub get_log { [@log] }
    $INC{"Role/Logged.pm"} = 1;

    package Logger;
    use Simple::Accessor qw{id};
    with 'Role::Logged';

    package main;

    my $obj = Logger->new(id => 1);
    $obj->entry('first');
    $obj->entry('second');
    is_deeply( Role::Logged->get_log(), ['first', 'second'],
        'role _before_*: hook fires from consumer class' );
}

# --- with() accepting multiple roles in one call ---
{
    package Role::ColorAttr;
    use Simple::Accessor qw{color};
    sub _build_color { 'red' }
    $INC{"Role/ColorAttr.pm"} = 1;

    package Role::SizeAttr;
    use Simple::Accessor qw{size};
    sub _build_size { 'medium' }
    $INC{"Role/SizeAttr.pm"} = 1;

    package MultiRole;
    use Simple::Accessor qw{label};
    with 'Role::ColorAttr', 'Role::SizeAttr';

    package main;

    my $obj = MultiRole->new(label => 'widget');
    is( $obj->label, 'widget', 'multi-role with(): own attribute works' );
    is( $obj->color, 'red', 'multi-role with(): first role builder works' );
    is( $obj->size, 'medium', 'multi-role with(): second role builder works' );
}

# --- _before_build receives constructor opts ---
{
    package BeforeBuildOpts;
    use Simple::Accessor qw{a b};

    my %captured_opts;

    sub _before_build {
        my ($self, %opts) = @_;
        %captured_opts = %opts;
    }

    sub captured_opts { \%captured_opts }

    package main;

    BeforeBuildOpts->new(a => 1, b => 2);
    is_deeply( BeforeBuildOpts->captured_opts(), { a => 1, b => 2 },
        '_before_build receives all constructor opts' );
}

# --- accessor with no hooks: simple get/set round-trip ---
{
    package PlainAccessor;
    use Simple::Accessor qw{x y z};

    package main;

    my $obj = PlainAccessor->new();
    is( $obj->x, undef, 'unset attribute returns undef' );
    $obj->x(42);
    is( $obj->x, 42, 'set then get returns value' );
    $obj->x(0);
    is( $obj->x, 0, 'can set to 0' );
    $obj->x('');
    is( $obj->x, '', 'can set to empty string' );
}

# --- _build_* in role accessed from consumer ---
{
    package Role::Greeting;
    use Simple::Accessor qw{greeting};
    sub _build_greeting { 'hello' }
    $INC{"Role/Greeting.pm"} = 1;

    package Greeter;
    use Simple::Accessor qw{name};
    with 'Role::Greeting';

    package main;

    my $obj = Greeter->new(name => 'world');
    is( $obj->greeting, 'hello', 'role builder works via lazy access' );
    is( $obj->name, 'world', 'own constructor arg preserved' );
}

# --- _after_build can rebless ---
{
    package Original;
    use Simple::Accessor qw{type};

    package Morphed;

    package Original;
    sub _after_build {
        my ($self, %opts) = @_;
        bless $self, 'Morphed' if ($opts{morph} || 0);
    }

    package main;

    my $normal = Original->new(type => 'plain');
    isa_ok $normal, 'Original', 'without morph flag: stays Original';

    my $morphed = Original->new(type => 'special', morph => 1);
    isa_ok $morphed, 'Morphed', 'with morph flag: reblessed to Morphed';
}
