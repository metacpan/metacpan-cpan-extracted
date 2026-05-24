package INA_CPAN_Check;

######################################################################
#
# INA_CPAN_Check - Shared test library for ina@CPAN distributions
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use vars qw($VERSION @EXPORT_OK);
use Exporter ();
use vars qw(@ISA);
@ISA = qw(Exporter);

$VERSION = '0.01';

@EXPORT_OK = qw(
    ok plan_tests diag plan_skip
    _slurp _slurp_lines _scan_code _manifest_files _find_pm_t
    check_A count_A
    check_B count_B
    check_C count_C
    check_D count_D
    check_E count_E
    check_F count_F
    check_G count_G
    check_H count_H
    check_I count_I
    check_J count_J
    check_K count_K
);

use vars qw($T_PLAN $T_RUN $T_FAIL);
($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);

use File::Spec ();

# Export all symbols into caller's namespace by default
sub import {
    my $class = shift;
    no strict 'refs';
    my $pkg = caller(0);
    for my $sym (@EXPORT_OK) {
        *{"${pkg}::${sym}"} = \&{"INA_CPAN_Check::${sym}"};
    }
}

######################################################################
# TAP helpers
######################################################################

sub plan_tests {
    $T_PLAN = $_[0];
    print "1..$T_PLAN\n";
}

sub ok {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN"
        . (defined($name) && $name ne '' ? " - $name" : '') . "\n";
    return $ok;
}

sub diag {
    print "# $_[0]\n";
}

sub plan_skip {
    my ($reason) = @_;
    print "1..0 # SKIP $reason\n";
    exit 0;
}

END {
    if ($T_PLAN && $T_FAIL) {
        exit 1;
    }
}

######################################################################
# File utilities
######################################################################

sub _slurp {
    my ($path) = @_;
    local *_INA_FH;
    open(_INA_FH, $path) or die "cannot open '$path': $!";
    my $content = do { local $/; <_INA_FH> };
    close _INA_FH;
    return $content;
}

sub _slurp_lines {
    my ($path) = @_;
    local *_INA_FH;
    open(_INA_FH, $path) or die "cannot open '$path': $!";
    my @lines = <_INA_FH>;
    close _INA_FH;
    return @lines;
}

sub _scan_code {
    # returns lines of all .pm and .t files under $root
    my ($root) = @_;
    my @files;
    _find_pm_t($root, \@files);
    my @lines;
    for my $f (@files) {
        my @l = _slurp_lines($f);
        push @lines, map { "$f: $_" } @l;
    }
    return @lines;
}

sub _find_pm_t {
    my ($dir, $result) = @_;
    local *_INA_DIR;
    opendir(_INA_DIR, $dir) or return;
    my @entries = grep { !/^\./ } readdir(_INA_DIR);
    closedir _INA_DIR;
    for my $e (sort @entries) {
        my $path = "$dir/$e";
        if (-d $path) {
            _find_pm_t($path, $result);
        } elsif ($e =~ /\.(?:pm|t)$/) {
            push @{$result}, $path;
        }
    }
}

sub _manifest_files {
    my ($root) = @_;
    my @lines = _slurp_lines("$root/MANIFEST");
    my @files;
    for my $line (@lines) {
        chomp $line;
        $line =~ s/\s*#.*$//;
        $line =~ s/^\s+|\s+$//g;
        next unless $line ne '';
        push @files, $line;
    }
    return @files;
}

######################################################################
# check_A -- MANIFEST completeness
# Every file listed in MANIFEST must exist on disk.
######################################################################
sub count_A { return 1 }
sub check_A {
    my ($root) = @_;
    plan_skip('MANIFEST not found') unless -f "$root/MANIFEST";
    my @files = _manifest_files($root);
    my $n = scalar @files;
    plan_tests($n);
    for my $f (@files) {
        ok(-e "$root/$f", "A1: MANIFEST entry exists: $f");
    }
}

######################################################################
# check_B -- version consistency
# $VERSION in .pm matches META.yml, META.json, Makefile.PL, Changes
######################################################################
sub count_B { return 5 }
sub check_B {
    my ($root) = @_;
    plan_tests(count_B());

    # extract $VERSION from primary .pm
    my $ver = _extract_version($root);
    ok(defined $ver, "B1: \$VERSION found in primary .pm");
    $ver = '(unknown)' unless defined $ver;

    # META.yml
    my $meta_yml = '';
    if (-f "$root/META.yml") {
        $meta_yml = _slurp("$root/META.yml");
    }
    ok($meta_yml =~ /version\s*:\s*['"']?\Q$ver\E['"']?/,
        "B2: META.yml version matches $ver");

    # META.json
    my $meta_json = '';
    if (-f "$root/META.json") {
        $meta_json = _slurp("$root/META.json");
    }
    ok($meta_json =~ /["']version["']\s*:\s*["']\Q$ver\E["']/,
        "B3: META.json version matches $ver");

    # Makefile.PL
    my $mkpl = '';
    if (-f "$root/Makefile.PL") {
        $mkpl = _slurp("$root/Makefile.PL");
    }
    ok($mkpl =~ /VERSION\s*=>\s*['"]\Q$ver\E['"]/,
        "B4: Makefile.PL VERSION matches $ver");

    # Changes
    my $changes = '';
    if (-f "$root/Changes") {
        $changes = _slurp("$root/Changes");
    }
    ok($changes =~ /^\Q$ver\E\b/m,
        "B5: Changes has entry for $ver");
}

sub _extract_version {
    my ($root) = @_;
    # Find the primary .pm file
    my $dist = _dist_name($root);
    (my $pmpath = $dist) =~ s{-}{/}g;
    my $pm = "$root/lib/$pmpath.pm";
    return undef unless -f $pm;
    my $src = _slurp($pm);
    if ($src =~ /\$VERSION\s*=\s*['"]([^'"]+)['"]/) {
        return $1;
    }
    return undef;
}

sub _dist_name {
    my ($root) = @_;
    my $base = $root;
    $base =~ s{.*[/\\]}{};  # basename
    $base =~ s{-[\d.]+$}{};  # strip version
    return $base;
}

######################################################################
# check_C -- encoding: US-ASCII, trailing whitespace, final newline
######################################################################
sub count_C {
    my ($root) = @_;
    plan_skip('MANIFEST not found') unless -f "$root/MANIFEST";
    my @files = _ascii_check_files($root);
    return scalar(@files) * 3;
}
sub check_C {
    my ($root) = @_;
    plan_skip('MANIFEST not found') unless -f "$root/MANIFEST";
    my @files = _ascii_check_files($root);
    plan_tests(scalar(@files) * 3);
    for my $rel (@files) {
        my $path = "$root/$rel";
        my $src  = -f $path ? _slurp($path) : '';
        ok($src !~ /[^\x00-\x7F]/, "C1: US-ASCII only: $rel");
        ok($src !~ /[ \t]+\n/,     "C2: no trailing whitespace: $rel");
        ok($src eq '' || $src =~ /\n\z/, "C3: ends with newline: $rel");
    }
}

sub _ascii_check_files {
    my ($root) = @_;
    my @all = _manifest_files($root);
    return grep {
        /\.(?:pm|pl|t|PL|bat|txt|md|yml|json)$/i
        && !/(?:^|\/)(lib\/Perl500503\/OrDie\.pm)$/
    } @all;
}

######################################################################
# check_D -- Perl 5.005_03 compatibility (warnings stub pattern)
######################################################################
sub count_D { return 2 }
sub check_D {
    my ($root) = @_;
    plan_tests(count_D());
    my @pm_files;
    _find_pm_t("$root/lib", \@pm_files);
    _find_pm_t("$root/t",   \@pm_files);

    my $all_pass = 1;
    my $stub_ok  = 1;
    for my $f (@pm_files) {
        my $src = _slurp($f);
        # Check: if 'use warnings' present, must have !defined guard
        if ($src =~ /^use warnings\b/m) {
            unless ($src =~ /!defined\(&warnings::import\)/) {
                $stub_ok = 0;
                diag("D1: missing warnings stub guard in $f");
            }
        }
        # Check: no 'our ' at top level (rough check)
        if ($src =~ /^our\s+[\$\@\%]/m) {
            $all_pass = 0;
            diag("D2: 'our' found in $f");
        }
    }
    ok($stub_ok,  'D1: warnings stub guards present where needed');
    ok($all_pass, "D2: no bare 'our' at line start in .pm/.t files");
}

######################################################################
# check_E -- style: no shebang in lib/*.pm
######################################################################
sub count_E { return 1 }
sub check_E {
    my ($root) = @_;
    plan_tests(count_E());
    my @pm_files;
    _find_pm_t("$root/lib", \@pm_files);
    my $ok = 1;
    for my $f (@pm_files) {
        my $src = _slurp($f);
        if ($src =~ /^#!/) {
            $ok = 0;
            diag("E1: shebang found in $f");
        }
    }
    ok($ok, 'E1: no shebang in lib/*.pm');
}

######################################################################
# check_F -- eg/ example files exist and are executable-ish
######################################################################
sub count_F { return 1 }
sub check_F {
    my ($root) = @_;
    plan_tests(count_F());
    my @eg;
    if (-d "$root/eg") {
        local *_EG_DIR;
        opendir(_EG_DIR, "$root/eg") or die;
        @eg = grep { /\.pl$/ } readdir(_EG_DIR);
        closedir _EG_DIR;
    }
    ok(scalar(@eg) > 0, 'F1: at least one eg/*.pl example file exists');
}

######################################################################
# check_G -- POD structure
######################################################################
sub count_G { return 6 }
sub check_G {
    my ($root) = @_;
    plan_tests(count_G());
    my $pm = _primary_pm($root);
    my $src = -f $pm ? _slurp($pm) : '';

    ok($src =~ /^=head1\s+NAME\b/m,        'G1: POD has NAME section');
    ok($src =~ /^=head1\s+VERSION\b/m,     'G2: POD has VERSION section');
    ok($src =~ /^=head1\s+SYNOPSIS\b/m,    'G3: POD has SYNOPSIS section');
    ok($src =~ /^=head1\s+DESCRIPTION\b/m, 'G4: POD has DESCRIPTION section');
    ok($src =~ /^=head1\s+AUTHOR\b/m,      'G5: POD has AUTHOR section');
    ok($src =~ /^=head1\s+LICENSE\b/m,     'G6: POD has LICENSE section');
}

sub _primary_pm {
    my ($root) = @_;
    my $dist = _dist_name($root);
    (my $rel = $dist) =~ s{-}{/}g;
    return "$root/lib/$rel.pm";
}

######################################################################
# check_H -- README required sections
######################################################################
sub count_H { return 4 }
sub check_H {
    my ($root) = @_;
    plan_tests(count_H());
    my $readme = '';
    if (-f "$root/README") {
        $readme = _slurp("$root/README");
    }
    ok($readme =~ /\bNAME\b/,        'H1: README has NAME');
    ok($readme =~ /\bSYNOPSIS\b/,    'H2: README has SYNOPSIS');
    ok($readme =~ /\bDESCRIPTION\b/, 'H3: README has DESCRIPTION');
    ok($readme =~ /\bINSTALL/i,      'H4: README has INSTALL');
}

######################################################################
# check_I -- META files well-formed
######################################################################
sub count_I { return 4 }
sub check_I {
    my ($root) = @_;
    plan_tests(count_I());

    my $yml = -f "$root/META.yml"  ? _slurp("$root/META.yml")  : '';
    my $jsn = -f "$root/META.json" ? _slurp("$root/META.json") : '';

    ok($yml =~ /^name\s*:/m,    'I1: META.yml has name field');
    ok($yml =~ /^version\s*:/m, 'I2: META.yml has version field');
    ok($jsn =~ /"name"\s*:/,    'I3: META.json has name field');
    ok($jsn =~ /"version"\s*:/, 'I4: META.json has version field');
}

######################################################################
# check_J -- test file naming (9NNN-name.t convention)
######################################################################
sub count_J { return 1 }
sub check_J {
    my ($root) = @_;
    plan_tests(count_J());
    my @t_files;
    local *_TMP_DIR;
    if (opendir(_TMP_DIR, "$root/t")) {
        @t_files = grep { /\.t$/ } readdir(_TMP_DIR);
        closedir _TMP_DIR;
    }
    my @bad = grep { /^9\d{3}/ && !/^9\d{3}-[a-z]/ } @t_files;
    ok(!@bad, 'J1: 9NNN test files follow 9NNN-name.t naming convention');
}

######################################################################
# check_K -- K3 style: { %hash } form for hash references
######################################################################
sub count_K { return 1 }
sub check_K {
    my ($root) = @_;
    plan_tests(count_K());
    my @pm_files;
    _find_pm_t("$root/lib", \@pm_files);
    my $ok = 1;
    for my $f (@pm_files) {
        my $src = _slurp($f);
        # detect return \%hash; (should be return { %hash };)
        if ($src =~ /\breturn\s+\\[\%]/) {
            $ok = 0;
            diag("K3: 'return \\%hash' should be 'return { %hash }' in $f");
        }
    }
    ok($ok, 'K3: hash references use { %hash } form');
}

1;

