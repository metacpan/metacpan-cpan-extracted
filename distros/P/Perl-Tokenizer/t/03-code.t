#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 90;

use Perl::Tokenizer qw(perl_tokens);

my @tokens = (
    [

        'tr{1{{{}}\}\}\{\{\{\{}3}{1{}/2\}\{{}\}}' => 'transliteration',

    ],

    [

     # The first comment is tricky to parse.
     'tr{}   # comment 1
           //   # comment 2' => ('transliteration', 'horizontal_space', 'comment',)

    ],

    [

     '$s[0]{tr}[-1]-- > ++$m{ y };' => (
                                        'scalar_sigil',        'var_name',
                                        'right_bracket_open',  'number',
                                        'right_bracket_close', 'curly_bracket_open',
                                        'bare_word',           'curly_bracket_close',
                                        'right_bracket_open',  'operator',
                                        'number',              'right_bracket_close',
                                        'operator',            'horizontal_space',
                                        'operator',            'horizontal_space',
                                        'operator',            'scalar_sigil',
                                        'var_name',            'curly_bracket_open',
                                        'horizontal_space',    'bare_word',
                                        'horizontal_space',    'curly_bracket_close',
                                        'semicolon',
                                       )

    ],

    [

     '$h{s}++ < 3.14159' => (
                             'scalar_sigil',        'var_name', 'curly_bracket_open', 'bare_word',
                             'curly_bracket_close', 'operator', 'horizontal_space',   'operator',
                             'horizontal_space',    'number'
                            )

    ],

    [

     'while(<$fh>){print}' => (
                               'keyword',            'parenthesis_open', 'glob_readline', 'parenthesis_close',
                               'curly_bracket_open', 'keyword',          'curly_bracket_close'
                              )

    ],

    [

     '-s $foo;' => ('file_test', 'horizontal_space', 'scalar_sigil', 'var_name', 'semicolon')

    ],

    [

     'print STDERR 42,"bar"' =>
       ('keyword', 'horizontal_space', 'special_fh', 'horizontal_space', 'number', 'comma', 'double_quoted_string')

    ],

    [

     <<'CODE'
my @a = (<<'EOT',<<"EOF",<<EOD);   # here-docs
foo
EOT
bar
baz
EOF
qux
EOD
CODE

       => (
           'keyword',          'horizontal_space',  'array_sigil',      'var_name',
           'horizontal_space', 'operator',          'horizontal_space', 'parenthesis_open',
           'heredoc_beg',      'comma',             'heredoc_beg',      'comma',
           'heredoc_beg',      'parenthesis_close', 'semicolon',        'horizontal_space',
           'comment',          'vertical_space',    'heredoc',          'vertical_space',
           'heredoc',          'vertical_space',    'heredoc',          'vertical_space'
          )

    ],

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
