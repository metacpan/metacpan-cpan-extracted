use strict;
use warnings;

use Test::More tests => 18;

# ===================================================================
# Tests for hashref-style constructor: MyClass->new({ key => val })
# The constructor should accept both a flat hash and a hashref.
# ===================================================================

# --- basic hashref constructor ---
{
    package HashrefBasic;
    use Simple::Accessor qw{name age};

    sub _build_age { 0 }

    package main;

    my $obj = HashrefBasic->new({ name => 'Alice', age => 30 });
    ok $obj, 'hashref constructor creates object';
    is $obj->name, 'Alice', 'hashref: name set correctly';
    is $obj->age, 30, 'hashref: age set correctly';
}

# --- empty hashref ---
{
    package HashrefEmpty;
    use Simple::Accessor qw{x};

    sub _build_x { 'default' }

    package main;

    my $obj = HashrefEmpty->new({});
    ok $obj, 'empty hashref constructor creates object';
    is $obj->x, 'default', 'empty hashref: builder provides default';
}

# --- hashref with falsy values ---
{
    package HashrefFalsy;
    use Simple::Accessor qw{zero empty undef_val};

    package main;

    my $obj = HashrefFalsy->new({ zero => 0, empty => '', undef_val => undef });
    ok $obj, 'hashref with falsy values creates object';
    is $obj->zero, 0, 'hashref: 0 preserved';
    is $obj->empty, '', 'hashref: empty string preserved';
    is $obj->undef_val, undef, 'hashref: undef preserved';
}

# --- flat hash still works (backward compat) ---
{
    package FlatHash;
    use Simple::Accessor qw{a b};

    package main;

    my $obj = FlatHash->new(a => 1, b => 2);
    ok $obj, 'flat hash constructor still works';
    is $obj->a, 1, 'flat hash: a set correctly';
    is $obj->b, 2, 'flat hash: b set correctly';
}

# --- hashref with hooks ---
{
    package HashrefHooks;
    use Simple::Accessor qw{score};

    my @before_log;
    sub _before_score {
        my ($self, $v) = @_;
        push @before_log, $v;
        return 1;
    }

    sub _validate_score {
        my ($self, $v) = @_;
        return $v >= 0;
    }

    package main;

    my $obj = HashrefHooks->new({ score => 42 });
    ok $obj, 'hashref with hooks: object created';
    is $obj->score, 42, 'hashref with hooks: value set';
    is_deeply \@before_log, [42], 'hashref: _before_* hook fired';

    # negative score should be rejected by validator
    $obj->score(-1);
    is $obj->score, 42, 'hashref: validate hook still works';
}

# --- hashref with strict constructor ---
{
    package HashrefStrict;
    use Simple::Accessor qw{name};

    sub _strict_constructor { 1 }

    package main;

    my $obj = HashrefStrict->new({ name => 'ok' });
    ok $obj, 'hashref with strict constructor: valid attrs accepted';

    eval { HashrefStrict->new({ name => 'ok', typo => 'bad' }) };
    like $@, qr/unknown attribute/, 'hashref with strict constructor: unknown attrs rejected';
}
