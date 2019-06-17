# NAME

Open::This - Try to Do the Right Thing when opening files

# VERSION

version 0.000019

# DESCRIPTION

This module powers the [ot](https://metacpan.org/pod/ot) command line script, which tries to do the right
thing when opening a file.  Imagine your `$ENV{EDITOR}` is set to `vim`.
(This should also work for `emacs` and `nano`.)  The following examples
demonstrate how your input is translated when launching your editor.

    ot Foo::Bar # vim lib/Foo/Bar.pm
    ot Foo::Bar # vim t/lib/Foo/Bar.pm

Imagine this module has a `sub do_something` at line 55.

    ot "Foo::Bar::do_something()" # vim +55 lib/Foo/Bar.pm

Or, when copy/pasting from a stack trace.  (Note that you do not need quotes in
this case.)

    ot Foo::Bar line 36 # vim +36 lib/Foo/Bar.pm

Copy/pasting a `git-grep` result.

    ot lib/Foo/Bar.pm:99 # vim +99 Foo/Bar.pm

Copy/pasting a partial GitHub URL.

    ot lib/Foo/Bar.pm#L100 # vim +100 Foo/Bar.pm

Open a local file on the GitHub web site in your web browser.  From within a
checked out copy of https://github.com/oalders/open-this

    ot -b Foo::Bar

Open a local file at the correct line on the GitHub web site in your web
browser.  From within a checked out copy of
https://github.com/oalders/open-this:

    ot -b Open::This line 50
    # https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L50

# SUPPORTED EDITORS

This code has been well tested with `vim`.  It should also work with `nvim`,
`emacs`, `pico`, `nano` and `kate`.  Patches for other editors are very
welcome.

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
    #     file_name     => 't/lib/Foo/Bar.pm',
    #     line_number   => 3,
    #     original_text => 't/lib/Foo/Bar.pm:32',
    #     sub_name      => 'do_something',
    # };

## to\_editor\_args

Given a scalar value, this calls `parse_text()` and returns an array of values
which can be passed at the command line to an editor.

    my @args = to_editor_args('Foo::Bar::do_something()');
    # @args = ( '+3', 't/lib/Foo/Bar.pm' );

## editor\_args\_from\_parsed\_text

If you have a `hashref` from the `parse_text` function, you can get editor
args via this function.  (The faster way is just to call `to_editor_args`
directly.)

    my @args
        = editor_args_from_parsed_text( parse_text('t/lib/Foo/Bar.pm:32') );

## maybe\_get\_url\_from\_parsed\_text

Tries to return an URL to a Git repository for a checked out file.  The URL
will be built using the `origin` remote and the name of the current branch.  A
line number will be attached if it can be parsed from the text.  This has only
currently be tested with GitHub URLs and it assumes you're working on a branch
which has already been pushed to your remote.

    my $url = maybe_get_url_from_parsed_text( parse_text('t/lib/Foo/Bar.pm:32'));
    # $url might be something like: https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L32

# ENVIRONMENT VARIABLES

By default, `ot` will search your `lib` and `t/lib` directories for local
files.  You can override this via the `$ENV{OPEN_THIS_LIBS}` variable.  It
accepts a comma-separated list of libs.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
