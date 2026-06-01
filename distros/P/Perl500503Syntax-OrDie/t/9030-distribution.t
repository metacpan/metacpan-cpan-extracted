######################################################################
#
# 9030-distribution.t  Distribution integrity checks
#
# A: MANIFEST completeness
# B: version consistency across .pm / META.yml / META.json /
#    Makefile.PL / Changes
# I: META files have required fields
# J: 9NNN test files use 9NNN-name.t naming convention
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

plan_skip('MANIFEST not found') unless -f "$ROOT/MANIFEST";

my @manifest = _manifest_files($ROOT);

# Count tests: A(per file) + B(5) + I(4) + J(1) + L(21 langs + 1 summary)
my $n = scalar(@manifest) + 5 + 4 + 1 + 21 + 1;
plan_tests($n);

######################################################################
# A: every MANIFEST entry exists on disk
######################################################################
for my $rel (@manifest) {
    ok(-e "$ROOT/$rel", "A1: MANIFEST entry exists: $rel");
}

######################################################################
# B: version consistency
######################################################################
my $ver = undef;
{
    my $pm = "$ROOT/lib/Perl500503Syntax/OrDie.pm";
    if (-f $pm) {
        my $src = _slurp($pm);
        if ($src =~ /\$VERSION\s*=\s*['"]([^'"]+)['"]/) {
            $ver = $1;
        }
    }
}
ok(defined $ver, "B1: \$VERSION found in lib/Perl500503Syntax/OrDie.pm");
$ver = '(unknown)' unless defined $ver;

my $meta_yml = -f "$ROOT/META.yml"  ? _slurp("$ROOT/META.yml")  : '';
my $meta_jsn = -f "$ROOT/META.json" ? _slurp("$ROOT/META.json") : '';
my $mkpl     = -f "$ROOT/Makefile.PL" ? _slurp("$ROOT/Makefile.PL") : '';
my $changes  = -f "$ROOT/Changes"   ? _slurp("$ROOT/Changes")   : '';

ok($meta_yml =~ /version\s*:\s*['"']?\Q$ver\E['"']?/,
   "B2: META.yml version matches \$VERSION ($ver)");
ok($meta_jsn =~ /["']version["']\s*:\s*["']\Q$ver\E["']/,
   "B3: META.json version matches \$VERSION ($ver)");
ok($mkpl =~ /VERSION\s*=>\s*['"]\Q$ver\E['"]/,
   "B4: Makefile.PL VERSION matches \$VERSION ($ver)");
ok($changes =~ /^\Q$ver\E\b/m,
   "B5: Changes has entry for version $ver");

######################################################################
# I: META fields
######################################################################
ok($meta_yml =~ /^name\s*:/m,        'I1: META.yml has name field');
ok($meta_yml =~ /^version\s*:/m,     'I2: META.yml has version field');
ok($meta_jsn =~ /["']name["']\s*:/,  'I3: META.json has name field');
ok($meta_jsn =~ /["']version["']\s*:/,'I4: META.json has version field');

######################################################################
# J: 9NNN test file naming
######################################################################
my @t_files;
{
    local *_T_DIR;
    if (opendir(_T_DIR, "$ROOT/t")) {
        @t_files = grep { /\.t$/ } readdir(_T_DIR);
        closedir _T_DIR;
    }
}
my @bad_names = grep { /^9\d{3}/ && !/^9\d{3}-[a-z]/ } @t_files;
ok(!@bad_names, 'J1: 9NNN test files follow 9NNN-name.t convention');
diag("  bad name: $_") for @bad_names;


######################################################################
# L: doc/ cheatsheet files exist (21 languages + perldelta_summary)
######################################################################
my @LANGS = qw(
    BM BN EN FR HI ID JA KM KO MN
    MY NE SI TH TL TR TW UR UZ VI
    ZH
);
for my $lang (@LANGS) {
    my $f = "$ROOT/doc/Perl500503Syntax-OrDie_cheatsheet.$lang.txt";
    ok(-f $f, "L1: doc cheatsheet exists: $lang");
}
my $pds = "$ROOT/doc/perldelta_summary.txt";
ok(-f $pds, 'L2: doc/perldelta_summary.txt exists');
