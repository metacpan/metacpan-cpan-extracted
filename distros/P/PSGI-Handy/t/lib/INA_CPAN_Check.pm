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

$VERSION = '0.36';

@EXPORT_OK = qw(
    ok plan_tests diag plan_skip end_testing
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

use vars qw($T_PLAN $T_RUN $T_FAIL
            $T_PLANNED $T_SKIPPED $T_DOUBLE $T_FINALIZED);
($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
# Regression guards for two defect classes that previously slipped through
# (a test passing when run by hand but FAILing under a real TAP harness):
#   $T_PLANNED  -- a "1..N" (or SKIP) plan line has already been emitted
#   $T_SKIPPED  -- the plan was a "1..0 # SKIP"
#   $T_DOUBLE   -- plan_tests()/plan_skip() was called after a plan existed
#   $T_FINALIZED-- _finalize() has already run (END + explicit end_testing)
($T_PLANNED, $T_SKIPPED, $T_DOUBLE, $T_FINALIZED) = (0, 0, 0, 0);

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
    # A plan line must be emitted at most once per test file. Emitting a
    # second "1..N" corrupts the TAP stream ("More than one plan found in
    # TAP output") and makes the file FAIL under a real harness even though
    # every "ok" line passes when the script is run by hand. If a plan was
    # already emitted, do NOT print another one; record the error so that
    # _finalize() reports a clear, immediate failure instead.
    if ($T_PLANNED) {
        $T_DOUBLE++;
        diag("plan_tests($_[0]) called after a plan of $T_PLAN was already "
           . "emitted; ignoring the extra plan");
        return;
    }
    $T_PLAN    = $_[0];
    $T_PLANNED = 1;
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
    if ($T_PLANNED) {
        $T_DOUBLE++;
        diag("plan_skip() called after a plan was already emitted; ignoring");
        return;
    }
    $T_PLANNED = 1;
    $T_SKIPPED = 1;
    print "1..0 # SKIP $reason\n";
    exit 0;
}

# Reconcile the emitted plan with the number of assertions actually run, and
# signal failure to the harness through the exit status only. This is the
# safety net that turns the two historical defects -- a duplicate plan line
# and a plan count that does not match the number of ok() calls -- into a
# loud, immediate failure on the author's own machine, with no TAP harness
# required. exit() is never called from here: doing so from an END block
# makes Perl 5.6 and earlier abort with "Callback called exit.", which is
# printed ahead of (and masks) the real "not ok" line. Assigning to $? sets
# the process exit status portably, all the way back to Perl 5.005_03.
sub _finalize {
    return if $T_FINALIZED;
    $T_FINALIZED = 1;

    if ($T_PLANNED && !$T_SKIPPED) {
        if ($T_DOUBLE) {
            diag("plan was set more than once "
               . "(" . ($T_DOUBLE + 1) . " plan calls); "
               . "only the first plan of $T_PLAN was emitted");
            $T_FAIL++;
        }
        if ($T_RUN != $T_PLAN) {
            diag("Looks like you planned $T_PLAN test(s) but ran $T_RUN.");
            $T_FAIL++;
        }
    }
}

# Kept for backward compatibility: test files call this via END{end_testing()}.
# It both reconciles the plan and (when run inside an END block, as the
# END{end_testing()} idiom does) sets the exit status.
sub end_testing {
    _finalize();
    $? = 1 if $T_FAIL;
}

# The module's own END block is the authoritative place to set the exit
# status: assigning to $? takes effect only when done inside an END block,
# and this runs for every test file whether or not it has its own END.
END {
    _finalize();
    $? = 1 if $T_FAIL;
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
        }
        elsif ($e =~ /\.(?:pm|t)$/) {
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
sub count_A {
    my ($root) = @_;
    return 0 unless defined($root) && -f "$root/MANIFEST";
    return scalar(_manifest_files($root));
}
sub check_A {
    my ($root) = @_;
    return unless -f "$root/MANIFEST";
    my @files = _manifest_files($root);
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
    my $pm = _primary_pm($root);
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
    return unless -f "$root/MANIFEST";
    my @files = _ascii_check_files($root);
    for my $rel (@files) {
        my $path = "$root/$rel";
        my $src  = -f $path ? _slurp($path) : '';
        # US-ASCII is required for Perl source and metadata (5.005_03
        # portability), but the 21-language cheatsheets under doc/ carry
        # native non-Latin scripts (and accented Latin) by design, so they
        # are exempt from C1. C2/C3 still apply to them.
        my $ascii_exempt = ($rel =~ m{^(?:doc|tutorial/tut)/.*\.txt$}i);
        ok($ascii_exempt || $src !~ /[^\x00-\x7F]/, "C1: US-ASCII only: $rel");
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
    # The primary module is the first MANIFEST entry (ina convention, as
    # used by pmake.bat). Deriving it from MANIFEST is robust regardless of
    # the directory name or a trailing "/.." that rel2abs leaves in $root.
    if (-f "$root/MANIFEST") {
        my @manifest = _manifest_files($root);
        if (@manifest && $manifest[0] =~ /\.pm$/ && -f "$root/$manifest[0]") {
            return "$root/$manifest[0]";
        }
    }
    # Fallback: derive from the distribution directory name.
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
    my ($root, %opt) = @_;
    # k3_exempt is a regular expression (as a string) matched against the
    # *name* of the returned hash. Hash names that match are allowed to use
    # the "return \%name" form (e.g. accessor-style %env / %opts / %args).
    # When omitted, no name is exempt and every "return \%..." is flagged.
    my $exempt = defined($opt{k3_exempt}) ? $opt{k3_exempt} : '';
    my @pm_files;
    _find_pm_t("$root/lib", \@pm_files);
    my $ok = 1;
    for my $f (@pm_files) {
        my $src = _slurp($f);
        # detect "return \%hash;" (should be "return { %hash };").
        # \w* also captures the empty name of forms such as "return \%{...}",
        # which is never exempt and is therefore always flagged.
        while ($src =~ /\breturn\s+\\\%(\w*)/g) {
            my $name = $1;
            next if $name ne '' && $exempt ne '' && $name =~ /$exempt/;
            $ok = 0;
            diag("K3: 'return \\%$name' should be 'return { %$name }' in $f");
        }
    }
    ok($ok, 'K3: hash references use { %hash } form');
}

######################################################################
# selfcheck_suite -- dist-time TAP plan-sanity check of the test suite
#
# Runs every t/*.t (and, by default, xt/*.t) in a child Perl and verifies
# the TAP each one emits, catching the two defect classes that a plain
# "perl t/foo.t" by hand does NOT reveal but a real harness (and therefore
# CPAN Testers) does:
#
#   1. more than one "1..N" plan line in a single file
#      ("More than one plan found in TAP output")
#   2. a plan count that does not match the number of ok/not-ok lines
#      ("planned X but ran Y")
#
# It also fails on any "not ok" line. A "1..0 # SKIP" file is accepted.
#
# Intended to be invoked from pmake.bat at "pmake dist" time:
#   perl -Ilib -It/lib -MINA_CPAN_Check \
#        -e "exit(INA_CPAN_Check::selfcheck_suite())"
#
# Options (name => value):
#   dir   => 't'                test directory (default 't')
#   xt    => 1                  also run xt/*.t if present (default 1)
#   inc   => ['lib','t/lib']    -I paths for the child Perl
#   quiet => 0                  suppress the per-file PASS lines
#
# Returns the number of test files that failed the check (0 == all good),
# suitable for exit().
######################################################################
sub selfcheck_suite {
    my %opt = @_;
    my $dir   = defined($opt{dir})   ? $opt{dir}   : 't';
    my $do_xt = exists($opt{xt})     ? $opt{xt}    : 1;
    my $quiet = $opt{quiet} ? 1 : 0;
    my @inc   = (defined($opt{inc}) && ref($opt{inc}) eq 'ARRAY')
                ? @{$opt{inc}} : ('lib', "$dir/lib");

    my @files = _suite_files($dir);
    if ($do_xt) {
        push @files, _suite_files('xt');
    }

    unless (@files) {
        print "selfcheck_suite: no test files found under $dir/\n" unless $quiet;
        return 0;
    }

    # Quote the Perl interpreter path for the piped command (it may contain
    # spaces, e.g. C:\Program Files\...). Inc args and file names in an ina
    # distribution never contain spaces.
    my $perl = $^X;
    $perl = qq{"$perl"} if $perl =~ /\s/;
    my $incstr = join(' ', map { "-I$_" } @inc);

    my $errors = 0;
    for my $file (@files) {
        my $cmd = "$perl $incstr $file";
        my @out;
        # open(FH, "CMD |") is portable to Perl 5.005_03 on both Windows
        # (via cmd.exe) and Unix. TAP (plan + ok/not-ok lines) is on STDOUT,
        # so capturing STDOUT alone is sufficient; no shell redirection.
        if (open(_SC_RUN, "$cmd |")) {
            @out = <_SC_RUN>;
            close _SC_RUN;
        }
        else {
            print "FAIL $file: cannot execute ($!)\n";
            $errors++;
            next;
        }

        my @plans = grep { /^1\.\.\d+/ } @out;
        my $skip  = grep { /^1\.\.0\b.*#\s*SKIP/i } @out;
        my $nok   = grep { /^ok\b/ }     @out;
        my $nnok  = grep { /^not ok\b/ } @out;

        if ($skip && @plans == 1) {
            print "skip $file (SKIP)\n" unless $quiet;
            next;
        }
        if (@plans == 0) {
            print "FAIL $file: no TAP plan emitted\n";
            $errors++;
            next;
        }
        if (@plans > 1) {
            print "FAIL $file: more than one plan line ("
                . scalar(@plans) . ")\n";
            $errors++;
            next;
        }
        my ($planned) = $plans[0] =~ /^1\.\.(\d+)/;
        my $ran = $nok + $nnok;
        if ($ran != $planned) {
            print "FAIL $file: planned $planned but ran $ran\n";
            $errors++;
            next;
        }
        if ($nnok) {
            print "FAIL $file: $nnok failing test(s)\n";
            $errors++;
            next;
        }
        print "ok   $file ($planned)\n" unless $quiet;
    }

    if ($errors) {
        print "selfcheck_suite: FAIL -- $errors of "
            . scalar(@files) . " test file(s) failed.\n";
    }
    else {
        print "selfcheck_suite: PASS -- "
            . scalar(@files) . " test file(s) OK.\n";
    }
    return $errors;
}

sub _suite_files {
    my ($dir) = @_;
    return () unless -d $dir;
    local *_SC_DIR;
    opendir(_SC_DIR, $dir) or return ();
    my @t = grep { /\.t$/ } readdir(_SC_DIR);
    closedir _SC_DIR;
    return map { "$dir/$_" } sort @t;
}

1;

