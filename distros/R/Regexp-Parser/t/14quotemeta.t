use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Tests for \Q...\E (quotemeta) support

my $r = Regexp::Parser->new;

# === Basic \Q...\E outside character classes ===

sub parse_ok {
    my ($input, $expected_vis, $desc) = @_;
    my $ok = $r->regex($input);
    ok($ok, "parse '$input'") or do {
        diag("error: " . ($r->errmsg || "unknown"));
        return;
    };
    is($r->visual, $expected_vis, $desc || "visual '$input'");
}

# Simple quotemeta — metacharacters escaped
parse_ok('\Qfoo.bar\E',    'foo\.bar',       '\Q escapes dot');
parse_ok('\Q.*+?\E',       '\.\*\+\?',       '\Q escapes quantifier metacharacters');
parse_ok('\Q(a|b)\E',      '\(a\|b\)',        '\Q escapes parens and pipe');
parse_ok('\Q[abc]\E',      '\[abc\]',         '\Q escapes brackets');
parse_ok('\Q{3}\E',        '\{3\}',           '\Q escapes braces');
parse_ok('\Q^$\E',         '\^\$',            '\Q escapes anchors');
parse_ok('\Q\\\E',         '\\\\',            '\Q escapes backslash');

# Non-metacharacters pass through unchanged
parse_ok('\Qhello\E',      'hello',           '\Q on plain text is identity');
parse_ok('\Q123\E',         '123',             '\Q on digits');

# \Q without \E — quotes to end of pattern
parse_ok('a\Qfoo.*',       'afoo\.\*',        '\Q without \E quotes to end');
parse_ok('\Qfoo',           'foo',             '\Q without \E, no metacharacters');

# \Q with surrounding normal regex
parse_ok('^start\Q.end\E$', '^start\.end$',   'normal^..\Q..\E..normal$');
parse_ok('(\Qfoo.bar\E)',   '(foo\.bar)',      '\Q inside capture group');
parse_ok('(?:\Qa+\E)',      '(?:a\+)',         '\Q inside non-capturing group');
parse_ok('a\Qb.c\Ed',       'ab\.cd',          'mixed normal and quotemeta');

# Multiple \Q..\E segments
parse_ok('\Qa.\Eb\Qc.\Ed', 'a\.bc\.d',        'two \Q..\E segments');

# Empty \Q\E
parse_ok('\Q\E',            '',                'empty \Q\E');
parse_ok('a\Q\Eb',          'ab',              'empty \Q\E between chars');

# \E without preceding \Q (no-op, like Perl)
parse_ok('foo\Ebar',        'foobar',          '\E without \Q is no-op');

# === \Q...\E inside character classes ===

parse_ok('[\Qabc\E]',      '[abc]',           '\Q in char class, plain chars');
parse_ok('[\Qa-z\E]',      '[a\-z]',          '\Q in char class escapes dash');
parse_ok('[\Q^a\E]',       '[\^a]',           '\Q in char class escapes caret');

# === qr() produces working regexes ===

{
    $r->regex('\Qfoo.bar\E');
    my $qr = $r->qr;
    like('foo.bar', $qr, 'qr matches literal dot');
    unlike('fooXbar', $qr, 'qr rejects non-dot');
}

{
    $r->regex('\Q(a|b)+\E');
    my $qr = $r->qr;
    like('(a|b)+', $qr, 'qr matches literal parens/pipe/plus');
    unlike('aaa', $qr, 'qr rejects non-literal');
}

# === Round-trip: parse → visual → re-parse → visual ===

my @roundtrip = (
    'foo\.bar',
    'a\.\*\+',
    '\(a\|b\)',
    '\[abc\]',
    '\^\$',
);

for my $pattern (@roundtrip) {
    $r->regex($pattern) or do {
        fail("roundtrip parse '$pattern'");
        next;
    };
    my $vis1 = $r->visual;
    $r->regex($vis1) or do {
        fail("roundtrip re-parse '$pattern'");
        next;
    };
    my $vis2 = $r->visual;
    is($vis2, $vis1, "round-trip '$pattern'");
}

# === Walker traversal works on quotemeta-parsed tree ===

{
    $r->regex('\Qfoo.bar\E');
    my $w = $r->walker;
    my @nodes;
    while (my $node = $w->()) {
        push @nodes, $node;
    }
    # Adjacent exact nodes get merged into one
    is(scalar @nodes, 1, 'walker finds merged exact node');
    is($nodes[0]->visual, 'foo\.bar', 'merged node has escaped visual');
    is($nodes[0]->data, 'foo.bar', 'merged node data is literal string');
}

done_testing;
