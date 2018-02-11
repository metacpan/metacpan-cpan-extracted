# NAME

Open::This - Try to Do the Right Thing when opening files

# VERSION

version 0.000004

# DESCRIPTION

This module powers the `ot` command line script, which tries to do the right
thing when opening a file.  Imagine your `$EDITOR` %ENV var is set to `vim`.
(This should also work for `emacs` and `nano`.

    ot Foo::Bar # vim lib/Foo/Bar.pm
    ot Foo::Bar # vim t/lib/Foo/Bar.pm

Imagine this module has a sub called do\_something at line 55.

    ot "Foo::Bar::do_something()" # vim +55 lib/Foo/Bar.pm

Or, when copy/pasting from a stack trace.  Note that you do not need quotes in
this case:

    ot Foo::Bar line 36 # vim +36 lib/Foo/Bar.pm

Copy/pasting a `git-grep` result:

    ot lib/Foo/Bar.pm:99 # vim +99 Foo/Bar.pm

# FUNCTIONS

## parse\_text

Given a scalar value or an array of scalars, this function will try to extract
useful information from it.  Returns a hashref on success.  Returns undef on
failure.  `file_name` is the only hash key which is guaranteed to be in the
hash.

    use Open::This qw( parse_text );
    my $parsed = parse_text('t/lib/Foo/Bar.pm:32');

    # $parsed = { file_name => 't/lib/Foo/Bar.pm', line_number => 32, }

    my $with_sub_name = parse_text( 'Foo::Bar::do_something()' );

    # $with_sub_name = {
    #     file_name   => 't/lib/Foo/Bar.pm',
    #     line_number => 3,
    #     sub_name    => 'do_something',
    # };

## to\_editor\_args

Given a scalar value, this calls `parse_text()` and returns an array of values
which can be passed at the command line to an editor.

    my @args = to_editor_args('Foo::Bar::do_something()');
    # @args = ( '+3', 't/lib/Foo/Bar.pm' );

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
