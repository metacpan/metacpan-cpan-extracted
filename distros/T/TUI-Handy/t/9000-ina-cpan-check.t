use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9000-ina-cpan-check.t - run the shared ina@CPAN check library
# (t/lib/INA_CPAN_Check.pm) over this distribution.
#
# Only the letters this distribution does not already cover in more depth
# on its own are called here:
#
#     B  version consistency        E  code layout style
#     F  eg/ examples shipped       I  generated metadata
#     J  test/prerequisite conventions
#     K  reference and punctuation  L  Changes format
#
# Deliberately NOT called, because a dedicated test file covers each in
# more depth already:
#
#     A  t/9030-manifest.t          C  t/9010-usascii.t
#     D  t/9020-perl5compat.t       G  t/9050-pod.t
#     H  t/9060-readme.t
#
# F IS called: it asserts that at least one eg/*.pl is shipped, and nothing
# else does.  t/9070-examples.t picks up from there -- MANIFEST listing,
# compilation and doc parity for each example -- so the two do not overlap.
#
# B and I read the pmake-generated metadata (Makefile.PL, META.yml,
# META.json).  Those files do not exist in a fresh working tree until
# 'pmake dist' has created them, so they are checked only when present
# and the plan is sized to match.

use lib 't/lib';
use INA_CPAN_Check;

# '.' rather than an absolute path: every check_* call builds "$root/name",
# and "./name" resolves the same way on Windows as it does on Unix.
my $root = '.';

my $have_meta = (-f 'Makefile.PL' && -f 'META.yml' && -f 'META.json') ? 1 : 0;

my $plan = count_E($root)
         + count_F($root)
         + count_J($root)
         + count_K($root)
         + count_L($root);
if ($have_meta) {
    $plan += count_B($root) + count_I($root);
}

plan_tests($plan);

diag('generated metadata absent - B and I are skipped until "pmake dist"')
    unless $have_meta;

check_E($root);
check_F($root);
check_J($root);
check_K($root);
check_L($root);
if ($have_meta) {
    check_B($root);
    check_I($root);
}
