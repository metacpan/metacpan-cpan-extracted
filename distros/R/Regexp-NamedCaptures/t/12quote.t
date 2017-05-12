#!perl
use warnings;
use Test::More tests => 5;
use Regexp::NamedCaptures;

TODO: {
    local $TODO = "\\Q breaks here.";
    is( eval(
                  "#line "
                . ( 1 + __LINE__ ) . " \""
                . __FILE__ . "\"\n"
                . "use re 'eval';\n"
                . "use Regexp::NamedCaptures;\n"
                . 'qr/(?#)\Q(?<\$_>...)\E/'
            )
            || $@,
        '(?-xism:(?#)\(\?\<\\\$_\>\.\.\.\))'
    );

    is( eval(
                  "#line "
                . ( 1 + __LINE__ ) . " \""
                . __FILE__ . "\"\n"
                . "use re 'eval';\n"
                . "use Regexp::NamedCaptures;\n"
                . 'qr/\Q(?<\\$_>...)/'
            )
            || $@,
        '(?-xism:\(\?\<\$_\>\.\.\.\))'
    );

    is( eval(
                  "#line "
                . ( 1 + __LINE__ ) . " \""
                . __FILE__ . "\"\n"
                . "use re 'eval';\n"
                . "use Regexp::NamedCaptures;\n"
                . 'qr/\Q(?<\$_>...)\E(?#)/'
            )
            || $@,
        '(?-xism:\(\?\<\\$_\>\.\.\.\)(?#))'
    );
}

is( eval(
              "#line "
            . ( 1 + __LINE__ ) . " \""
            . __FILE__ . "\"\n"
            . "use re 'eval';\n"
            . "use Regexp::NamedCaptures;\n"
            . 'qr/(\Q?<\$_>...\E)/'
        )
        || $@,
    '(?-xism:(\?\<\\\\\\$_\>\.\.\.))'
);
is( eval(
              "#line "
            . ( 1 + __LINE__ ) . " \""
            . __FILE__ . "\"\n"
            . "use re 'eval';\n"
            . "use Regexp::NamedCaptures;\n"
            . 'qr/(?<\$_>\Q...\E)/'
        )
        || $@,
    '(?-xism:(?{$_=undef})(\.\.\.)(?{$_=$^N}))'
);

