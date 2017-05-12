use strict;
use warnings;
use Test::More;

BEGIN {
    if (!eval { require B::Hooks::EndOfScope }) {
        plan skip_all => "B::Hooks::EndOfScope is required for this test";
    }
}

BEGIN {
    package My::Parser;
    use Exporter 'import';
    our @EXPORT = 'foo';
    use Parse::Keyword { foo => \&parse_foo };

    sub foo { $_[0]->() }
    sub parse_foo {
        lex_read_space;
        die "syntax error" unless lex_peek eq '{';
        lex_read;
        lex_stuff(
            '{'
              . 'my $foo = 42;'
              . '{'
                  . 'BEGIN { B::Hooks::EndOfScope::on_scope_end {'
                      . 'Parse::Keyword::lex_stuff(q[}])'
                  . '} }'
        );
        my $body = parse_block;
        return sub { $body };
    }

    $INC{'My/Parser.pm'} = __FILE__;
}

use My::Parser;

is(foo { $foo }, 42);
{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    is(foo { my $foo = 12; $foo }, 12);
    is($warnings, undef);
}

done_testing;
