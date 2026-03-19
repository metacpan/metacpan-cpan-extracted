use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Test that the parser correctly rejects invalid regex patterns.
# Some patterns fail during regex() (SIZE_ONLY pass), others fail
# during visual()/parse() (tree-building pass). We test both stages.

# Patterns that fail during regex() (SIZE_ONLY pass)
my @fail_on_regex = (
    ['(abc',      'unmatched open paren'],
    ['abc)',      'unmatched close paren'],
    ['((a)',      'nested unmatched open paren'],
    ['[abc',      'unmatched open bracket'],

    # Bad conditionals
    ['(?(??{bad})c|d)',  'bad conditional (embedded pattern)'],
    ['(?(?p{bad})c|d)',  'bad conditional (?p)'],
    ['(?(?>bad)c|d)',    'bad conditional (atomic)'],
    ['(?(?:bad)c|d)',    'bad conditional (non-capturing)'],
    ['(?(?i)c|d)',       'bad conditional (flag)'],
    ['(?(?#bad)c|d)',    'bad conditional (comment)'],
    ['(?(BAD)c|d)',      'bad conditional (alpha name)'],
    ['(?(1BAD)c|d)',     'bad conditional (digit+alpha)'],
    ['(?()c|d)',         'bad conditional (empty)'],
);

# Patterns that succeed on regex() but croak during visual()
# because error checks are guarded by !&SIZE_ONLY
my @fail_on_visual = (
    ['*',         'nothing to quantify (*)'],
    ['+',         'nothing to quantify (+)'],
);

plan tests => scalar(@fail_on_regex) + scalar(@fail_on_visual) * 2;

for my $case (@fail_on_regex) {
    my ($pat, $desc) = @$case;
    my $r = Regexp::Parser->new;
    my $ok = eval { $r->regex($pat) };
    ok(!$ok || $@, "reject on regex(): '$pat' — $desc");
}

for my $case (@fail_on_visual) {
    my ($pat, $desc) = @$case;
    my $r = Regexp::Parser->new;
    my $ok = eval { $r->regex($pat) };
    ok($ok, "regex() accepts '$pat' (deferred check)");
    my $vis = eval { $r->visual };
    ok($@, "croak on visual(): '$pat' — $desc");
}
