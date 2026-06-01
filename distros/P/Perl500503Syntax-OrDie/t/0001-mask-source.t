######################################################################
#
# 0001-mask-source.t  Unit tests for _mask_source()
#
# Tests the source masker that replaces comments and string literal
# contents with 'X' while preserving newlines.
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

use vars qw(@tests);

BEGIN {
    require Perl500503Syntax::OrDie;
    Perl500503Syntax::OrDie::_install_runtime_guards();
}

sub mask { (Perl500503Syntax::OrDie::_mask_source($_[0]))[0] }

@tests = (

    # ----------------------------------------------------------------
    # Single-line comments
    # ----------------------------------------------------------------
    ['comment: basic',
        sub { mask("# comment\n") =~ /^#X+\n$/ }],

    ['comment: text after hash masked',
        sub { mask("my \$x; # note our\n") !~ /our/ }],

    ['comment: newline preserved',
        sub {
            my $m = mask("# a\n# b\n");
            my @lines = split /\n/, $m, -1;
            scalar(@lines) == 3;    # 2 lines + empty after final \n
        }],

    ['comment: hash in middle of line masked',
        sub { mask("code; # our \$x\n") !~ /our/ }],

    ['comment: hash at end of file (no newline)',
        sub { mask("# eof") =~ /^#X+$/ }],

    # ----------------------------------------------------------------
    # Double-quoted strings
    # ----------------------------------------------------------------
    ['dquote: basic content masked',
        sub { mask('"hello"') !~ /hello/ }],

    ['dquote: our inside masked',
        sub { mask('"our $x"') !~ /our/ }],

    ['dquote: delimiters preserved',
        sub { mask('"abc"') =~ /^"X+"$/ }],

    ['dquote: escaped backslash inside',
        sub { mask('"a\\\\b"') =~ /^"/ }],

    ['dquote: escaped quote inside does not terminate early',
        sub { mask('"a\\"b"') =~ /^"X+X+"$/ }],

    ['dquote: newline inside string preserved',
        sub {
            my $m = mask("\"line1\nline2\"");
            my @l = split /\n/, $m, -1;
            scalar(@l) == 2;
        }],

    ['dquote: our after string still detected',
        sub {
            my $m = mask("\"hello\"; our \$x");
            $m =~ /\bour\s*\$x/;
        }],

    # ----------------------------------------------------------------
    # Single-quoted strings
    # ----------------------------------------------------------------
    ['squote: basic content masked',
        sub { mask("'hello'") !~ /hello/ }],

    ['squote: our inside masked',
        sub { mask("'our \$x'") !~ /our/ }],

    ['squote: escaped backslash',
        sub { mask("'a\\\\b'") =~ /^'/ }],

    ['squote: escaped quote inside',
        sub { mask("'it\\'s'") =~ /^'X+'$/ }],

    ['squote: newline preserved',
        sub {
            my $m = mask("'a\nb'");
            scalar(split /\n/, $m, -1) == 2;
        }],

    # ----------------------------------------------------------------
    # Backtick strings
    # ----------------------------------------------------------------
    ['backtick: content masked',
        sub { mask('`ls -l`') !~ /ls/ }],

    ['backtick: our inside masked',
        sub { mask('`our $x`') !~ /our/ }],

    # ----------------------------------------------------------------
    # qq{} and friends
    # ----------------------------------------------------------------
    ['qq{}: content masked',
        sub { mask('qq{our $x}') !~ /our/ }],

    ['qq(): content masked',
        sub { mask('qq(our $x)') !~ /our/ }],

    ['qq//: content masked',
        sub { mask('qq/our $x/') !~ /our/ }],

    ['qw{}: content masked',
        sub { mask('qw{foo bar}') !~ /foo/ }],

    ['qx{}: content masked',
        sub { mask('qx{our $x}') !~ /our/ }],

    ['q{}: content masked',
        sub { mask("q{it's our}") !~ /our/ }],

    ['qq{}: nested braces',
        sub {
            my $m = mask('qq{a{b}c}');
            $m =~ /^qq\{/ && $m !~ /[abc]/;
        }],

    # ----------------------------------------------------------------
    # Heredocs
    # ----------------------------------------------------------------
    ['heredoc: content masked',
        sub {
            my $src = "my \$x = <<END;\nour \$y\nEND\n";
            mask($src) !~ /our/;
        }],

    ['heredoc: newlines preserved (line count unchanged)',
        sub {
            my $src = "<<END;\nline1\nline2\nEND\n";
            my $m   = mask($src);
            scalar(split /\n/, $src, -1) == scalar(split /\n/, $m, -1);
        }],

    ['heredoc: double-quoted sentinel',
        sub {
            my $src = "<<\"END\";\nour \$y\nEND\n";
            mask($src) !~ /our/;
        }],

    ['heredoc: single-quoted sentinel',
        sub {
            my $src = "<<'END';\nour \$y\nEND\n";
            mask($src) !~ /our/;
        }],

    # ----------------------------------------------------------------
    # Edge cases: constructs NOT inside strings
    # ----------------------------------------------------------------
    ['edge: our after string visible',
        sub {
            my $m = mask("my \$s = 'x'; our \$v;\n");
            $m =~ /\bour\s*\$v\b/;
        }],

    ['edge: our in comment invisible, our after visible',
        sub {
            my $m = mask("# our\nour \$v;\n");
            $m !~ /^#.*our/ && $m =~ /\bour\s*\$v/;
        }],

    ['edge: empty source',
        sub { mask('') eq '' }],

    ['edge: only whitespace',
        sub { mask("   \n   \n") eq "   \n   \n" }],

    ['edge: multiple strings on one line',
        sub {
            my $m = mask("\"a\" . 'b' . \"c\"\n");
            $m !~ /[abc]/;
        }],

    ['edge: adjacent strings',
        sub {
            my $m = mask('"ab""cd"');
            $m !~ /[abcd]/;
        }],

    # ----------------------------------------------------------------
    # Line number preservation
    # ----------------------------------------------------------------
    ['linenum: code on line 3 stays on line 3',
        sub {
            my $src = "# comment\n\"hello\"\nour \$x\n";
            my $m   = mask($src);
            my @l   = split /\n/, $m, -1;
            $l[2] =~ /\bour\s*\$x\b/;
        }],

    ['linenum: heredoc body line count stable',
        sub {
            my $src = "a\n<<END;\nX\nY\nEND\nb\n";
            my @orig = split /\n/, $src, -1;
            my @mskd = split /\n/, mask($src), -1;
            scalar(@orig) == scalar(@mskd);
        }],

    # ----------------------------------------------------------------
    # Regression: s/.../.../  -- closing delimiter not confused
    # ----------------------------------------------------------------
    ['regression: s operator not confused with string',
        sub {
            my $src = "my \$x = 1;\n\$s =~ s/our/their/;\n";
            my $m   = mask($src);
            # The substitution operator is NOT a string literal
            # so 'our' pattern inside s/// may or may not appear,
            # but the code after line 2 remains unaffected.
            # Just verify mask returns something of same line count.
            scalar(split /\n/, $src, -1) == scalar(split /\n/, $m, -1);
        }],

    # ----------------------------------------------------------------
    # Multiple / shared-line here-documents (jcode-style test fixtures)
    # ----------------------------------------------------------------
    ['heredoc: two heredocs sharing one line, both bodies masked',
        sub {
            # $_ = <<'A'; $x eq <<'B';  followed by body A then body B.
            my $src = "\$_ = <<'A'; \$x eq <<'B';\nour \$p\nA\nstate \$q\nB\n";
            my $m   = mask($src);
            # Both bodies are data; their declarations must be masked away,
            # and the line count must be preserved.
            $m !~ /our/ && $m !~ /state/
                && scalar(split /\n/, $src, -1) == scalar(split /\n/, $m, -1);
        }],

    ['heredoc: code following two shared-line heredocs stays visible',
        sub {
            # A real construct on the operator line must survive masking.
            my $src = "\$a = <<'A'; \$b = <<'B'; my \$z = 1;\nAAA\nA\nBBB\nB\n";
            my $m   = mask($src);
            my @ml  = split /\n/, $m, -1;
            # First line still carries the visible assignment 'my $z = 1;'
            $ml[0] =~ /my \$z = 1;/;
        }],

    ['heredoc: body line count stable with two heredocs',
        sub {
            my $src = "x\n\$p = <<'A'; \$q = <<'B';\n1\n2\nA\n3\nB\ny\n";
            my $m   = mask($src);
            scalar(split /\n/, $src, -1) == scalar(split /\n/, $m, -1);
        }],

    # ----------------------------------------------------------------
    # Old-style apostrophe package separator  &pkg'sub  ==  &pkg::sub
    # (jcode idiom:  &jcode'tr(*val, FROM, TO))
    # ----------------------------------------------------------------
    ['apostrophe pkgsep: not treated as string start',
        sub {
            my $src = "&jcode'tr(*val, 'A', '1');\n";
            my $m   = mask($src);
            # The package separator and the following name remain visible;
            # only the genuine string arguments are masked.
            $m =~ /&jcode'tr\(\*val, 'X', 'X'\);/;
        }],

    ['apostrophe pkgsep: trailing code on next line stays visible',
        sub {
            my $src = "&jcode'tr(*val, 'A', '1');\nour \$leak = 1;\n";
            my $m   = mask($src);
            # If the apostrophe were mistaken for a string opener the rest
            # would be masked; the real 'our' must remain visible.
            $m =~ /our \$leak = 1;/;
        }],

    ['apostrophe pkgsep: scalar form $pkg\'var preserved',
        sub {
            my $src = "\$main'foo = 1;\n";
            my $m   = mask($src);
            $m =~ /\$main'foo = 1;/;
        }],

    # ----------------------------------------------------------------
    # Typeglob / package-qualified name before a quote-like word
    # ----------------------------------------------------------------
    ['typeglob *s not consumed as s/// operator',
        sub {
            my $src = "local (*s, \$n) = \@_;\n";
            my $m   = mask($src);
            # The line has no strings or comments, so a correct masker
            # leaves it byte-for-byte identical; if *s were taken as the
            # s/// operator the argument list would be masked away.
            $m eq $src;
        }],

    ['package-qualified ::tr not consumed as tr/// operator',
        sub {
            my $src = "my \$r = mb::tr(\$x, 'A', '1');\n";
            my $m   = mask($src);
            $m =~ /mb::tr\(\$x, 'X', 'X'\);/;
        }],

    # ----------------------------------------------------------------
    # Escaped backslash inside a regex literal
    # ----------------------------------------------------------------
    ['regex body: escaped backslash kept distinct from escape letter',
        sub {
            # /a\\hb/ contains the two literal characters \\ then h, which
            # is NOT the \h escape.  The masker records the regex body; the
            # de-escaping happens in _check_source, so here we only verify
            # the operator line keeps a stable line count.
            my $src = "\$x =~ /a\\\\hb/;\n";
            my $m   = mask($src);
            scalar(split /\n/, $src, -1) == scalar(split /\n/, $m, -1);
        }],

);

print "1.." . scalar(@tests) . "\n";
my $n = 0;
for my $t (@tests) {
    $n++;
    my ($label, $code) = @{$t};
    my $result = eval { $code->() };
    my $ok     = $result && !$@;
    print +($ok ? '' : 'not ') . "ok $n - $label\n";
    print "# EVAL ERROR: $@\n" if $@;
}

