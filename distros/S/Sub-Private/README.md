# NAME

Sub::Private - Private subroutines and methods

# VERSION

Version 0.04

# SYNOPSIS

    package Foo;
    use Sub::Private;

    sub foo :Private {
        return 42;
    }

    sub bar {
        return foo() + 1;
    }

# DESCRIPTION

This module provide a `:Private` attribute for subroutines.
By using the attribute you get truly private methods.

# AUTHOR

Original Author:
Peter Makholm, `<peter at makholm.net>`

Current maintainer:
Nigel Horne, `<njh@bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-sub-private at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Private](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Private).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Private

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Private](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Private)

- Search CPAN

    [http://search.cpan.org/dist/Sub-Private](http://search.cpan.org/dist/Sub-Private)

# ACKNOWLEDGEMENTS

# COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
