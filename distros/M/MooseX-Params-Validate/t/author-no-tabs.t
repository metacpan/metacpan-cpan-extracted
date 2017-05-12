
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/Params/Validate.pm',
    'lib/MooseX/Params/Validate/Exception/ValidationFailedForTypeConstraint.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001_basic.t',
    't/002_basic_list.t',
    't/003_nocache_flag.t',
    't/004_custom_cache_key.t',
    't/005_coercion.t',
    't/006_not_moose.t',
    't/007_deprecated.t',
    't/008_positional.t',
    't/009_wrapped.t',
    't/010_overloaded.t',
    't/011_allow_extra.t',
    't/012_ref_as_first_param.t',
    't/013_tc_message.t',
    't/014_anon_does.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-no404s.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-tidyall.t'
);

notabs_ok($_) foreach @files;
done_testing;
