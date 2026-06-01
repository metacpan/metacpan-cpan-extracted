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
    # Note: \x{} inside a double-quoted string is masked and
    # therefore not detected by the static scanner.  The typical
    # use in a regex or outside a string IS detected.
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

    ['xUNI: inside dquote string - masked (not detected)',
        sub {
            my $esc = sprintf("\\x{%s}", "263A");
            !violates("my \$s = \"$esc\";\n");
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

