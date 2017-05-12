#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 18;

use Perl::Tokenizer qw(perl_tokens);

my @tokens = (
    [unpack('A*', <<'EOT'), 'compiled_regex'],
qr{
        {-}
        (?>
            [^{}\\]+
                |
            \\.
                |
            (??{$foo{$h->{s}}})
        )*
        (?:(\{\}))
        (?{ s{}{\}\}\{\{\{\}\{{}\}\}\}\}\}\}
        \{\{\{\{\{{{\}{{{{{\}\}\}\{\{\{\}\}}}\{}}\}}}}\{\{\{\{\{}})
        42;
        32;
    }xs
EOT

    ['/1\/42/',                                                                                      'match_regex'],
    ['m<foo<bar>baz>',                                                                               'match_regex'],
    ['m~\G(?:\s+|#?)\{\s*(?:$x|$y|[#{])\s*\}~goc',                                                   'match_regex'],
    ['m{\G(?:\^\w+|[{}]|#(?!\{)|$x)}gco',                                                            'match_regex'],
    ['s/(?<!\\)(?:\\\\)*\K\\(?![\$\\tex])/\\\\/g',                                                   'substitution'],
    ['s{}{\}\}\{\{\{\}\{{}\}\}\}\}\}\}\{\{\{\{\{{{\}{{{{{\}\}\}\{\{\{\}\}}}\{}}\}}}}\{\{\{\{\{}asa', 'substitution'],
    ['s~4\~\~2~1234\~\~99\~~',                                                                       'substitution'],
    ['s{1{2}/3}/4\/{{}}2\}\{\{/im',                                                                  'substitution'],
             );

foreach my $group (@tokens) {
    my ($code, @names) = @{$group};
    perl_tokens {
        my ($token) = @_;
        is($token, shift(@names));
    }
    $code;
    ok(!@names);
}
