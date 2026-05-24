######################################################################
#
# 0005-regex-checks.t  Tests for regex and additional construct checks
#
# Covers constructs that were missing from the blacklist and caused
# real implementation bugs, including the variable-length lookbehind
# that was accidentally used in this very module:
#
#   R1: Variable-length lookbehind (?<=..{n,m}) (?<!..{n,m})
#       -- introduced in Perl 5.38
#       Root cause of the "variable length lookbehind not implemented"
#       error observed on Perl < 5.38 (including all Windows Perls
#       prior to 5.38).
#
#   R2: \K (keep) in regex
#       -- introduced in Perl 5.10
#
#   R3: Named capture (?<name>...) and \k<name>
#       -- introduced in Perl 5.10
#
#   R4: Branch reset (?|...)
#       -- introduced in Perl 5.10
#
#   R5: (*VERB) backtrack control verbs
#       -- introduced in Perl 5.10
#
#   R6: \h \H \v \V \R regex escapes
#       -- introduced in Perl 5.10
#
#   R7: \p{} \P{} Unicode property escapes
#       -- introduced in Perl 5.6
#
#   R8: PerlIO layer (:utf8 :encoding etc) in open()/binmode()
#       -- introduced in Perl 5.8
#
#   R9: s///r tr///r non-destructive flag
#       -- introduced in Perl 5.14
#
#   R10: __SUB__ token
#       -- introduced in Perl 5.16
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

BEGIN {
    require Perl500503Syntax::OrDie;
    Perl500503Syntax::OrDie::_install_runtime_guards();
}

sub violates {
    my ($src) = @_;
    my @_v = Perl500503Syntax::OrDie::_check_source($src, 'test');
    return @_v ? 1 : 0;
}

use vars qw(@tests);
@tests = (

    # ==============================================================
    # R1: Variable-length lookbehind  (Perl 5.38)
    # This was the direct cause of the "variable length lookbehind
    # not implemented" error on Perl < 5.38.
    # The module itself mistakenly used (?<!\buse\s{0,20}) which
    # fails on every Perl before 5.38.
    # ==============================================================
    ['R1 varlookbehind: (?<=\\w{1,3}) - detected',
        sub { violates('if ($s =~ /(?<=\w{1,3})x/) {}' . "\n") }],

    ['R1 varlookbehind: (?<!\\s{0,20}) - detected',
        sub { violates('if ($s =~ /(?<!\s{0,20})x/) {}' . "\n") }],

    ['R1 varlookbehind: (?<=\\w+) - detected',
        sub { violates('if ($s =~ /(?<=\w+)x/) {}' . "\n") }],

    ['R1 varlookbehind: (?<=\\w*) - detected',
        sub { violates('if ($s =~ /(?<=\w*)x/) {}' . "\n") }],

    ['R1 varlookbehind: fixed (?<=foo) - not detected',
        sub { !violates('if ($s =~ /(?<=foo)x/) {}' . "\n") }],

    ['R1 varlookbehind: fixed (?<!bar) - not detected',
        sub { !violates('if ($s =~ /(?<!bar)x/) {}' . "\n") }],

    ['R1 varlookbehind: fixed (?<=\\w) - not detected',
        sub { !violates('if ($s =~ /(?<=\w)x/) {}' . "\n") }],

    ['R1 varlookbehind: in comment - ignored',
        sub { !violates('# if ($s =~ /(?<=\w{1,3})x/) {}' . "\n") }],

    # ==============================================================
    # R2: \K (keep) in regex  (Perl 5.10)
    # ==============================================================
    ['R2 \\K: in regex - detected',
        sub { violates('if ($s =~ /foo\Kbar/) {}' . "\n") }],

    ['R2 \\K: in s/// - detected',
        sub { violates('$s =~ s/foo\Kbar/baz/;' . "\n") }],

    ['R2 \\K: in comment - ignored',
        sub { !violates('# use \K to reset match start' . "\n") }],

    ['R2 \\K: in string - ignored',
        sub { !violates('my $s = "use \\K";' . "\n") }],

    ['R2 \\K: $K variable - not detected',
        sub { !violates('my $K = 1;' . "\n") }],

    # ==============================================================
    # R3: Named capture (?<name>...) and \k<name>  (Perl 5.10)
    # ==============================================================
    ['R3 named: (?<year>\\d+) - detected',
        sub { violates('if ($s =~ /(?<year>\d+)/) {}' . "\n") }],

    ['R3 named: qr/(?<word>\\w+)/ - detected',
        sub { violates('my $re = qr/(?<word>\w+)/;' . "\n") }],

    ['R3 named: \\k<name> backreference - detected',
        sub { violates('if ($s =~ /(?<x>\w)\k<x>/) {}' . "\n") }],

    ['R3 named: (?:non-capture) - not detected',
        sub { !violates('if ($s =~ /(?:foo)/) {}' . "\n") }],

    ['R3 named: (?=lookahead) - not detected',
        sub { !violates('if ($s =~ /(?=foo)/) {}' . "\n") }],

    ['R3 named: in comment - ignored',
        sub { !violates('# (?<year>\d+)' . "\n") }],

    # ==============================================================
    # R4: Branch reset group (?|...)  (Perl 5.10)
    # ==============================================================
    ['R4 breset: (?|(a)|(b)) - detected',
        sub { violates('if ($s =~ /(?|(a)|(b))/) {}' . "\n") }],

    ['R4 breset: (?:a|b) non-capturing - not detected',
        sub { !violates('if ($s =~ /(?:a|b)/) {}' . "\n") }],

    ['R4 breset: in comment - ignored',
        sub { !violates('# (?|(a)|(b))' . "\n") }],

    # ==============================================================
    # R5: (*VERB) backtrack control verbs  (Perl 5.10)
    # ==============================================================
    ['R5 verb: (*FAIL) - detected',
        sub { violates('if ($s =~ /(*FAIL)/) {}' . "\n") }],

    ['R5 verb: (*ACCEPT) - detected',
        sub { violates('if ($s =~ /(*ACCEPT)/) {}' . "\n") }],

    ['R5 verb: (*PRUNE) - detected',
        sub { violates('if ($s =~ /(*PRUNE)/) {}' . "\n") }],

    ['R5 verb: (*SKIP) - detected',
        sub { violates('if ($s =~ /(*SKIP)/) {}' . "\n") }],

    ['R5 verb: (*COMMIT) - detected',
        sub { violates('if ($s =~ /(*COMMIT)/) {}' . "\n") }],

    ['R5 verb: (*MARK:foo) - detected',
        sub { violates('if ($s =~ /(*MARK:foo)/) {}' . "\n") }],

    ['R5 verb: in comment - ignored',
        sub { !violates('# (*FAIL) control verb' . "\n") }],

    ['R5 verb: in string - ignored',
        sub { !violates('my $s = "(*FAIL)";' . "\n") }],

    # ==============================================================
    # R6: \h \H \v \V \R regex escapes  (Perl 5.10)
    # ==============================================================
    ['R6 \\h: horizontal whitespace - detected',
        sub { violates('if ($s =~ /\h/) {}' . "\n") }],

    ['R6 \\H: non-horizontal - detected',
        sub { violates('if ($s =~ /\H/) {}' . "\n") }],

    ['R6 \\v: vertical whitespace - detected',
        sub { violates('if ($s =~ /\v/) {}' . "\n") }],

    ['R6 \\V: non-vertical - detected',
        sub { violates('if ($s =~ /\V/) {}' . "\n") }],

    ['R6 \\R: generic newline - detected',
        sub { violates('if ($s =~ /\R/) {}' . "\n") }],

    ['R6 \\n: literal newline - not detected (Perl 5.004)',
        sub { !violates('if ($s =~ /\n/) {}' . "\n") }],

    ['R6 \\s: whitespace - not detected (Perl 5.004)',
        sub { !violates('if ($s =~ /\s/) {}' . "\n") }],

    ['R6 \\h: in comment - ignored',
        sub { !violates('# use \h for horizontal space' . "\n") }],

    # ==============================================================
    # R7: \p{} \P{} Unicode property escapes  (Perl 5.6)
    # ==============================================================
    ['R7 \\p{}: Alpha property - detected',
        sub { violates('if ($s =~ /\p{Alpha}/) {}' . "\n") }],

    ['R7 \\P{}: negated property - detected',
        sub { violates('if ($s =~ /\P{Space}/) {}' . "\n") }],

    ['R7 \\p{}: in comment - ignored',
        sub { !violates('# \p{Alpha} matches letters' . "\n") }],

    ['R7 \\p{}: in string - ignored',
        sub { !violates('my $s = "\\p{Alpha}";' . "\n") }],

    ['R7 $p{key}: hash access - not detected',
        sub { !violates('print $p{foo};' . "\n") }],

    # ==============================================================
    # R8: PerlIO layer -- string contents are not syntax; only 3-arg open is checked
    # ==============================================================
    ['R8 PerlIO: open with layer - detected as 3-arg open (Perl 5.6)',
        sub { violates('open(FH, ">:utf8", $f);' . "\n") }],

    ['R8 PerlIO: open with encoding - detected as 3-arg open (Perl 5.6)',
        sub { violates('open(FH, "<:encoding(UTF-8)", $f);' . "\n") }],

    ['R8 PerlIO: binmode with layer string - NOT a syntax violation',
        sub { !violates('binmode($fh, ":encoding(utf8)");' . "\n") }],

    ['R8 PerlIO: binmode utf8 string - NOT a syntax violation',
        sub { !violates('binmode(STDOUT, ":utf8");' . "\n") }],

    ['R8 PerlIO: open plain 2-arg - not detected',
        sub { !violates('open(FH, ">output.txt");' . "\n") }],

    ['R8 PerlIO: binmode no layer - not detected',
        sub { !violates('binmode(STDOUT);' . "\n") }],

    ['R8 PerlIO: in comment - ignored',
        sub { !violates('# open(FH, ">:utf8", $f)' . "\n") }],
    # ==============================================================
    # R9: s///r tr///r non-destructive flag  (Perl 5.14)
    # ==============================================================
    ['R9 /r: s///r - detected',
        sub { violates('my $new = $s =~ s/foo/bar/r;' . "\n") }],

    ['R9 /r: tr///r - detected',
        sub { violates('my $new = $s =~ tr/a-z/A-Z/r;' . "\n") }],

    ['R9 /r: s{}{} r - detected',
        sub { violates('$s =~ s{foo}{bar}r;' . "\n") }],

    ['R9 /r: s///g not detected',
        sub { !violates('$s =~ s/foo/bar/g;' . "\n") }],

    ['R9 /r: s/// no flag - not detected',
        sub { !violates('$s =~ s/foo/bar/;' . "\n") }],

    ['R9 /r: in comment - ignored',
        sub { !violates('# $new = $s =~ s/foo/bar/r' . "\n") }],

    # ==============================================================
    # R10: __SUB__  (Perl 5.16)
    # ==============================================================
    ['R10 __SUB__: in code - detected',
        sub { violates('my $self = __SUB__;' . "\n") }],

    ['R10 __SUB__: recursive call - detected',
        sub { violates('__SUB__->(@_);' . "\n") }],

    ['R10 __SUB__: in comment - ignored',
        sub { !violates('# use __SUB__ for anonymous recursion' . "\n") }],

    ['R10 __SUB__: in string - ignored',
        sub { !violates('my $s = "__SUB__";' . "\n") }],

    ['R10 __FILE__: not detected (Perl 5.004)',
        sub { !violates('print __FILE__;' . "\n") }],

    ['R10 __LINE__: not detected (Perl 5.004)',
        sub { !violates('print __LINE__;' . "\n") }],

    ['R10 __PACKAGE__: not detected (Perl 5.004)',
        sub { !violates('print __PACKAGE__;' . "\n") }],

    # ==============================================================
    # Clean code: verify that common Perl 5.005_03 regex features pass
    # ==============================================================
    ['clean: (?:non-capture) ok',
        sub { !violates('if ($s =~ /(?:foo)/) {}' . "\n") }],

    ['clean: (?=lookahead) ok',
        sub { !violates('if ($s =~ /(?=foo)/) {}' . "\n") }],

    ['clean: (?!negative lookahead) ok',
        sub { !violates('if ($s =~ /(?!foo)/) {}' . "\n") }],

    ['clean: (?<=fixed lookbehind) ok',
        sub { !violates('if ($s =~ /(?<=foo)x/) {}' . "\n") }],

    ['clean: (?<!fixed neg lookbehind) ok',
        sub { !violates('if ($s =~ /(?<!foo)x/) {}' . "\n") }],

    ['clean: \\w \\d \\s ok',
        sub { !violates('if ($s =~ /\w\d\s/) {}' . "\n") }],

    ['clean: [character class] ok',
        sub { !violates('if ($s =~ /[a-z]/) {}' . "\n") }],

    ['clean: plain open 2-arg ok',
        sub { !violates('open(FH, ">file.txt") or die;' . "\n") }],

);

print "1.." . scalar(@tests) . "\n";
my $n = 0;
for my $t (@tests) {
    $n++;
    my ($label, $code) = @{$t};
    my $result = eval { $code->() };
    my $ok     = $result && !$@;
    print +($ok ? '' : 'not ') . "ok $n - $label\n";
    print "# EVAL ERROR: $@\n" if $@ && $@ !~ /VIOLATION/;
}
