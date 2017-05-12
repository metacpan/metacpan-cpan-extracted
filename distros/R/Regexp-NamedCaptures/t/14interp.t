#!perl
use warnings;
use Test::More tests => 4;

my $RE = '(?<\$_>...)';
TODO: {
    local $TODO = "100% interpolated patterns aren't converted";
    is( eval(
                  "#line "
                . ( 1 + __LINE__ ) . " \""
                . __FILE__ . "\"\n"
                . "use Regexp::NamedCaptures;\n"
                . "use re 'eval';\n"
                . "qr/\$RE/"
            )
            || $@,
        ''
    );
}

is( eval(
              "#line "
            . ( 1 + __LINE__ ) . " \""
            . __FILE__ . "\"\n"
            . "use Regexp::NamedCaptures;\n"
            . "use re 'eval';\n"
            . "qr/(?#)\$RE/"
        )
        || $@,
    '(?-xism:(?{$_=undef})(?#)(...)(?{$_=$^N}))'
);

is( eval(
              "#line "
            . ( 1 + __LINE__ ) . " \""
            . __FILE__ . "\"\n"
            . "use Regexp::NamedCaptures;\n"
            . "use re 'eval';\n"
            . "qr/\$RE(?#)/"
        )
        || $@,
    '(?-xism:(?{$_=undef})(...)(?{$_=$^N})(?#))'
);
is( eval(
              "#line "
            . ( 1 + __LINE__ ) . " \""
            . __FILE__ . "\"\n"
            . "use Regexp::NamedCaptures;\n"
            . "use re 'eval';\n"
            . "qr/(?#)\$RE(?#)/"
        )
        || $@,
    '(?-xism:(?{$_=undef})(?#)(...)(?{$_=$^N})(?#))'
);

