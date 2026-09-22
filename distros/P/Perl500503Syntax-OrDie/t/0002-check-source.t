######################################################################
#
# 0002-check-source.t  Static violation detection tests
#
# Verifies that _check_source() correctly detects (or passes) each
# of the constructs in the blacklist, including edge cases such as:
#   - construct inside a comment       (must NOT be detected)
#   - construct inside a string        (must NOT be detected)
#   - construct in real code           (MUST be detected)
#   - similar but valid construct      (must NOT be detected)
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

# helper: returns 1 if check_source returns violations, 0 if clean
sub violates {
    my ($src) = @_;
    my @_v = Perl500503Syntax::OrDie::_check_source($src, 'test');
    return @_v ? 1 : 0;
}

use vars qw(@tests);
@tests = (

    # ==============================================================
    # our $x  (Perl 5.6)
    # ==============================================================
    ['our: real code - detected',
        sub { violates("our \$x = 1;\n") }],

    ['our: in comment - ignored',
        sub { !violates("# our \$x\nmy \$y;\n") }],

    ['our: in double-quoted string - ignored',
        sub { !violates("my \$s = \"our \$x\";\n") }],

    ['our: in single-quoted string - ignored',
        sub { !violates("my \$s = 'our \$x';\n") }],

    ['our: array - detected',
        sub { violates("our \@arr;\n") }],

    ['our: hash - detected',
        sub { violates("our \%h;\n") }],

    ['our: similar word "oured" - not detected',
        sub { !violates("my \$poured = 1;\n") }],

    ['our: "your" - not detected',
        sub { !violates("my \$your = 1;\n") }],

    # ==============================================================
    # 3-argument open  (Perl 5.6)
    # ==============================================================
    ['open3: basic - detected',
        sub { violates("open(FH, \">\", \$f);\n") }],

    ['open3: with variable mode - detected',
        sub { violates("open(FH, \$mode, \$file);\n") }],

    ['open3: 2-argument form - not detected',
        sub { !violates("open(FH, \">file\");\n") }],

    ['open3: in comment - ignored',
        sub { !violates("# open(FH, \">\", \$f)\n") }],

    ['open3: open without parens - not flagged by pattern',
        sub { !violates("open FH, \">\$f\";\n") }],

    # ==============================================================
    # defined-or-assign operator  (Perl 5.10)
    # ==============================================================
    ['defor-assign: real code - detected',
        sub { my $s = '$x ' . '/' . '/= 1;' . "\n"; violates($s) }],

    ['defor-assign: in comment - ignored',
        sub { my $s = "# \$x " . join("","/"  ,"/") . "= 1\n"; !violates($s) }],

    ['defor-assign: in string - ignored',
        sub { my $s = 'my $s = ' . "'" . join('','/','/') . "= example'" . ";\n"; !violates($s) }],

    # ==============================================================
    # say  (Perl 5.10)
    # ==============================================================
    ['say: real code - detected',
        sub { violates("say \"hello\";\n") }],

    ['say: in comment - ignored',
        sub { !violates("# say hello\n") }],

    ['say: in string - ignored',
        sub { !violates("my \$s = 'say hello';\n") }],

    ['say: substring "essay" - not detected',
        sub { !violates("my \$s = essay();\n") }],

    ['say: substring "okay" - not detected',
        sub { !violates("my \$s = okay();\n") }],

    # ==============================================================
    # state  (Perl 5.10)
    # ==============================================================
    ['state: scalar - detected',
        sub { violates("state \$n = 0;\n") }],

    ['state: array - detected',
        sub { violates("state \@arr;\n") }],

    ['state: in comment - ignored',
        sub { !violates("# state \$n\n") }],

    ['state: word "stateful" - not detected',
        sub { !violates("my \$stateful = 1;\n") }],

    # ==============================================================
    # given / when  (Perl 5.10)
    # ==============================================================
    ['given: real code - detected',
        sub { violates("given (\$x) { }\n") }],

    ['when: real code - detected',
        sub { violates("when (\$x) { }\n") }],

    ['given: in comment - ignored',
        sub { !violates("# given(\$x)\n") }],

    ['given: substring "forgiven" - not detected',
        sub { !violates("my \$s = forgiven();\n") }],

    # ==============================================================
    # smart-match ~~  (Perl 5.10)
    # ==============================================================
    ['~~: real code - detected',
        sub { violates("if (\$a ~~ \$b) { }\n") }],

    ['~~: in comment - ignored',
        sub { !violates("# a ~~ b\n") }],

    ['~~: in string - ignored',
        sub { !violates("my \$s = 'a ~~ b';\n") }],

    # ==============================================================
    # use feature  (Perl 5.10)
    # ==============================================================
    ['use feature: detected',
        sub { violates("use feature qw(say);\n") }],

    ['use feature: in comment - ignored',
        sub { !violates("# use feature\n") }],

    ['use feature (): empty-import no-op - ignored',
        sub { !violates("use feature ();\n") }],

    ['use feature ( ): empty-import with space - ignored',
        sub { !violates("use feature (  );\n") }],

    ['use feature with import still detected',
        sub { violates("use feature ':5.10';\n") }],

    # ==============================================================
    # lexical filehandle / directory handle  (Perl 5.6)
    #
    # Only the  my  spelling is checked.  open($fh, ...) against a
    # lexical that already holds a glob is valid 5.005_03 and must not
    # be reported.
    # ==============================================================
    ['lexfh: open(my $fh, ...) - detected',
        sub { violates("open(my \$fh, '<f.txt') or die;\n") }],

    ['lexfh: open my $fh without parens - detected',
        sub { violates("open my \$fh, '<f.txt' or die;\n") }],

    ['lexfh: opendir(my $dh, ...) - detected',
        sub { violates("opendir(my \$dh, '.') or die;\n") }],

    ['lexfh: sysopen(my $fh, ...) - detected',
        sub { violates("sysopen(my \$fh, 'f', 0) or die;\n") }],

    ['lexfh: pipe(my $r, my $w) - detected',
        sub { violates("pipe(my \$r, my \$w) or die;\n") }],

    ['lexfh: bareword open - ignored',
        sub { !violates("open(FH, '<f.txt') or die;\n") }],

    ['lexfh: glob open - ignored',
        sub { !violates("local *FH;\nopen(*FH, '<f.txt') or die;\n") }],

    ['lexfh: open against an existing lexical - ignored',
        sub { !violates("local *FH;\nmy \$fh = *FH;\nopen(\$fh, '<f.txt');\n") }],

    ['lexfh: in a comment - ignored',
        sub { !violates("# open(my \$fh, '<f.txt')\nmy \$x = 1;\n") }],

    # ==============================================================
    # binmode() with a LAYER argument  (Perl 5.6)
    #
    # A question of arity, not of what the layer string says: 5.005_03
    # binmode takes the filehandle alone.
    # ==============================================================
    ['binmode: two arguments - detected',
        sub { violates("binmode(\$fh, ':raw');\n") }],

    ['binmode: two arguments without parens - detected',
        sub { violates("binmode FH, ':utf8';\n") }],

    ['binmode: one argument - ignored',
        sub { !violates("binmode(FH);\n") }],

    ['binmode: one argument without parens - ignored',
        sub { !violates("binmode FH;\n") }],

    ['binmode: one glob-deref argument - ignored',
        sub { !violates("{ no strict 'refs'; binmode(*{\$fhn}) }\n") }],

    ['binmode: comma in a later statement on the same line - ignored',
        sub { !violates("binmode(FH); my (\$a, \$b) = (1, 2);\n") }],

    ['binmode: in a comment - ignored',
        sub { !violates("# binmode(\$fh, ':raw')\nmy \$x = 1;\n") }],

    # ==============================================================
    # use warnings / no warnings without the stub  (Perl 5.6)
    #
    # The guarded idiom is the tolerated form; the bare statement is
    # not.  The guard is recognised only where it is live code, so the
    # idiom quoted in prose does not excuse an unguarded statement.
    # ==============================================================
    ['warnings: bare use warnings - detected',
        sub { violates("use warnings;\n") }],

    ['warnings: bare no warnings - detected',
        sub { violates("no warnings;\n") }],

    ['warnings: short stub then use warnings - ignored',
        sub { !violates(
            "BEGIN { \$INC{'warnings.pm'} = '' if \$] < 5.006 }\n"
          . "use warnings; local \$^W = 1;\n") }],

    ['warnings: full stub then use warnings - ignored',
        sub { !violates(
            "BEGIN { if (\$] < 5.006 && !defined(&warnings::import)) {\n"
          . "        \$INC{'warnings.pm'} = 'stub';"
          . " eval 'package warnings; sub import {}' } }\n"
          . "use warnings; local \$^W = 1;\n") }],

    ['warnings: stub and use warnings on one line - ignored',
        sub { !violates(
            "BEGIN { \$INC{'warnings.pm'} = '' if \$] < 5.006 };"
          . " use warnings; \$^W = 1;\n") }],

    ['warnings: stub after the use - detected',
        sub { violates(
            "use warnings;\n"
          . "BEGIN { \$INC{'warnings.pm'} = '' if \$] < 5.006 }\n") }],

    ['warnings: stub only in a comment - detected',
        sub { violates(
            "# BEGIN { \$INC{'warnings.pm'} = '' if \$] < 5.006 }\n"
          . "use warnings;\n") }],

    ['warnings: guarded stub, no warnings later - ignored',
        sub { !violates(
            "BEGIN { \$INC{'warnings.pm'} = '' if \$] < 5.006 }\n"
          . "use warnings;\n"
          . "sub f { no warnings; 1 }\n") }],

    ['warnings: use strict alone - ignored',
        sub { !violates("use strict;\n") }],

    # ==============================================================
    # use utf8  (Perl 5.6)
    # ==============================================================
    ['use utf8: detected',
        sub { violates("use utf8;\n") }],

    ['use utf8: in comment - ignored',
        sub { !violates("# use utf8\n") }],

    ['use utf8: in string - ignored',
        sub { !violates("my \$s = 'use utf8';\n") }],

    # ==============================================================
    # package NAME VERSION  (Perl 5.12)
    # ==============================================================
    ['pkg+ver: detected',
        sub { violates("package Foo 1.00;\n") }],

    ['pkg+ver: v-string detected',
        sub { violates("package Foo v1.2.3;\n") }],

    ['pkg+ver: plain package ok',
        sub { !violates("package Foo;\n") }],

    # ==============================================================
    # use VERSION >= 5.6
    # ==============================================================
    ['use 5.6: detected',
        sub { violates("use 5.006;\n") }],

    ['use 5.8: detected',
        sub { violates("use 5.008;\n") }],

    ['use 5.10: detected (5.010 form)',
        sub { violates("use 5.010;\n") }],

    ['use v5.6: detected',
        sub { violates("use v5.6;\n") }],

    ['use v5.10: detected',
        sub { violates("use v5.10;\n") }],

    ['use 5.005: not detected',
        sub { !violates("use 5.005;\n") }],

    ['use 5.004: not detected',
        sub { !violates("use 5.004;\n") }],

    # ==============================================================
    # \x{HHHH}  (Perl 5.6)
    # The escape is detected in a regex (stage 3) and in an
    # interpolating string literal (stage 4).  A single-quoted string
    # performs no escape processing, so the same characters there are
    # an ordinary backslash followed by text and are NOT a violation.
    # The escape sequence is constructed at runtime (sprintf) so
    # that the literal pattern does not appear in this source file
    # and trigger the P3 check on this file itself.
    # ==============================================================
    ['xUNI: in regex - detected',
        sub {
            my $esc = sprintf("\\x{%s}", "263A");
            violates("if (\$s =~ /$esc/) { }\n");
        }],

    ['xUNI: in comment - ignored',
        sub {
            my $esc = sprintf("\\x{%s}", "263A");
            !violates("# $esc\n");
        }],

    ['xUNI: inside dquote string - detected',
        sub {
            my $esc = sprintf("\\x{%s}", "263A");
            violates("my \$s = \"$esc\";\n");
        }],

    ['xUNI: inside single-quoted string - ignored',
        sub {
            my $esc = sprintf("\\x{%s}", "263A");
            !violates("my \$s = '$esc';\n");
        }],

    ['xUNI: escaped backslash in dquote string - ignored',
        sub {
            my $esc = sprintf("\\\\x{%s}", "263A");
            !violates("my \$s = \"$esc\";\n");
        }],

    ['xUNI: inside interpolating heredoc - detected',
        sub {
            my $esc = sprintf("\\x{%s}", "263A");
            violates("my \$s = <<EOT;\n$esc\nEOT\n");
        }],

    ['xUNI: inside non-interpolating heredoc - ignored',
        sub {
            my $esc = sprintf("\\x{%s}", "263A");
            !violates("my \$s = <<'EOT';\n$esc\nEOT\n");
        }],

    ['NUNI: inside dquote string - detected',
        sub {
            my $esc = sprintf("\\N{%s}", "BULLET");
            violates("my \$s = \"$esc\";\n");
        }],

    ['NUNI: in s/// replacement - detected',
        sub {
            my $esc = sprintf("\\N{%s}", "BULLET");
            violates("\$s =~ s/a/$esc/;\n");
        }],

    # ==============================================================
    # yada-yada ...  (Perl 5.12)
    # ==============================================================
    ['yada: in sub - detected',
        sub { violates("sub foo { ... }\n") }],

    ['yada: standalone - detected',
        sub { violates("...\n") }],

    ['yada: range .. not affected',
        sub { !violates("for (1..10) { }\n") }],

    ['yada: in comment - ignored',
        sub { !violates("# ...\n") }],

    # ==============================================================
    # subroutine signatures  (Perl 5.20)
    # ==============================================================
    ['sig: detected',
        sub { violates("sub foo (\$x, \$y) { }\n") }],

    ['sig: empty prototype ok',
        sub { !violates("sub foo () { }\n") }],

    ['sig: old-style proto with \@ ok',
        sub { !violates("sub foo (\\@) { }\n") }],

    # ==============================================================
    # class keyword  (Perl 5.38)
    # ==============================================================
    ['class: detected',
        sub { violates("class Foo { }\n") }],

    ['class: in comment - ignored',
        sub { !violates("# class Foo\n") }],

    ['class: method named "class" ok',
        sub { !violates("my \$c = \$obj->class();\n") }],

    # ==============================================================
    # try block  (Perl 5.34)
    # ==============================================================
    ['try: detected',
        sub { violates("try { die }\n") }],

    ['try: in comment - ignored',
        sub { !violates("# try { die }\n") }],

    # ==============================================================
    # Clean code: valid Perl 5.005_03 constructs
    # ==============================================================
    ['clean: use vars ok',
        sub { !violates("use vars qw(\$x);\n") }],

    ['clean: 2-arg open ok',
        sub { !violates("open(FH, \">file\");\n") }],

    ['clean: open bareword ok',
        sub { !violates("open(OUT, \">out.txt\") or die;\n") }],

    ['clean: use strict ok',
        sub { !violates("use strict;\n") }],

    ['clean: use Exporter ok',
        sub { !violates("use Exporter ();\n") }],

    ['clean: for loop range ok',
        sub { !violates("for my \$i (1..10) { }\n") }],

    ['clean: $x = $y || $z not flagged',
        sub { !violates("my \$x = \$y || \$z;\n") }],

    ['clean: regex-with-slash-slash not flagged by defined-or-assign rule',
        sub { !violates("\$s =~ s/foo/bar/g;\n") }],

    ['clean: sprintf ok',
        sub { !violates("my \$s = sprintf(\"%d\", 42);\n") }],

    # ==============================================================
    # Multi-line and multi-construct
    # ==============================================================
    ['multi: first violation on line 3 detected with correct line',
        sub {
            my @vv = Perl500503Syntax::OrDie::_check_source(
                "use strict;\nuse vars qw(\$x);\nour \$y;\n", 't.pl');
            scalar(@vv) && $vv[0] =~ /line 3/;
        }],

    ['multi: violation in string on line 3 - NOT detected',
        sub {
            !violates("use strict;\nmy \$s = 'our \$x';\n\$s = 1;\n");
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
    print "# EVAL ERROR: $@\n" if $@ && $@ !~ /VIOLATION/;
}

