use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/Constructor/AllErrors.pm',
    'lib/MooseX/Constructor/AllErrors/Error.pm',
    'lib/MooseX/Constructor/AllErrors/Error/Constructor.pm',
    'lib/MooseX/Constructor/AllErrors/Error/Misc.pm',
    'lib/MooseX/Constructor/AllErrors/Error/Required.pm',
    'lib/MooseX/Constructor/AllErrors/Error/TypeConstraint.pm',
    'lib/MooseX/Constructor/AllErrors/Role/Object.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001_basic.t',
    't/002_type_constraint_bug.t',
    't/003_type_coercion.t',
    't/004_BUILD.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
