# NAME

Test::Base::SubTest - Enables Test::Base to use subtest

# SYNOPSIS

    use Test::Base::SubTest;

    filters { input => [qw/eval/] };
    run {
        my $block = shift;
        is $block->input, $block->expected, $block->name;
    };
    done_testing;

    __DATA__

    ### subtest 1
        === test 1-1
        --- input:    4*2
        --- expected: 8

        === test 1-2
        --- input :   3*3
        --- expected: 9

    ### subtest 2
        === test 2-1
        --- input:    4*3
        --- expected: 12

<div><img src="http://cdn-ak.f.st-hatena.com/images/fotolife/C/Cside/20140116/20140116204246.png?1389872580"></div>

# DESCRIPTION

Test::Base::SubTest is a extension of [Test::Base::Less](https://metacpan.org/pod/Test::Base::Less).

"\#\#\# TEST NAME" is a delimiter of a subtest. Indentaion is necessary.

# FUNCTIONS

This module exports all Test::More's exportable functions, and following functions:

- filters(+{ } : HashRef);

        filters {
            input => [qw/eval/],
        };

    Set a filter for the section name.

- run(\\&subroutine)

        run {
            my $block = shift;
            is $block->input, $block->expected, $block->name;
        };

    Calls the sub for each block. It passes the current block object to the subroutine.

- run\_is(\[data\_name1, data\_name2\])

        run_is input => 'expected';
- run\_is\_deeply(\[data\_name1, data\_name2\])
- register\_filter($name: Str, $code: CodeRef)

    Register a filter for $name using $code.

# DEFAULT FILTERS

This module provides only few filters. If you want to add more filters, pull-reqs welcome.
(I only merge a patch using no depended modules)

- eval

    eval() the code.

- chomp

    `chomp()` the arguments.

- uc

    `uc()` the arguments.

- trim

    Remove extra blank lines from the beginning and end of the data. This
    allows you to visually separate your test data with blank lines.

# REGISTER YOUR OWN FILTER

You can register your own filter by following form:

    use Digest::MD5 qw/md5_hex/;
    Test::Base::Less::register_filter(md5_hex => \&md5_hex);

# USE CODEREF AS FILTER

You can use a CodeRef as filter.

    use Digest::MD5 qw/md5_hex/;
    filters {
        input => [\&md5_hex],
    };

# SEE ALSO

Most of code is taken from [Test::Base::Less](https://metacpan.org/pod/Test::Base::Less). Thank you very match, tokuhirom.

# AUTHOR

Hiroki Honda <cside.story@gmail.com>

# LICENSE

Copyright (C) Hiroki Honda

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
