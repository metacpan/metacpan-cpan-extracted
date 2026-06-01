######################################################################
#
# 0008-new-features.t  Tests for features added in revised OrDie
#
# Covers:
#   - use constant { HASH } detection (Perl 5.8)
#   - typeglob slot *name{SLOT} detection (Perl 5.6)
#   - sprintf/printf %v format detection (Perl 5.6)
#   - say method-call false positive fix
#   - isa( call false positive fix
#   - any/all List::Util import suppression
#   - %hash{LIST} slice context fix (reduced false positives)
#   - REGEX_BLACKLIST line numbers now reported
#   - check_source() returns violation list (API change)
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

# helper: returns 1 if check_source finds violations, 0 if clean
sub violates {
    my ($src) = @_;
    my @v = Perl500503Syntax::OrDie::_check_source($src, 'test');
    return @v ? 1 : 0;
}

# helper: return violation messages for a source string
sub violations {
    my ($src) = @_;
    return Perl500503Syntax::OrDie::_check_source($src, 'test');
}

use vars qw(@tests);
@tests = (

    # ==============================================================
    # use constant { HASH }  (Perl 5.8)
    # ==============================================================
    ['use constant {}: detected',
        sub { violates("use constant { A => 1, B => 2 };\n") }],

    ['use constant {}: in comment - ignored',
        sub { !violates("# use constant { A => 1 }\n") }],

    ['use constant NAME => VALUE: not detected (5.004 form)',
        sub { !violates("use constant PI => 3.14159;\n") }],

    ['use constant {}: in string - ignored',
        sub { !violates("my \$s = 'use constant { A => 1 }';\n") }],

    # ==============================================================
    # typeglob slot  *name{IO}  (Perl 5.6)
    # ==============================================================
    ['typeglob slot *FH{IO}: detected',
        sub { violates("my \$io = *FH{IO};\n") }],

    ['typeglob slot *foo{SCALAR}: detected',
        sub { violates("my \$r = *foo{SCALAR};\n") }],

    ['typeglob slot *foo{CODE}: detected',
        sub { violates("my \$r = *foo{CODE};\n") }],

    ['typeglob slot: in comment - ignored',
        sub { !violates("# *FH{IO}\n") }],

    ['typeglob slot: in string - ignored',
        sub { !violates("my \$s = '*FH{IO}';\n") }],

    ['typeglob assign (not slot): not detected',
        sub { !violates("*foo = *bar;\n") }],

    # ==============================================================
    # sprintf/printf %v -- string contents are NOT checked
    # A string literal "%vd" is valid Perl 5.005_03 syntax.
    # ==============================================================
    ['spf %v in string literal - NOT a violation',
        sub { !violates("my \$s = sprintf(\"%vd\", \$v);\n") }],

    ['pf %v in string literal - NOT a violation',
        sub { !violates("printf(\"%vd\", \$v);\n") }],

    ['spf %v in comment - not detected',
        sub { !violates("# sprintf(\"%vd\", \$v)\n") }],

    # ==============================================================
    # say false positive fixes
    # ==============================================================
    ['say: method call ->say() - not detected',
        sub { !violates("\$obj->say(\"hello\");\n") }],

    ['say: hash key say => - not detected',
        sub { my $kw = 'sa' . 'y'; my $t = 'my %h = (' . $kw . ' => 1);' . "\n"; !violates($t) }],

    ['say: real say usage - detected',
        sub { my $kw = 'sa' . 'y'; my $t = "${kw} \"hello\";\n"; violates($t) }],

    ['say: say LIST - detected',
        sub { my $kw = 'sa' . 'y'; my $t = "${kw} STDOUT \"hello\";\n"; violates($t) }],

    # ==============================================================
    # isa false positive fixes
    # ==============================================================
    ['isa: ->isa() method call - not detected',
        sub { !violates("\$obj->isa('Foo');\n") }],

    ['isa: UNIVERSAL::isa() - not detected',
        sub { !violates("UNIVERSAL::isa(\$obj, 'Foo');\n") }],

    ['isa: isa( sub call form - not detected',
        sub { !violates("isa(\$obj, 'Foo');\n") }],

    ['isa: infix operator - detected',
        sub { violates("\$obj isa Foo;\n") }],

    # ==============================================================
    # any/all: List::Util import suppression
    # ==============================================================
    ['any{}: without List::Util import - detected',
        sub { violates("my \$r = any { \$_ > 0 } \@list;\n") }],

    ['any{}: with List::Util any import - not detected',
        sub {
            my $src = "use List::Util qw(any);\n"
                    . "my \$r = any { \$_ > 0 } \@list;\n";
            !violates($src);
        }],

    ['all{}: with List::Util all import - not detected',
        sub {
            my $src = "use List::Util qw(all);\n"
                    . "my \$ok = all { \$_ > 0 } \@list;\n";
            !violates($src);
        }],

    ['all{}: without List::Util import - detected',
        sub { violates("my \$r = all { \$_ > 0 } \@list;\n") }],

    ['any{}: List::Util imported but different function - detected',
        sub {
            my $src = "use List::Util qw(sum);\n"
                    . "my \$r = any { \$_ > 0 } \@list;\n";
            violates($src);
        }],

    # ==============================================================
    # %hash{LIST} slice: context-aware (reduced false positives)
    # ==============================================================
    ['%hash{LIST}: in rvalue context - detected',
        sub { violates("my \@kv = (%h{\@keys});\n") }],

    ['%hash plain assignment: not detected',
        sub { !violates("my \%h = (a => 1);\n") }],

    ['%ENV scalar access: not detected',
        sub { !violates("my \$p = \$ENV{PATH};\n") }],

    # ==============================================================
    # REGEX_BLACKLIST: line numbers now reported
    # ==============================================================
    ['regex blacklist: line number reported for \\K in regex',
        sub {
            my $src = "use strict;\n"
                    . "my \$x = 1;\n"
                    . "\$str =~ s/foo\\Kbar/baz/;\n";
            my @v = violations($src);
            @v && $v[0] =~ /line 3/;
        }],

    ['regex blacklist: line number reported for named capture',
        sub {
            my $src = "my \$x = 1;\n"
                    . "my \$y = 2;\n"
                    . "my \$z = 3;\n"
                    . "\$s =~ m/(?<name>\\w+)/;\n";
            my @v = violations($src);
            @v && $v[0] =~ /line 4/;
        }],

    # ==============================================================
    # check_source() public API returns list
    # ==============================================================
    ['api: check_source returns empty list on clean code',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "use strict;\nmy \$x = 1;\n", 't');
            !@v;
        }],

    ['api: check_source returns violations list (not die)',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "our \$x = 1;\n", 't');
            @v && $v[0] =~ /VIOLATION/;
        }],

    ['api: check_source multiple violations returns multiple entries',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "our \$x;\nour \$y;\n", 't');
            scalar(@v) >= 2;
        }],

    # ==============================================================
    # any/all: subroutine definition is NOT the keyword operator
    # (false-positive fix)
    # ==============================================================
    ['sub any {}: definition - not detected',
        sub { !violates("sub any {\n    return 1;\n}\n") }],

    ['sub all {}: definition - not detected',
        sub { !violates("sub all {\n    return 1;\n}\n") }],

    ['sub any {}: extra spaces - not detected',
        sub { !violates("sub   any   {\n    return 1;\n}\n") }],

    ['method ->any {}: not detected',
        sub { !violates("\$obj->any {\n    return 1;\n};\n") }],

    ['any { } operator still detected after sub on same line',
        sub { violates("sub f { return any { \$_ } \@x }\n") }],

    # ==============================================================
    # 3-argument open(): paren-aware top-level comma count
    # (false-positive fix for a nested function-call comma)
    # ==============================================================
    ['open 2-arg with nested catfile comma: not detected',
        sub { !violates(
            "open(FH, '>' . File::Spec->catfile(\$dir, \$file));\n") }],

    ['open 2-arg with nested join comma: not detected',
        sub { !violates("open(FH, join(',', \@parts));\n") }],

    ['open 3-arg still detected (literal mode)',
        sub { violates("open(FH, \">\", \$file);\n") }],

    ['open 3-arg still detected (variable mode)',
        sub { violates("open(FH, \$mode, \$file);\n") }],

    # ==============================================================
    # Here-document body masking (false-positive fix)
    # Bodies are data, not code; example text inside them must not be
    # flagged.  Two heredocs may also share a single line.
    # ==============================================================
    ['heredoc body: our-decl inside body not detected',
        sub { !violates("\$x = <<'E';\nour \$z = 1;\nE\n") }],

    ['heredoc body: signature inside body not detected',
        sub { !violates("\$x = <<'E';\nsub max (\$m, \$n) {}\nE\n") }],

    ['heredoc body: <<>> inside body not detected',
        sub { !violates("\$x = <<'E';\n<<>>\nE\n") }],

    ['heredoc: real say keyword after heredoc on same line - detected',
        sub { violates("\$x = <<\"E\"; " . "sa" . "y \$y;\nbody\nE\n") }],

    ['heredoc: two heredocs sharing a line, real defined-or after - detected',
        sub { violates(
            "\$a = <<\"A\"; \$b = <<\"B\"; my \$z = \$p "
          . join('', '/', '/') . " \$q;\nAAA\nA\nBBB\nB\n") }],

    ['heredoc: two heredocs sharing a line, bodies are data',
        sub { !violates(
            "\$a = <<'A'; \$b = <<'B';\nour \$x;\nA\nstate \$y;\nB\n") }],

    # ==============================================================
    # Typeglob / sub-sigil / package-separator before quote-like word
    # (false-positive fix)
    # ==============================================================
    ['typeglob *s not read as s/// operator',
        sub { !violates("local (*s, \$n) = \@_;\n") }],

    ['package-qualified mb::tr not read as tr/// operator',
        sub { !violates("my \$r = mb::tr(\$x, 'A', '1');\n") }],

    ['real s/// after assignment still detected via flag',
        sub { violates("my \$r = \$s =~ s/a/b/r;\n") }],

    # ==============================================================
    # Old-style apostrophe package separator (false-positive fix)
    # &jcode'tr(...) is &jcode::tr(...); the line must not desync.
    # ==============================================================
    ['apostrophe package separator: trailing our still detected (no desync)',
        sub { violates("&jcode'tr(*val, 'A', '1');\nour \$leak = 1;\n") }],

    ['apostrophe package separator: clean call not flagged',
        sub { !violates("&jcode'tr(*val, 'A', '1');\n") }],

    # ==============================================================
    # Escaped backslash + regex-escape letter (false-positive fix)
    # The literal two characters \\h are not the \h escape.
    # ==============================================================
    ['escaped backslash + h in regex not detected',
        sub { !violates("\$x =~ /a\\\\hb/;\n") }],

    ['real \\h escape in regex still detected',
        sub { violates("\$x =~ /a\\h/;\n") }],

    # ==============================================================
    # Postfix increment vs possessive quantifier (false-positive fix)
    # ==============================================================
    ['package-qualified postfix increment not detected',
        sub { !violates("\$mb::seq++;\n") }],

    ['real possessive quantifier in regex still detected',
        sub { violates("\$x =~ /a++/;\n") }],

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
