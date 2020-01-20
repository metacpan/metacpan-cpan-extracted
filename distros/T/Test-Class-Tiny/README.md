# NAME

Test::Class::Tiny - xUnit in Perl, simplified

# SYNOPSIS

    package t::mytest;

    use parent qw( Test::Class::Tiny );

    __PACKAGE__->runtests() if !caller;

    sub T_startup_something {
        # Runs at the start of the test run.
    }

    sub something_T_setup {
        # Runs before each normal test function
    }

    # Expects 2 assertions:
    sub T2_normal {
        ok(1, 'yes');
        ok( !0, 'no');
    }

    # Ignores assertion count:
    sub T0_whatever {
        ok(1, 'yes');
    }

    sub T_teardown_something {
        # Runs after each normal test function
    }

    sub T_shutdown_something {
        # Runs at the end of the test run.
    }

# STATUS

This module is **EXPERIMENTAL**. If you use it, you MUST check the changelog
before upgrading to a new version. Any CPAN distributions that use this module
could break whenever this module is updated.

# DESCRIPTION

[Test::Class](https://metacpan.org/pod/Test::Class) has served Perl’s xUnit needs for a long time
but is incompatible with the [Test2](https://metacpan.org/pod/Test2) framework. This module allows for
a similar workflow but in a way that works with both [Test2](https://metacpan.org/pod/Test2) and the older,
[Test::Builder](https://metacpan.org/pod/Test::Builder)-based modules.

# HOW (AND WHY) TO USE THIS MODULE

xUnit encourages well-designed tests by encouraging organization of test
logic into independent chunks of test logic rather than a single monolithic
block of code.

xUnit provides standard hooks for:

- startup: The start of all tests
- setup: The start of an individual test group (i.e., Perl function)
- teardown: The end of an individual test group
- shutdown: The end of all tests

To write functions that execute at these points in the workflow,
name those functions with the prefixes `T_startup_`, `T_setup_`,
`T_teardown_`, or `T_shutdown_`. **Alternatively**, name such functions
with the _suffixes_ `_T_startup`, `_T_setup`, `_T_teardown`, or
`_T_shutdown`.

To write a test function—i.e., a function that actually runs some
assertions—prefix the function name with `T`, the number of test assertions
in the function, then an underscore. For example, a function that contains
9 assertions might be named `T9_check_validation()`. If that function
doesn’t run exactly 9 assertions, a test failure is produced.

To forgo counting test assertions, use 0 as the test count, e.g.,
`T0_check_validation()`.

You may alternatively use suffix-style naming for test functions well,
e.g., `check_validation_T9()`, `check_validation_T0()`.

The above convention is a significant departure from [Test::Class](https://metacpan.org/pod/Test::Class),
which uses Perl subroutine attributes to indicate this information.
Using method names is dramatically simpler to implement and also easier
to type.

In most other respects this module attempts to imitate [Test::Class](https://metacpan.org/pod/Test::Class).

## PLANS

The concept of a global “plan” (i.e., an expected number of assertions)
isn’t all that sensible with xUnit because each test function has its
own plan. So, ideally the total number of expected assertions for a given
test module is just the sum of all test functions’ expected assertions.

Thus, currently, `runtests()` sets the [Test2::Hub](https://metacpan.org/pod/Test2::Hub) object’s plan to
`no_plan` if the plan is undefined.

# TEST INHERITANCE

Like [Test::Class](https://metacpan.org/pod/Test::Class), this module seamlessly integrates inherited methods.
To have one test module inherit another module’s tests, just make that
first module a subclass of the latter.

**CAVEAT EMPTOR:** Inheritance in tests, while occasionally useful, can also
make for difficult maintenance over time if overused. Where I’ve found it
most useful is cases like [Promise::ES6](https://metacpan.org/pod/Promise::ES6), where each test needs to run with
each backend implementation.

# RUNNING YOUR TEST

To use this module to write normal Perl test scripts, just define
the script’s package (ideally not `main`, but it’ll work) as a subclass of
this module. Then put the following somewhere in the script:

    __PACKAGE__->runtests() if !caller;

Your test will thus execute as a “modulino”.

# SPECIAL FEATURES

- As in [Test::Class](https://metacpan.org/pod/Test::Class), a `SKIP_CLASS()` method may be defined. If this
method returns truthy, then the class’s tests are skipped, and that truthy
return is given as the reason for the skip.
- The `TEST_METHOD` environment variable is honored as in [Test::Class](https://metacpan.org/pod/Test::Class).
- [Test::Class](https://metacpan.org/pod/Test::Class)’s `fail_if_returned_early()` method is NOT recognized
here because an early return will already trigger a failure.
- Within a test method, `num_tests()` may be called to retrieve the
number of expected test assertions.
- To define a test function whose test count isn’t known until runtime,
name it **without** the usual `T$num` prefix, then at runtime do:

        $test_obj->num_method_tests( $name, $count )

    See `t/` in the distribution for an example of this.

# COMMON PITFALLS

Avoid the following:

- Writing startup logic outside of the module class, e.g.:

        if (!caller) {
            my $mock = Test::MockModule->new('Some::Module');
            $mock->redefine('somefunc', sub { .. } );

            __PACKAGE__->runtests();
        }

    The above works _only_ if the test module runs in its own process; if you try
    to run this module with anything else it’ll fail because `caller()` will be
    truthy, which will prevent the mocking from being set up, which your test
    probably depends on.

    Instead of the above, write a wrapper around `runtests()`, thus:

        sub runtests {
            my $self = shift;

            my $mock = Test::MockModule->new('Some::Module');
            $mock->redefine('somefunc', sub { .. } );

            $self->SUPER::runtests();
        }

    This ensures your test module will always run with the intended mocking.

- REDUX: Writing startup logic outside of the module class, e.g.:

        my $mock = Test::MockModule->new('Some::Module');
        $mock->redefine('somefunc', sub { .. } );

        __PACKAGE__->runtests() if !caller;

    This is even worse than before because the mock will be global, which
    will quietly apply it where we don’t intend. This produces
    action-at-a-distance bugs, which can be notoriously hard to find.

# SEE ALSO

Besides [Test::Class](https://metacpan.org/pod/Test::Class), you might also look at the following:

- [Test2::Tools::xUnit](https://metacpan.org/pod/Test2::Tools::xUnit) also implements xUnit for [Test2](https://metacpan.org/pod/Test2) but doesn’t
allow inheritance.
- [Test::Class::Moose](https://metacpan.org/pod/Test::Class::Moose) works with [Test2](https://metacpan.org/pod/Test2), but the [Moose](https://metacpan.org/pod/Moose) requirement
makes use in CPAN modules problematic.

# AUTHOR

Copyright 2019 [Gasper Software Consulting](http://gaspersoftware.com) (FELIPE)

# LICENSE

This code is licensed under the same license as Perl itself.
