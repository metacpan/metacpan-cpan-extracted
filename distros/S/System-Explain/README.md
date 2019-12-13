# NAME

System::Explain - run a system command and explain the result

# SYNOPSIS

    use System::Explain "command, verbose, errors";
    sys qw(ls -al);

The `sys` function runs a system command, checks the result, and comments on
it to STDOUT.

# DESCRIPTION

System::Explain is a standalone release of [System](https://metacpan.org/pod/System), part of [Gedcom](https://metacpan.org/pod/Gedcom)
v1.20 and earlier.

# FUNCTIONS

# import

Say `use System::Explain "list, of, options"` to use this module.
The options are: `command` (to print the command before running it),
`error` (to report on the exit status), and `verbose` (to do both of those).

# sys

`sys(@command);` runs `@command` (by passing `@command` to `system()`) and
optionally prints human-readable information about the result (specifically,
about the return value of `system()`).

Returns the return value of the `system()` call.

# dsys

As ["sys"](#sys), but dies if the `system()` call fails.

# SEE ALSO

[IPC::System::Simple](https://metacpan.org/pod/IPC::System::Simple), [Proc::ChildError](https://metacpan.org/pod/Proc::ChildError), [Process::Status](https://metacpan.org/pod/Process::Status)
(among others).

# LICENSE

Copyright (C) 2012 Paul Johnson <pjcj@cpan.org>

Also Copyright (C) 1999-2012 Paul Johnson; Copyright (C) 2019 Christopher White

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Paul Johnson <paul@pjcj.net>
