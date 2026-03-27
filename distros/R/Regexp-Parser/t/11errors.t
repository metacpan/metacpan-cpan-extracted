use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Comprehensive tests for parser error detection and rejection.
#
# The parser has a two-pass model:
#   Pass 1 (SIZE_ONLY): structural checks (parens, brackets, sizing)
#   Pass 2 (tree-building): semantic checks (backrefs, quantifier placement)
#
# error() calls croak — always fatal, sets errnum/errmsg.
# warn()  calls carp  — only during SIZE_ONLY pass (first pass).
#
# Tests are organized by error code category.

# Helper: expect error on regex() call
# Note: regex() catches croak internally and returns undef on failure.
# It does NOT propagate the exception.
sub fails_regex {
    my ($pat, $errcode, $desc) = @_;
    my $r = Regexp::Parser->new;
    my $ok = $r->regex($pat);
    ok(!$ok, "reject on regex(): $desc")
        or diag "  pattern '$pat' was unexpectedly accepted";
    if (defined $errcode) {
        ok($r->errnum && $r->errnum == $errcode,
           "  errnum matches expected code")
            or diag sprintf("  expected errnum %d, got %s",
                            $errcode, $r->errnum // 'undef');
    }
}

# Helper: expect error deferred to visual/parse (pass 2 only)
sub fails_visual {
    my ($pat, $errcode, $desc) = @_;
    my $r = Regexp::Parser->new;
    my $ok = eval { $r->regex($pat); 1 };
    ok($ok, "regex() accepts '$pat' (deferred check)")
        or do { diag "  unexpectedly failed on regex(): $@"; return };
    my $vis = eval { $r->visual; 1 };
    ok(!$vis, "croak on visual(): $desc")
        or diag "  pattern '$pat' should have failed on visual()";
    if (defined $errcode) {
        ok($r->errnum && $r->errnum == $errcode,
           "  errnum matches expected code")
            or diag sprintf("  expected errnum %d, got %s",
                            $errcode, $r->errnum // 'undef');
    }
}

# Helper: expect warning during regex() (SIZE_ONLY pass)
sub warns_regex {
    my ($pat, $desc) = @_;
    my $r = Regexp::Parser->new;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $ok = eval { $r->regex($pat); 1 };
    ok($ok, "regex() succeeds for '$pat'")
        or diag "  unexpectedly failed: $@";
    ok(@warnings > 0, "warning emitted: $desc")
        or diag "  pattern '$pat' produced no warnings";
    return @warnings;
}

# Helper: expect clean parse (no errors, no warnings)
sub parses_ok {
    my ($pat, $desc) = @_;
    my $r = Regexp::Parser->new;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $ok = eval { $r->regex($pat); 1 };
    ok($ok, "parses cleanly: $desc")
        or diag "  pattern '$pat' failed: $@";
    is(scalar @warnings, 0, "  no warnings for '$pat'")
        or diag "  got warnings: @warnings";
}

# Access error code constants from the parser
my $r = Regexp::Parser->new;

##
## 1. STRUCTURAL ERRORS — Unmatched delimiters (RPe_LPAREN, RPe_RPAREN, RPe_LBRACK)
##

fails_regex('(abc',       ($r->RPe_LPAREN)[0],  'unmatched open paren');
fails_regex('((a)',       ($r->RPe_LPAREN)[0],  'nested unmatched open paren');
fails_regex('(((a))',     ($r->RPe_LPAREN)[0],  'deeply nested unmatched paren');
fails_regex('abc)',       ($r->RPe_RPAREN)[0],  'unmatched close paren');
fails_regex('[abc',       ($r->RPe_LBRACK)[0],  'unmatched open bracket');
fails_regex('[a-z',       ($r->RPe_LBRACK)[0],  'unmatched bracket with range');
fails_regex('[[:alpha:]', ($r->RPe_LBRACK)[0],  'unmatched bracket with POSIX');

##
## 2. QUANTIFIER ERRORS — RPe_BCURLY, RPe_EQUANT
##

# {n,m} with n > m
fails_regex('a{5,3}',    ($r->RPe_BCURLY)[0],  '{n,m} with n > m');
fails_regex('a{10,0}',   ($r->RPe_BCURLY)[0],  '{10,0} with n > m');
fails_regex('a{100,1}',  ($r->RPe_BCURLY)[0],  '{100,1} with n > m');

# Quantifier follows nothing — deferred to visual pass
fails_visual('*',         ($r->RPe_EQUANT)[0],  'bare * quantifier');
fails_visual('+',         ($r->RPe_EQUANT)[0],  'bare + quantifier');
fails_visual('?',         ($r->RPe_EQUANT)[0],   'bare ? quantifier');

# Nested quantifiers (RPe_NESTED) — quantifier following quantifier
fails_visual('a**',       ($r->RPe_NESTED)[0],   'nested quantifier **');
fails_visual('a+*',       ($r->RPe_NESTED)[0],   'nested quantifier +*');
fails_visual('a{2}{3}',   ($r->RPe_NESTED)[0],   'nested quantifier {2}{3}');
fails_visual('a{2}*',     ($r->RPe_NESTED)[0],   'nested quantifier {2}*');

# Zero-width quantifier warnings (RPe_ZQUANT, RPe_NULNUL)
# These are warnings (awarn), not errors — emitted during tree-building pass.
# awarn forces SIZE_ONLY context for the carp call, so we capture with __WARN__.
{
    my $rw = Regexp::Parser->new;
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $rw->regex('(?{code})+');
    eval { $rw->visual };
    ok(@w > 0, 'RPe_ZQUANT warning on quantified code block (?{code})+');
}
{
    my $rw = Regexp::Parser->new;
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $rw->regex('(?=a)*');
    eval { $rw->visual };
    ok(@w > 0, 'RPe_NULNUL warning on unbounded zero-width (?=a)*');
}

# {n} without quantifiable target parses differently — { is literal if not {n,m}
parses_ok('{}', 'bare {} is literal text');
parses_ok('{abc}', '{abc} is literal text');

##
## 3. ESCAPE SEQUENCE ERRORS — RPe_ESLASH, RPe_BRACES, RPe_RBRACE, RPe_EMPTYB
##

# Trailing backslash
fails_regex('abc\\',     ($r->RPe_ESLASH)[0],   'trailing backslash');
fails_regex('\\',        ($r->RPe_ESLASH)[0],   'lone backslash');

# Missing braces on \g, \N
fails_regex('\\g',       ($r->RPe_BRACES)[0],   '\\g without braces');
fails_regex('\\N',       ($r->RPe_BRACES)[0],   '\\N without braces');

# Missing right brace
fails_regex('\\x{abc',   ($r->RPe_RBRACE)[0],   '\\x{... missing right brace');
fails_regex('\\o{777',   ($r->RPe_RBRACE)[0],   '\\o{... missing right brace');
fails_regex('\\N{SPACE',  ($r->RPe_RBRACE)[0],  '\\N{... missing right brace');
fails_regex('\\g{1',     ($r->RPe_RBRACE)[0],   '\\g{... missing right brace');

# Empty \p / \P (end of string — nothing after the escape)
fails_regex('\\p',       ($r->RPe_EMPTYB)[0],   '\\p at end of string');
fails_regex('\\P',       ($r->RPe_EMPTYB)[0],   '\\P at end of string');

##
## 4. BACKREFERENCE ERRORS — RPe_BGROUP
##

# Reference to nonexistent group — deferred to visual pass
fails_visual('\\1',       ($r->RPe_BGROUP)[0],  '\\1 with no capture groups');
fails_visual('(a)\\2',   ($r->RPe_BGROUP)[0],   '\\2 with only 1 capture group');
fails_visual('\\g{5}',   ($r->RPe_BGROUP)[0],   '\\g{5} with no capture groups');
fails_visual('\\g{-1}',  ($r->RPe_BGROUP)[0],   '\\g{-1} (relative) with no groups');

# Valid backrefs should work
parses_ok('(a)\\1', 'valid backref \\1 with 1 group');
parses_ok('(a)(b)\\2', 'valid backref \\2 with 2 groups');

##
## 5. SEQUENCE ERRORS — RPe_SEQINC, RPe_NOTREC, RPe_NOTERM, RPe_NOTBAL
##

# Sequence (? incomplete
fails_regex('(?',         ($r->RPe_SEQINC)[0],  '(? at end of string');

# Sequence not recognized
fails_regex('(?z)',       ($r->RPe_NOTREC)[0],  '(?z) unrecognized');
fails_regex('(?Q)',       ($r->RPe_NOTREC)[0],  '(?Q) unrecognized');

# Comment not terminated
fails_regex('(?#comment', ($r->RPe_NOTERM)[0],  '(?#... not terminated');
fails_regex('(?#',        ($r->RPe_NOTERM)[0],  '(?# empty unterminated');

# Code block not balanced
fails_regex('(?{code',    ($r->RPe_NOTBAL)[0],  '(?{... not balanced');
fails_regex('(?{{{}',     ($r->RPe_NOTBAL)[0],  '(?{{{} deeply unbalanced');

# Valid sequences should parse
parses_ok('(?:abc)', 'non-capturing group');
parses_ok('(?#comment)', 'terminated comment');

##
## 6. CONDITIONAL ERRORS — RPe_SWNREC, RPe_SWBRAN, RPe_SWUNKN
##

# Switch condition not recognized (digit followed by non-paren)
# (?(1 — the digit match but no closing paren)
fails_regex('(?(1x)a|b)', ($r->RPe_SWNREC)[0], 'conditional group number not closed');

# Too many branches in conditional
fails_regex('(?(1)a|b|c)', ($r->RPe_SWBRAN)[0], 'conditional with 3 branches');

# Unknown switch condition
fails_regex('(?(?:bad)c|d)',  ($r->RPe_SEQINC)[0],  'conditional with non-capturing group');
fails_regex('(?(?i)c|d)',     ($r->RPe_SEQINC)[0],  'conditional with flag group');
fails_regex('(?(?#bad)c|d)',  ($r->RPe_SEQINC)[0],  'conditional with comment');
fails_regex('(?(>bad)c|d)',   ($r->RPe_SWUNKN)[0],  'conditional with > (not a valid condition)');

# Bad conditionals — these go through the ifthen(? handler
# which checks for valid assertion prefixes and falls through to RPe_SEQINC
fails_regex('(?(??{bad})c|d)',  ($r->RPe_SEQINC)[0], 'conditional with embedded ??{...}');
fails_regex('(?(?p{bad})c|d)',  ($r->RPe_SEQINC)[0], 'conditional with deprecated (?p)');
fails_regex('(?(?>bad)c|d)',    ($r->RPe_SEQINC)[0], 'conditional with atomic group');

# These go through the ifthen( handler which rejects non-assertion conditions
fails_regex('(?()c|d)',         ($r->RPe_SWUNKN)[0],  'conditional with empty condition');
fails_regex('(?(BAD)c|d)',      ($r->RPe_SWUNKN)[0],  'conditional with alpha name (no <name>)');
fails_regex('(?(1BAD)c|d)',     ($r->RPe_SWNREC)[0],  'conditional with digit+alpha');

# Valid conditionals
parses_ok('(a)(?(1)b|c)', 'valid conditional on group 1');
parses_ok('(?(?=a)b|c)',  'valid conditional with lookahead');
parses_ok('(?(?!a)b|c)',  'valid conditional with neg lookahead');
parses_ok('(?(?<=a)b|c)', 'valid conditional with lookbehind');
parses_ok('(?(?<!a)b|c)', 'valid conditional with neg lookbehind');

##
## 7. CHARACTER CLASS ERRORS — RPe_BADPOS, RPe_IRANGE, RPe_FRANGE
##

# Unknown POSIX class
fails_regex('[[:foo:]]',  ($r->RPe_BADPOS)[0],  'unknown POSIX class [:foo:]');
fails_regex('[[:bar:]]',  ($r->RPe_BADPOS)[0],  'unknown POSIX class [:bar:]');

# Invalid range (reversed endpoints)
fails_regex('[z-a]',      ($r->RPe_IRANGE)[0],  'invalid range z-a (reversed)');
fails_regex('[9-0]',      ($r->RPe_IRANGE)[0],  'invalid range 9-0 (reversed)');

# Valid POSIX classes
parses_ok('[[:alpha:]]',  'valid POSIX [:alpha:]');
parses_ok('[[:digit:]]',  'valid POSIX [:digit:]');
parses_ok('[[:^alpha:]]', 'valid POSIX negated [:^alpha:]');

##
## 8. DEPRECATED CONSTRUCT WARNINGS — RPe_LOGDEP
##

warns_regex('(?p{code})', '(?p{}) deprecated warning');

##
## 9. BAD FLAG WARNINGS — RPe_BADFLG
##

warns_regex('(?g)',  'useless (?g) flag warning');
warns_regex('(?c)',  'useless (?c) flag warning');
warns_regex('(?o)',  'useless (?o) flag warning');

# Negative flag forms too
warns_regex('(?-g)', 'useless (?-g) flag warning');

##
## 10. BAD ESCAPE IN CHARACTER CLASS WARNINGS — RPe_BADESC
##

warns_regex('[\\A]',  '\\A in character class warning');
warns_regex('[\\B]',  '\\B in character class warning');
warns_regex('[\\C]',  '\\C in character class warning');
warns_regex('[\\G]',  '\\G in character class warning');
warns_regex('[\\Z]',  '\\Z in character class warning');
warns_regex('[\\z]',  '\\z in character class warning');
warns_regex('[\\X]',  '\\X in character class warning');
warns_regex('[\\K]',  '\\K in character class warning');
warns_regex('[\\R]',  '\\R in character class warning');

# Outside char class, these should NOT warn (they're valid)
parses_ok('\\A',    '\\A outside char class is valid');
parses_ok('\\Z',    '\\Z outside char class is valid');
parses_ok('\\b',    '\\b outside char class is valid');
parses_ok('\\K',    '\\K outside char class is valid');
parses_ok('\\R',    '\\R outside char class is valid');

##
## 11. POSIX OUTSIDE CHARACTER CLASS WARNING — RPe_OUTPOS
##

warns_regex('[:alpha:]',  'POSIX [:alpha:] outside character class');
warns_regex('[:digit:]',  'POSIX [:digit:] outside character class');

##
## 12. FALSE RANGE WARNING — RPe_FRANGE
##

warns_regex('[\\w-x]',   'false range \\w-x (class shorthand as range start)');
warns_regex('[\\d-z]',   'false range \\d-z (class shorthand as range start)');

##
## 13. UNKNOWN ESCAPE WARNING — RPe_BADESC (outside char class)
##

warns_regex('\\y',        'unknown escape \\y');
warns_regex('\\j',        'unknown escape \\j');
warns_regex('\\m',        'unknown escape \\m');

##
## 14. ERROR INTROSPECTION API
##

{
    my $r = Regexp::Parser->new;
    eval { $r->regex('(abc') };
    ok($r->errnum,   'errnum is set after error');
    ok($r->errmsg,   'errmsg is set after error');
    like($r->errmsg, qr/Unmatched/, 'errmsg contains error text');
    ok($r->error_is(($r->RPe_LPAREN)[0]), 'error_is() matches RPe_LPAREN');
    ok(!$r->error_is(($r->RPe_RPAREN)[0]), 'error_is() does not match wrong code');
}

##
## 15. VALID EDGE CASES — ensure no false positives
##

parses_ok('a{3,5}',      'valid quantifier {3,5}');
parses_ok('a{0,}',       'valid quantifier {0,} (unbounded)');
parses_ok('a{3}',        'valid quantifier {3} (exact)');
parses_ok('\\x{41}',     'valid hex escape \\x{41}');
parses_ok('\\o{101}',    'valid octal escape \\o{101}');
parses_ok('\\N{SPACE}',  'valid named char \\N{SPACE}');
parses_ok('\\p{Alpha}',  'valid Unicode property \\p{Alpha}');
parses_ok('\\P{Digit}',  'valid negated property \\P{Digit}');
parses_ok('(?=a)',        'valid positive lookahead');
parses_ok('(?!a)',        'valid negative lookahead');
parses_ok('(?<=a)',       'valid positive lookbehind');
parses_ok('(?<!a)',       'valid negative lookbehind');
parses_ok('(?>abc)',      'valid atomic group');
parses_ok('(?:abc)',      'valid non-capturing group');
parses_ok('(?{1+1})',    'valid code block');
parses_ok('(??{1+1})',   'valid logical code block');
parses_ok('a(?:b|c)d',   'valid alternation in group');

done_testing;
