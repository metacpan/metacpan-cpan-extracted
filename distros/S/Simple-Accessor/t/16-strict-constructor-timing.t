use strict;
use warnings;

use Test::More tests => 12;
use FindBin;
use lib $FindBin::Bin . '/lib';

# Track side effects to prove hooks don't fire before strict check
my @side_effects;

# --- Strict class with observable hooks ---
{
    package StrictWithHooks;
    use Simple::Accessor qw{name age};

    sub _strict_constructor { 1 }

    sub _before_name {
        my ($self, $v) = @_;
        push @side_effects, "before_name:$v";
        return 1;
    }

    sub _after_name {
        my ($self) = @_;
        push @side_effects, "after_name:" . $self->{name};
        return 1;
    }

    sub _validate_age {
        my ($self, $v) = @_;
        push @side_effects, "validate_age:$v";
        return 1;
    }
}

# --- Strict class with _before_build ---
{
    package StrictWithBeforeBuild;
    use Simple::Accessor qw{x};

    sub _strict_constructor { 1 }

    sub _before_build {
        my ($self, %opts) = @_;
        push @side_effects, "before_build";
    }
}

# === Test 1: valid args still fire hooks normally ===

@side_effects = ();
my $obj = StrictWithHooks->new(name => 'alice', age => 30);
ok $obj, 'valid args: object created';
is $obj->name, 'alice', 'valid args: name set';
is $obj->age, 30, 'valid args: age set';
ok scalar(@side_effects) > 0, 'valid args: hooks fired';

# === Test 2: unknown args die WITHOUT firing attribute hooks ===

@side_effects = ();
eval { StrictWithHooks->new(name => 'bob', bogus => 1) };
like $@, qr/unknown attribute\(s\): bogus/,
    'unknown attr: constructor dies';
is_deeply \@side_effects, [],
    'unknown attr: no attribute hooks fired before die';

# === Test 3: multiple unknown args, no hooks ===

@side_effects = ();
eval { StrictWithHooks->new(name => 'carol', age => 25, fake => 1, bad => 2) };
like $@, qr/unknown attribute\(s\): bad, fake/,
    'multiple unknown: constructor dies with sorted list';
is_deeply \@side_effects, [],
    'multiple unknown: no hooks fired';

# === Test 4: _before_build still runs (it's before the strict check) ===

@side_effects = ();
my $ok = StrictWithBeforeBuild->new(x => 1);
ok $ok, '_before_build: valid construction works';
is_deeply \@side_effects, ['before_build'],
    '_before_build: fires on valid args';

@side_effects = ();
eval { StrictWithBeforeBuild->new(x => 1, unknown => 2) };
like $@, qr/unknown attribute\(s\): unknown/,
    '_before_build + strict: dies on unknown';
is_deeply \@side_effects, ['before_build'],
    '_before_build runs before strict check, but attribute hooks do not';
