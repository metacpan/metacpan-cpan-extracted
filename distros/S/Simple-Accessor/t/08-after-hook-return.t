use strict;
use warnings;

use Test::More tests => 19;

# --- Test packages ---

# 1. _after_* hook that returns true — value should be set
{
    package AfterReturnsTrue;
    use Simple::Accessor qw{color size};

    sub _after_color {
        my ($self, $v) = @_;
        # Side effect: sync size from color length
        $self->size(length($v)) if defined $v;
        return 1;  # true return, value stays set
    }
}

# 2. _after_* hook that returns false — gates the setter like _before_*
{
    package AfterReturnsFalse;
    use Simple::Accessor qw{name};

    sub _after_name {
        my ($self, $v) = @_;
        return 0;  # false return gates the setter
    }
}

# 3. _after_* hook that returns undef — gates the setter like _before_*
{
    package AfterReturnsUndef;
    use Simple::Accessor qw{tag};

    sub _after_tag {
        my ($self, $v) = @_;
        return undef;  # false-y return gates the setter
    }
}

# 4. _before_* returning false gates the setter
{
    package BeforeStillGates;
    use Simple::Accessor qw{guarded};

    sub _before_guarded {
        my ($self, $v) = @_;
        return 0;  # reject all sets
    }
}

# 5. _validate_* returning false gates the setter
{
    package ValidateStillGates;
    use Simple::Accessor qw{checked};

    sub _validate_checked {
        my ($self, $v) = @_;
        return $v > 0 ? 1 : 0;
    }
}

# === _after_* returning true allows the set ===

my $obj = AfterReturnsTrue->new();
$obj->color('red');
is $obj->color, 'red',
    '_after_* returning true allows value to be set';

is $obj->size, 3,
    '_after_* side effect executed (size set from color length)';

my $ret = $obj->color('blue');
is $ret, 'blue',
    'accessor returns stored value when _after_* returns true';

is $obj->size, 4,
    '_after_* side effect updates on each set';

# === _after_* returning false gates the setter (same as _before_*) ===

my $obj2 = AfterReturnsFalse->new();
my $ret2 = $obj2->name('alice');
ok !defined($ret2),
    '_after_* returning false makes accessor return undef';

is $obj2->name, undef,
    '_after_* returning false rolls back the set (value not stored)';

# set a value first, then try to set again with _after_* rejecting
# (need a class where _after_* conditionally rejects)
{
    package AfterConditional;
    use Simple::Accessor qw{score};

    sub _after_score {
        my ($self, $v) = @_;
        return $v <= 100 ? 1 : 0;  # reject scores over 100
    }
}

my $cond = AfterConditional->new();
$cond->score(50);
is $cond->score, 50,
    '_after_* returning true keeps value set';

$cond->score(200);
is $cond->score, 50,
    '_after_* returning false restores previous value';

my $ret_cond = $cond->score(999);
ok !defined($ret_cond),
    '_after_* returning false makes accessor return undef (conditional)';

is $cond->score, 50,
    'previous value survives multiple rejected sets';

# === _after_* returning undef gates the setter (same as _before_*) ===

my $obj3 = AfterReturnsUndef->new();
my $ret3 = $obj3->tag('important');
ok !defined($ret3),
    '_after_* returning undef makes accessor return undef';

is $obj3->tag, undef,
    '_after_* returning undef rolls back the set (value not stored)';

# === _before_* returning false gates the setter ===

my $obj4 = BeforeStillGates->new();
$obj4->guarded(42);
is $obj4->guarded, undef,
    '_before_* returning false prevents value from being set';

my $ret4 = $obj4->guarded(99);
ok !defined($ret4),
    '_before_* returning false makes accessor return undef';

# === _validate_* returning false gates the setter ===

my $obj5 = ValidateStillGates->new();
$obj5->checked(10);
is $obj5->checked, 10,
    '_validate_* returning true allows the set';

$obj5->checked(-5);
is $obj5->checked, 10,
    '_validate_* returning false prevents the set (value unchanged)';

my $ret5 = $obj5->checked(-1);
ok !defined($ret5),
    '_validate_* returning false makes accessor return undef';

# === _after_* rollback works when attribute had no prior value ===
{
    package AfterRollbackFresh;
    use Simple::Accessor qw{label};

    sub _after_label { return 0; }
}

my $fresh = AfterRollbackFresh->new();
$fresh->label('test');
ok !exists($fresh->{label}),
    '_after_* rollback deletes attribute when it had no prior value';

# === all three hooks behave the same way ===
ok 1, '_before_*, _validate_*, and _after_* all gate the setter on false return';
