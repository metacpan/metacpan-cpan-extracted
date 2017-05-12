use strict;
use warnings;
use Test::More;

{
    package Parser;

    use Parse::Keyword { foo => \&parse_foo };

    sub foo {}
    sub parse_foo {
        lex_peek(99999999);
        return sub {};
    }

    ::is_deeply([ foo ], []);
}

is(__LINE__, 19);

done_testing;
