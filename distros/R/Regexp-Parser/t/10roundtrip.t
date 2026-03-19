use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Round-trip test: parse a regex, get visual(), re-parse that, get visual() again.
# The two visual() outputs must match.

my @patterns = (
    # Literals and anchors
    'abc',
    '^abc$',
    '\Aabc\z',
    '\Aabc\Z',
    '\bword\b',
    '\Bfoo\B',
    '\Gfoo',

    # Quantifiers
    'a+',
    'a*',
    'a?',
    'a{3}',
    'a{3,}',
    'a{3,5}',
    'a+?',
    'a*?',
    'a??',
    'a{3,5}?',

    # Dot and character classes
    '.',
    'a.b',
    '[abc]',
    '[a-z]',
    '[^abc]',
    '[^a-z]',
    '[\w\d\s]',
    '[\W\D\S]',
    '[\f\b\a]',
    '[\t\n\r]',
    '[\e]',

    # Shorthand classes
    '\w+',
    '\W+',
    '\d+',
    '\D+',
    '\s+',
    '\S+',

    # Escape sequences
    '\a\e\f\n\r\t',
    '\x41',
    '\x{41}',
    '\c@',
    '\cA',

    # Groups - non-capturing
    '(?:abc)',
    '(?:a|b|c)',
    '(?:a(?:b(?:c)))',

    # Groups - capturing
    '(abc)',
    '(a)(b)(c)',
    '(a(b)c)',
    '(a|b)',
    '((a|b)(c|d))',

    # Alternation
    'a|b',
    'a|b|c',
    'abc|def|ghi',
    'a(b|c)d',

    # Flags
    '(?i:abc)',
    '(?s:abc)',
    '(?m:abc)',
    '(?x:abc)',
    '(?im:abc)',
    '(?-i:abc)',
    '(?i-m:abc)',
    '(?i)',
    '(?-i)',

    # Assertions - lookahead
    '(?=abc)',
    '(?!abc)',
    'a(?=b)c',
    'a(?!b)c',

    # Assertions - lookbehind
    '(?<=abc)',
    '(?<!abc)',

    # Atomic groups
    '(?>abc)',
    '(?>a|b)',

    # Backreferences
    '(a)\1',
    '(a)(b)\2',

    # Conditional
    '(?(?=a)b|c)',
    '(?(?!a)b|c)',
    '(?(?<=a)b|c)',
    '(?(?<!a)b|c)',
    '(?(?{1})c|d)',
    '(?(1)b|c)',

    # Comments
    '(?#comment)abc',
    'a(?#mid)b',

    # Code evaluation
    '(?{1})',
    '(??{1})',

    # Unicode properties
    '\p{alpha}',
    '\P{alpha}',

    # POSIX classes in character class
    '[[:alpha:]]',
    '[[:digit:]]',
    '[[:^alpha:]]',

    # Complex combinations
    '^(\w+)\s*=\s*(.+)$',
    '(?:(?:a|b)+(?:c|d)*)',
    '(?i:a(?-i:b)c)',
    '(a+)(b+)\2\1',
    '[\w\-\.]+',
    # '^[a-zA-Z0-9_.+-]+$',  # dash before ] — known issue #6, PR #10

    # Named characters
    '\N{LATIN SMALL LETTER A}',

    # Clump
    '\X+',

    # Quantified groups
    '(abc)+',
    '(?:abc){2,5}',
    '(a|b)*?',
    '(?>abc)+',
);

plan tests => scalar(@patterns) * 2;

for my $pat (@patterns) {
    my $r1 = Regexp::Parser->new;
    my $ok1 = $r1->regex($pat);
    if (!$ok1) {
        fail("parse '$pat': " . ($r1->errmsg || 'unknown error'));
        fail("roundtrip '$pat': skipped");
        next;
    }
    my $vis1 = $r1->visual;
    pass("parse '$pat'");

    # Round-trip: re-parse the visual output
    my $r2 = Regexp::Parser->new;
    my $ok2 = $r2->regex($vis1);
    if (!$ok2) {
        fail("roundtrip '$pat' -> '$vis1': " . ($r2->errmsg || 'unknown error'));
        next;
    }
    my $vis2 = $r2->visual;
    is($vis2, $vis1, "roundtrip '$pat'");
}
