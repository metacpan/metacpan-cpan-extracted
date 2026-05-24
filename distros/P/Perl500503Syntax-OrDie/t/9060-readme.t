######################################################################
#
# 9060-readme.t  README content checks
#
# H1: NAME section present
# H2: SYNOPSIS section present
# H3: DESCRIPTION section present
# H4: INSTALL section present (case-insensitive)
# H5: AUTHOR section present
# H6: LICENSE section present
# H7: README not empty
# H8: module name mentioned in README
# H9: VERSION number mentioned in README
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

plan_skip('README not found') unless -f "$ROOT/README";

plan_tests(9);

my $readme = _slurp("$ROOT/README");
my $ver    = '(unknown)';
{
    my $pm = "$ROOT/lib/Perl500503Syntax/OrDie.pm";
    if (-f $pm) {
        my $src = _slurp($pm);
        $ver = $1 if $src =~ /\$VERSION\s*=\s*['"]([^'"]+)['"]/;
    }
}

ok($readme ne '',                       'H7: README is not empty');
ok($readme =~ /\bNAME\b/,              'H1: README has NAME section');
ok($readme =~ /\bSYNOPSIS\b/,          'H2: README has SYNOPSIS section');
ok($readme =~ /\bDESCRIPTION\b/,       'H3: README has DESCRIPTION section');
ok($readme =~ /install/i,              'H4: README mentions INSTALL');
ok($readme =~ /\bAUTHOR\b/,            'H5: README has AUTHOR section');
ok($readme =~ /\bLICENSE\b/i,          'H6: README mentions LICENSE');
ok($readme =~ /Perl500503Syntax::OrDie/,     'H8: README mentions Perl500503Syntax::OrDie');
ok($readme =~ /\Q$ver\E/,             "H9: README mentions version $ver");

