## Mylisp 

Mylisp is like lisp which could transfer to Perl5.

To install this tool, please install Perl5 in your computer.

    > cpan
    > install Mylisp
    > mylisp

    This is mylisp REPL, type enter to exit.
    >> (say 'hello world!')
    .. say "hello world!"

    >> (say $hash[:key])
    .. say($hash->{'key'})

    >> (say $hash[$key])
    .. say($hash->{$key});

    >> (say $hash[:key][$key])
    .. say($hash->['key'][$key])

    >> (say $array[1])
    .. say($array->[1])

DESCRIPTION

see Mylisp.pod.

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Mylisp

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mylisp

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Mylisp

    CPAN Ratings
        http://cpanratings.perl.org/d/Mylisp

    Search CPAN
        http://search.cpan.org/dist/Mylisp/


LICENSE AND COPYRIGHT

Copyright (C) 2017 Micheal Song

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

