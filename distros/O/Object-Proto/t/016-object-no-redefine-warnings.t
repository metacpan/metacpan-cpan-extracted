#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test that importing accessors does NOT produce redefinition warnings

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# ============================================
# Test 1: Multiple import_accessors calls
# ============================================

subtest 'no warnings on multiple import_accessors calls' => sub {
    @warnings = ();

    require Object::Proto;
    Object::Proto::define('Widget', qw(name value));

    # Import multiple times - should NOT warn
    Object::Proto::import_accessors('Widget', 'main');
    Object::Proto::import_accessors('Widget', 'main');
    Object::Proto::import_accessors('Widget', 'main');

    my @redefine_warnings = grep { /redefin/i } @warnings;
    is(scalar(@redefine_warnings), 0, 'no redefinition warnings from multiple imports')
        or diag("Warnings: @redefine_warnings");
};

# ============================================
# Test 2: Multiple import_accessor calls for same alias
# ============================================

subtest 'no warnings on multiple import_accessor with same alias' => sub {
    @warnings = ();

    Object::Proto::define('Gadget', qw(id label));

    # Import same accessor with same alias multiple times
    Object::Proto::import_accessor('Gadget', 'id', 'gadget_id', 'main');
    Object::Proto::import_accessor('Gadget', 'id', 'gadget_id', 'main');
    Object::Proto::import_accessor('Gadget', 'id', 'gadget_id', 'main');

    my @redefine_warnings = grep { /redefin/i } @warnings;
    is(scalar(@redefine_warnings), 0, 'no redefinition warnings from repeated import_accessor')
        or diag("Warnings: @redefine_warnings");
};

# ============================================
# Test 3: Simulating use in a package
# ============================================

subtest 'no warnings when used in package' => sub {
    @warnings = ();

    # This simulates what Ancient::NeuralForge::Activation would do
    eval q{
        package TestActivation;
        use strict;
        use warnings;

        # Suppose the object class has these properties
        main::Object::Proto::define('Activation', qw(relu relu_grad sigmoid sigmoid_grad));

        # Import into this package
        main::Object::Proto::import_accessors('Activation', 'TestActivation');

        # Import again (simulating module reload or duplicate use)
        main::Object::Proto::import_accessors('Activation', 'TestActivation');

        1;
    };
    die $@ if $@;

    my @redefine_warnings = grep { /redefin/i } @warnings;
    is(scalar(@redefine_warnings), 0, 'no redefinition warnings in package context')
        or diag("Warnings: @redefine_warnings");
};

# ============================================
# Test 4: Import when sub already exists
# ============================================

subtest 'no warning when importing over existing CV' => sub {
    @warnings = ();

    # Define a sub first, then import accessor with same name
    # This should skip the import (existing CV takes precedence)
    eval q{
        package ConflictTest;
        use strict;
        use warnings;

        # Pre-existing sub
        sub existing_func { return "original" }

        main::Object::Proto::define('Conflicting', qw(existing_func other_prop));

        # This should NOT overwrite and NOT warn
        main::Object::Proto::import_accessors('Conflicting', 'ConflictTest');

        1;
    };
    die $@ if $@;

    my @redefine_warnings = grep { /redefin/i } @warnings;
    is(scalar(@redefine_warnings), 0, 'no redefinition warning when sub exists')
        or diag("Warnings: @redefine_warnings");

    # Verify the original sub is preserved
    is(ConflictTest::existing_func(), "original", 'existing sub preserved');
};

# ============================================
# Test 5: Cross-package imports
# ============================================

subtest 'no warnings on cross-package imports' => sub {
    @warnings = ();

    eval q{
        package SourceClass;
        main::Object::Proto::define('DataPoint', qw(val label));
        1;
    };
    die $@ if $@;

    eval q{
        package TargetClass1;
        main::Object::Proto::import_accessors('DataPoint', 'TargetClass1');
        1;
    };
    die $@ if $@;

    eval q{
        package TargetClass2;
        main::Object::Proto::import_accessors('DataPoint', 'TargetClass2');
        1;
    };
    die $@ if $@;

    # Import again to both
    eval q{
        package TargetClass1;
        main::Object::Proto::import_accessors('DataPoint', 'TargetClass1');
        1;
    };
    die $@ if $@;

    my @redefine_warnings = grep { /redefin/i } @warnings;
    is(scalar(@redefine_warnings), 0, 'no warnings on cross-package imports')
        or diag("Warnings: @redefine_warnings");
};

# ============================================
# Test 6: Verify accessors still work after multiple imports
# ============================================

subtest 'accessors work correctly after multiple imports' => sub {
    Object::Proto::define('TestItem', qw(foo bar));
    Object::Proto::import_accessors('TestItem', 'main');
    Object::Proto::import_accessors('TestItem', 'main');  # Duplicate

    my $item = TestItem->new('hello', 42);

    is(foo($item), 'hello', 'foo accessor works');
    is(bar($item), 42, 'bar accessor works');

    foo($item, 'world');
    is(foo($item), 'world', 'foo setter works');
};

done_testing();
