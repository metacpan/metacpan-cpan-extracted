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

# F1 + 5 checks per file
plan_tests(1 + scalar(@eg_files) * 5);

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

