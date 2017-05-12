use strict;
use warnings;
use Test::More;

{
    package Foo;

    use Parse::Keyword { bar => \&bar_parser };

    sub bar { @_ }
    sub bar_parser {
        return sub { return (1, 2, 3) }
    }

    ::is_deeply([bar], [1, 2, 3]);
}

{
    package Bar;

    use Parse::Keyword { baz => \&baz_parser };

    my $code;

    sub baz { $code = $_[0] }
    sub baz_parser {
        lex_read_space;
        my $block = parse_block;
        return (sub { $block }, 1);
    }

    baz {
        1 + 2
    }
    ::is(ref($code), 'CODE');
    ::is($code->(), 3);
}

done_testing;
