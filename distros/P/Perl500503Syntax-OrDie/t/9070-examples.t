######################################################################
#
# 9070-examples.t  eg/ example script quality checks
#
# F1: at least one eg/*.pl file exists
# F2: eg/*.pl files use strict
# F3: eg/*.pl files do not contain shebang
# F4: eg/*.pl files mention Perl500503Syntax::OrDie
# F5: eg/*.pl files have no trailing whitespace
# F6: eg/*.pl files end with newline
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

plan_skip('eg/ directory not found') unless -d "$ROOT/eg";

my @eg_files;
{
    local *_EG_DIR;
    opendir(_EG_DIR, "$ROOT/eg") or plan_skip("cannot read eg/: $!");
    @eg_files = sort grep { /\.pl$/ } readdir(_EG_DIR);
    closedir _EG_DIR;
}

plan_skip('no eg/*.pl files found') unless @eg_files;

# The demonstration script must actually exercise the return-value API
# (check_source returns a violation list; it does not die).  A regression
# once wrapped the calls in eval{}/if($@), so every example silently
# reported "(not detected)".  F7/F8 run the demo and assert it detects.
#
# The demo is run IN-PROCESS (STDOUT captured to a temp file via a 2-arg
# dup), NOT as a child via `"$^X" ... 2>&1`.  Spawning a child depends on
# $^X resolution, -I propagation and shell quoting, none of which are
# portable to every Perl 5.005_03 host; the in-process form has no such
# dependency and runs identically everywhere.
my $DEMO     = 'check_compatibility.pl';
my $has_demo = -f "$ROOT/eg/$DEMO";

# F1 + 5 checks per file (+ 2 execution checks when the demo is present)
plan_tests(1 + scalar(@eg_files) * 5 + ($has_demo ? 2 : 0));

ok(scalar(@eg_files) > 0, 'F1: eg/*.pl example files exist');

for my $name (@eg_files) {
    my $path = "$ROOT/eg/$name";
    my $src  = _slurp($path);

    ok($src =~ /^use strict\b/m,           "F2: use strict in eg/$name");
    ok($src !~ /^#!/,                       "F3: no shebang in eg/$name");
    ok($src =~ /Perl500503Syntax::OrDie/,         "F4: mentions Perl500503Syntax::OrDie in eg/$name");
    ok($src !~ /[ \t]+\n/,                  "F5: no trailing whitespace in eg/$name");
    ok($src eq '' || $src =~ /\n\z/,        "F6: ends with newline in eg/$name");
}

if ($has_demo) {
    my $out = _run_demo("$ROOT/eg/$DEMO");

    # F7: the demo reports at least one detected violation.  The broken
    #     eval/$@ form produced no VIOLATION lines at all.
    #     (Match forced to scalar context: a failed list-context match
    #      returns the empty list and would shift ok()'s arguments.)
    my $f7 = ($out =~ /VIOLATION/) ? 1 : 0;
    ok($f7, "F7: $DEMO detects and reports violations");

    # F8: the 'our' example is detected, not shown as "(not detected)".
    my $f8 = ($out =~ /'our'/ && $out !~ /\(not detected\)/) ? 1 : 0;
    ok($f8, "F8: $DEMO flags the 'our' example via the return-value API");
}

# ------------------------------------------------------------------
# _run_demo($path) - run an eg/ demo script in-process with empty
# @ARGV, capturing its STDOUT and returning it as a string.
#
# Uses only 2-arg open (Perl 5.005_03 safe).  STDOUT is duplicated to
# a save handle, redirected to a temp file, restored afterwards.  The
# demo is loaded with do(); its own warnings go to the (untouched)
# STDERR and are intentionally not captured.
# ------------------------------------------------------------------
sub _run_demo {
    my $path = shift;
    my $tmp  = File::Spec->catfile($ROOT, 't', "_demo_out.$$");

    open(_SAVEOUT, ">&STDOUT") or return '';
    unless (open(STDOUT, "> $tmp")) {
        open(STDOUT, ">&_SAVEOUT");
        close _SAVEOUT;
        return '';
    }

    {
        local @ARGV = ();
        do $path;
    }

    open(STDOUT, ">&_SAVEOUT");
    close _SAVEOUT;

    my $out = _slurp($tmp);
    unlink $tmp;
    $out = '' unless defined $out;
    return $out;
}

