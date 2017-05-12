use strict;
use warnings;
use Test::More tests => 42;
use charnames qw(:full);
binmode STDERR, ':utf8';

use lib '../lib';
use lib 'lib';
use Perl6::Str;
use Perl6::Str::Test qw(expand_str is_eq);

my $acute = "\N{COMBINING ACUTE ACCENT}";

my @tests = (
    # source, pattern, expected
    ['abc',  'xyz', 'abc'   ],
    ['abc',  'XyZ', 'AbC'   ],
    ['ab',   'XyZ', 'Ab'    ],
    ['abcd', 'Xy',  'Abcd'  ],
    ['abcd', 'yY',  'aBCD'  ],
    ['Abc',  '',    'Abc'   ], 
    ['',     'Xyz',  ''     ],

    # now with characters that don't carry case information
    ['1',    'x',    '1'    ],
    ['1',    'X',    '1'    ],
    ['a',    '0',    'a'    ],
    ['A',    '0',    'A'    ],
    ['Abc',  ' ',    'Abc'  ],
    ['abcd', ' Y ',  'aBcd' ],
    ['ABCD', ' y ',  'AbCD' ],
    ['abcd', ' Y',   'aBCD' ],
    ['ABCD', ' y',   'Abcd' ],

    # Now with some weird cases
    # U+1FFC is greek omega in title case with an accent
    ["\N{GREEK CAPITAL LETTER OMEGA WITH PROSGEGRAMMENI}", "a", "\N{GREEK SMALL LETTER OMEGA WITH YPOGEGRAMMENI}"],
    ["a", "\N{GREEK CAPITAL LETTER OMEGA WITH PROSGEGRAMMENI}", "A"],
    ["A$acute", "o$acute", "a$acute"],
    # test that a two codepoint grapheme is counted as one char in the pattern
    ["aou",     "O${acute}xX", "AoU"],
    # test that a two codepoint grapheme is counted as one char in the source
    ["a${acute}ou", "xYz",  "a${acute}Ou"],
);

for my $spec (@tests){
    my ($source, $pattern, $expected) = @$spec;
    my $s = Perl6::Str->new($source);
    is_eq $s->samecase($pattern), $expected, qq{"$source"->samecase($pattern) eq $expected};
    is_eq $s, $source, qq{"$source" unchanged};
}
