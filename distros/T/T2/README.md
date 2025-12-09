# NAME

T2 - Define the [T2](https://metacpan.org/pod/T2) namespace that can always be used to access functionality
from a Test2 bundle such as [Test2::V1](https://metacpan.org/pod/Test2%3A%3AV1).

# DESCRIPTION

If you want a global `T2` that can be called from anywhere, without needing to
import [Test2::V1](https://metacpan.org/pod/Test2%3A%3AV1) in every package, you can do that with the [T2](https://metacpan.org/pod/T2) module.

This defines the [T2](https://metacpan.org/pod/T2) namespace so you can always call methods on it like
`T2->ok(1, "pass")` and `T2->done_testing`.

# SYNOPSIS

Create a file/package somewhere to initialize it. Only initialize it once!

    package My::Global::T2;

    # Load Test2::V1 (or future bundle)
    # Add any customizations like including extra tools, overriding tools, etc.
    use Test2::V1 ...;

    # Load T2, it will find the T2() handle in the current package and make it global
    use T2;

    #########################################
    # Alternatively you can do this:
    my $handle = Test2::V1::Handle->new(...);
    require T2;
    T2->import($handle);

Now use it somewhere in your code:

    use My::Global::T2;

Now T2 is available from any package

    T2->ok(1, "pass");
    T2->ok(0, "fail");

    T2->done_testing;

**Note:** In this case T2 is a package name, not a function, so `T2()` will
not work. However you can import [Test2::V1](https://metacpan.org/pod/Test2%3A%3AV1) into any package providing a T2()
function that will be used preferentially to the [T2](https://metacpan.org/pod/T2) namespace.

**Bonus:** You can use the `T2::tool(...)` form to leverage the original
prototype of the tool.

    T2::is(@foo, 3, "Array has 3 elements");

Without the prototype (method form does not allow prototypes) you would have to
prefix scalar on `@foo`:

    T2->is(scalar(@foo), 3, "Array matches expections");

# SOURCE

The source code repository for T2 can be found at
`https://github.com/Test-More/T2/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
