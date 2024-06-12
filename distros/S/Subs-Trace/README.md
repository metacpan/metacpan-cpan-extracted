# NAME

Subs::Trace - Trace all calls in a package.

# SYNOPSIS

Similar to

    around 'my_function' => sub {
      my $original = shift;
      print "--> my_function\n";
      $original->(@_);
    };

But for ALL functions in a class.

    package MyClass;

    sub Func1 { ... }
    sub Func2 { ... }
    sub Func3 { ... }

    use Subs::Trace;

    Func1();
    # Prints:
    # --> MyClass::Func1

# DESCRIPTION

This module updates all methods/functions in a class to
also print a message when invoked.

(This is a more of a proof-of-concept than useful!)

# SUBROUTINES/METHODS

## import

NOTE: This must be put at the very bottom of a class.

Also, some reason `INIT{ ... }` is not being called with Moose.

Will attach hooks to all functions defined BEFORE this import call.

# AUTHOR

Tim Potapov, `<tim.potapov at gmail.com>`

# BUGS

Please report any bugs or feature requests to [https://github.com/poti1/subs-trace/issues](https://github.com/poti1/subs-trace/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Subs::Trace

# ACKNOWLEDGEMENTS

TBD

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
