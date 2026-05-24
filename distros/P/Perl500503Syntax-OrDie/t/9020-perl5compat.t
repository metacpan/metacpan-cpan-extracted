######################################################################
#
# 9020-perl5compat.t  Perl 5.005_03 source compatibility checks
#
# Verifies that lib/*.pm and t/*.t do not use constructs introduced
# after Perl 5.005_03.
#
# P1:  no 'our'                        (introduced in 5.6)
# P2:  no 3-argument open              (introduced in 5.6)
# P3:  no \x{HHHH} Unicode escapes     (introduced in 5.6)
# P4:  no 'use utf8'                   (introduced in 5.6)
# P5:  no 'use VERSION' >= 5.6
# P6:  no //= defined-or assign        (introduced in 5.10)
# P7:  no 'say'                        (introduced in 5.10)
# P8:  no 'state'                      (introduced in 5.10)
# P9:  no '~~' smart-match             (introduced in 5.10)
# P10: no 'given'/'when'               (introduced in 5.10)
# P11: no 'use feature'                (introduced in 5.10)
# P12: no yada-yada '...'              (introduced in 5.12)
# P13: no subroutine signatures        (introduced in 5.20)
# P14: open() first arg is bareword FH (not scalar var)
#
# EXCEPTIONS:
#   lib/Perl500503Syntax/OrDie.pm is the implementation itself and defines
#   the patterns; its source is exempt from P1-P14.
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
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

# Collect source files; exempt OrDie.pm itself
my @src_files;
_find_pm_t("$ROOT/lib", \@src_files);
_find_pm_t("$ROOT/t",   \@src_files);

# OrDie.pm is exempt from all checks (it defines the patterns).
# 0002 and 0003 are functional tests that intentionally contain
# the very constructs being tested (inside strings/eval); they are
# exempt from the checks that would produce false positives on them.
my @check_files = grep {
    $_ !~ m{lib[/\\]Perl500503Syntax[/\\]OrDie\.pm$}
} @src_files;

# 14 checks per file
plan_tests(scalar(@check_files) * 14);

for my $f (@check_files) {
    my $is_functional_test = ($f =~ m{t[/\\]000[23]-});
    my $rel = $f;
    $rel =~ s{^\Q$ROOT\E[/\\]?}{};

    my $raw = _slurp($f);
    my $src = _mask_compat($raw);   # mask strings/comments for pattern checks

    my @lines     = split(/\n/, $src,  -1);
    my @raw_lines = split(/\n/, $raw,  -1);

    # P1: no 'our'
    my @bad_our = grep { $lines[$_] =~ /\bour\s*[\$\@\%\*]/ } 0..$#lines;
    ok(!@bad_our, "P1: no 'our' declaration: $rel");
    diag("  line " . ($_+1) . ": $raw_lines[$_]") for @bad_our;

    # P2: no 3-argument open
    my @bad_open3 = grep {
        $lines[$_] =~ /\bopen\s*\(\s*[^,\)]+\s*,\s*[^,\)]+\s*,/
    } 0..$#lines;
    ok($is_functional_test || !@bad_open3, "P2: no 3-argument open(): $rel");
    diag("  line " . ($_+1) . ": $raw_lines[$_]") for @bad_open3;

    # P3: no \x{HHHH}
    my @bad_xesc = grep { $raw_lines[$_] =~ /\\x\{[0-9A-Fa-f]+\}/ } 0..$#raw_lines;
    ok(!@bad_xesc, "P3: no \\x{} Unicode escape: $rel");

    # P4: no 'use utf8'
    my @bad_utf8 = grep { $lines[$_] =~ /\buse\s+utf8\b/ } 0..$#lines;
    ok(!@bad_utf8, "P4: no 'use utf8': $rel");

    # P5: no use VERSION >= 5.6
    my @bad_ver = grep {
        $lines[$_] =~ /\buse\s+5\s*\.\s*0*[6-9]\b/
     || $lines[$_] =~ /\buse\s+5\s*\.\s*0*[1-9]\d{2,}\b/
     || $lines[$_] =~ /\buse\s+v5\s*\.\s*[6-9]/
     || $lines[$_] =~ /\buse\s+v5\s*\.1/
    } 0..$#lines;
    ok(!@bad_ver, "P5: no 'use VERSION >= 5.6': $rel");

    # P6: no //=  (pattern built at runtime to avoid false-positive on this file)
    my $p6_pat = '/' . '/=';
    my @bad_defor = grep { index($lines[$_], $p6_pat) >= 0 } 0..$#lines;
    ok(!@bad_defor, "P6: no '" . '/' . '/=' . "' defined-or assign: $rel");

    # P7: no 'say'
    my @bad_say = grep { $lines[$_] =~ /\bsay\b/ } 0..$#lines;
    ok(!@bad_say, "P7: no 'say': $rel");

    # P8: no 'state'
    my @bad_state = grep { $lines[$_] =~ /\bstate\s+[\$\@\%]/ } 0..$#lines;
    ok(!@bad_state, "P8: no 'state' variable: $rel");

    # P9: no ~~  (pattern built at runtime to avoid false-positive on this file)
    my $p9_pat = '~' . '~';
    my @bad_sm = grep { index($lines[$_], $p9_pat) >= 0 } 0..$#lines;
    ok(!@bad_sm, "P9: no '~~' smart-match: $rel");

    # P10: no given/when
    my @bad_gw = grep {
        $lines[$_] =~ /\bgiven\s*\(/ || $lines[$_] =~ /\bwhen\s*\(/
    } 0..$#lines;
    ok(!@bad_gw, "P10: no 'given'/'when': $rel");

    # P11: no 'use feature'
    my @bad_feat = grep { $lines[$_] =~ /\buse\s+feature\b/ } 0..$#lines;
    ok(!@bad_feat, "P11: no 'use feature': $rel");

    # P12: no yada-yada
    my @bad_yy = grep { $lines[$_] =~ /(?<!\.)\.\.\.(?!\.)/ } 0..$#lines;
    ok(!@bad_yy, "P12: no yada-yada '...': $rel");

    # P13: no subroutine signatures
    my @bad_sig = grep {
        $lines[$_] =~ /\bsub\s+\w+\s*\([^\)]*[\$\@\%\*][^\)]*\)\s*\{/
    } 0..$#lines;
    ok(!@bad_sig, "P13: no subroutine signatures: $rel");

    # P14: open() first arg is bareword filehandle
    my @bad_oh = grep {
        $raw_lines[$_] =~ /\bopen\s*\(\s*(?:my\s+)?\$/
    } 0..$#raw_lines;
    ok($is_functional_test || !@bad_oh, "P14: open() uses bareword filehandle: $rel");
    diag("  line " . ($_+1) . ": $raw_lines[$_]") for @bad_oh;
}

# minimal masker for compat checks (mask strings and comments)
sub _mask_compat {
    my ($src) = @_;
    require Perl500503Syntax::OrDie;
    return Perl500503Syntax::OrDie::_mask_source($src);
}

