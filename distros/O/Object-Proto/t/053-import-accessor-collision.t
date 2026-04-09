use strict;
use warnings;
use Test::More tests => 13;

# Test that import_accessors/import_accessor correctly override OO accessors
# from a different class defined in the same package.
#
# Bug scenario (Timer::Wheel pattern):
#   - Define ClassA with 'paused' at slot 6
#   - Define ClassB with 'paused' at slot 3
#   - Both classes are used from the ClassB package
#   - import_accessors('ClassA') should install a functional accessor
#     for ClassA's 'paused' (slot 6) into ClassB's namespace, even
#     though define('ClassB') already installed an OO 'paused' accessor
#     (slot 3) in the same namespace.
#
# The recommended pattern for collisions is to use import_accessor with
# aliases, so each class gets a distinct function name.

BEGIN {
    require Object::Proto;

    # ClassA has 'paused' at slot 6 (after id, epoch, callback, interval, active)
    Object::Proto::define('ColA',
        'id:Int:required',
        'epoch:Num:required',
        'callback:CodeRef:required',
        'interval:Num',
        'active:Bool:default(1)',
        'paused:Bool:default(0)',
    );

    # ClassB has 'paused' at slot 3 (after bname, count)
    Object::Proto::define('ColB',
        'bname:Str',
        'count:Int',
        'paused:Bool:default(0)',
    );

    # This is the critical sequence: import_accessors for ClassA
    # into the ColB namespace. ColB::paused already exists as an OO method
    # from define('ColB'), and import_accessors must override it.
    Object::Proto::import_accessors('ColA', undef, 'ColB');
}

use Object::Proto;

my $a = new ColA 42, 100.5, sub { 'fired' }, 0, 1, 0;
my $b = new ColB 'wheel', 1, 0;

# ==========================================================
# Part 1: import_accessors overrides existing OO accessor
# ==========================================================

# ColB::paused is now ColA's functional accessor (slot 6)
{
    no strict 'refs';
    my $func_paused = \&{'ColB::paused'};

    is($func_paused->($a), 0, 'after import, paused() reads ColA slot 6');

    $func_paused->($a, 1);
    is($func_paused->($a), 1, 'after import, paused() setter works on ColA');
    is($a->paused, 1, 'OO getter confirms functional set');

    $a->paused(0);
    is($func_paused->($a), 0, 'OO setter reflected in functional getter');
}

# ==========================================================
# Part 2: import_accessor with alias — the recommended pattern
# ==========================================================

BEGIN {
    Object::Proto::import_accessor('ColA', 'paused', 'a_paused', 'ColB');
    Object::Proto::import_accessor('ColB', 'paused', 'b_paused', 'ColB');
    Object::Proto::import_accessor('ColA', 'active', 'a_active', 'ColB');
}

{
    no strict 'refs';
    my $a_paused = \&{'ColB::a_paused'};
    my $b_paused = \&{'ColB::b_paused'};
    my $a_active = \&{'ColB::a_active'};

    is($a_paused->($a), 0, 'aliased a_paused reads ColA slot correctly');
    is($b_paused->($b), 0, 'aliased b_paused reads ColB slot correctly');

    $a_paused->($a, 1);
    $b_paused->($b, 2);

    is($a_paused->($a), 1, 'aliased a_paused setter works');
    is($b_paused->($b), 2, 'aliased b_paused setter works');

    # Different aliases access different slot indexes
    $a_paused->($a, 0);
    is($b_paused->($b), 2, 'different aliases access different slot indexes');

    # active was already imported by import_accessors, alias should override
    is($a_active->($a), 1, 'aliased a_active reads ColA active slot');
    $a_active->($a, 0);
    is($a_active->($a), 0, 'aliased a_active setter works');
    $a_active->($a, 1);
}

# ==========================================================
# Part 3: no redefinition warnings
# ==========================================================

# The import should not produce "Subroutine redefined" warnings
{
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ if $_[0] =~ /redefin/i };

    # Force a fresh import that would collide
    Object::Proto::import_accessor('ColA', 'epoch', 'b_epoch', 'ColB');
    # Import again — same name, should override silently
    Object::Proto::import_accessor('ColA', 'epoch', 'b_epoch', 'ColB');
    is($warned, 0, 'no redefinition warnings on re-import');

    no strict 'refs';
    my $b_epoch = \&{'ColB::b_epoch'};
    is($b_epoch->($a), 100.5, 're-imported accessor still works');
}
