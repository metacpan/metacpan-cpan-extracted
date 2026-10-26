
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/perl-version-bump',
    'lib/Perl/Version/Bumper.pm',
    'lib/Perl/Version/Bumper/Helper/Version.pm',
    'lib/Perl/Version/Bumper/Rationale.pod',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-distmeta.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/bump.t',
    't/bump/001_basic.data',
    't/bump/002_features.data',
    't/bump/003_bundles.data',
    't/bump/004_non_existent_features.data',
    't/bump/005_misc.data',
    't/bump/006_advent.data',
    't/bump/007_enable_known.data',
    't/bump/008_disable_known.data',
    't/bump/009_strict.data',
    't/bump/010_warnings.data',
    't/bump/011_whtp7.data',
    't/bump/101_say.data',
    't/bump/102_state.data',
    't/bump/103_switch.data',
    't/bump/104_unicode_strings.data',
    't/bump/105_array_base.data',
    't/bump/106_current_sub.data',
    't/bump/107_evalbytes.data',
    't/bump/108_fc.data',
    't/bump/109_unicode_eval.data',
    't/bump/110_lexical_subs.data',
    't/bump/111_postderef.data',
    't/bump/112_postderef_qq.data',
    't/bump/113_signatures.data',
    't/bump/114_bitwise.data',
    't/bump/115_refaliasing.data',
    't/bump/116_declared_refs.data',
    't/bump/117_indirect.data',
    't/bump/118_isa.data',
    't/bump/119_multidimensional.data',
    't/bump/120_bareword_filehandles.data',
    't/bump/121_try.data',
    't/bump/122_defer.data',
    't/bump/123_extra_paired_delimiters.data',
    't/bump/124_module_true.data',
    't/bump/125_class.data',
    't/bump/126_apostrophe_as_package_separator.data',
    't/bump/127_smartmatch.data',
    't/bump/128_keyword_all.data',
    't/bump/129_keyword_any.data',
    't/bump/130_enhanced_xx.data',
    't/bump_safely.t',
    't/bump_safely/001_die.data',
    't/bump_safely/002_v585.data',
    't/bump_safely/003_strict.data',
    't/bump_safely/006_advent.data',
    't/bump_safely/113_signatures.data',
    't/bump_safely/117_indirect.data',
    't/bump_safely/118_isa.data',
    't/bump_safely/119_multidimensional.data',
    't/bump_safely/120_bareword_filehandles.data',
    't/bump_safely/121_try.data',
    't/bump_safely/122_defer.data',
    't/bump_safely/125_class.data',
    't/fail.t',
    't/lib/TestFunctions.pm',
    't/version.t',
    't/version_doc.t'
);

notabs_ok($_) foreach @files;
done_testing;
