######################################################################
#
# 9040-style.t  ina@CPAN coding style checks
#
# E1: no shebang line (#!) in lib/*.pm
# E2: use strict present in every .pm
# E3: $VERSION declared in every .pm
# K1: no 'return undef' (return; preferred)
# K2: no string eval in lib/*.pm
# K3: hash refs use { %hash } not \%hash
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

my @pm_files;
_find_pm_t("$ROOT/lib", \@pm_files);

plan_tests(scalar(@pm_files) * 6);

for my $f (@pm_files) {
    my $rel = $f;
    $rel =~ s{^\Q$ROOT\E[/\\]?}{};
    my $src = _slurp($f);

    # E1: no shebang
    ok($src !~ /^#!/, "E1: no shebang in $rel");

    # E2: use strict present
    ok($src =~ /^use strict\b/m, "E2: use strict present in $rel");

    # E3: $VERSION declared
    ok($src =~ /\$VERSION\s*=/, "E3: \$VERSION declared in $rel");

    # K1: no 'return undef'
    my @bad_undef = ();
    my @lines = split(/\n/, $src, -1);
    my $lineno = 0;
    for my $line (@lines) {
        $lineno++;
        if ($line =~ /\breturn\s+undef\b/) {
            push @bad_undef, $lineno;
        }
    }
    ok(!@bad_undef, "K1: no 'return undef' in $rel");
    diag("  line $_: $lines[$_-1]") for @bad_undef;

    # K2: no string eval (eval "...")
    require Perl500503Syntax::OrDie;
    my $masked = Perl500503Syntax::OrDie::_mask_source($src);
    my @eval_lines = ();
    $lineno = 0;
    for my $line (split(/\n/, $masked, -1)) {
        $lineno++;
        if ($line =~ /\beval\s*["']/) {
            push @eval_lines, $lineno;
        }
    }
    # OrDie.pm itself uses eval in the warnings stub install: exempt
    my $exempt = ($rel =~ m{Perl500503Syntax[/\\]OrDie\.pm$});
    ok($exempt || !@eval_lines, "K2: no string eval in $rel");

    # K3: no return \%hash
    my @hash_ref_lines = ();
    $lineno = 0;
    for my $line (@lines) {
        $lineno++;
        if ($line =~ /\breturn\s+\\%/) {
            push @hash_ref_lines, $lineno;
        }
    }
    ok(!@hash_ref_lines, "K3: no 'return \\%hash' in $rel");
    diag("  line $_: $lines[$_-1]") for @hash_ref_lines;
}

