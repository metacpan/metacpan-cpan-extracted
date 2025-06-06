use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'examples/README',
    'lib/Net/MAC/Vendor.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/extract_oui_from_html.t',
    't/fetch_oui.t',
    't/fetch_oui_from_custom.t',
    't/fetch_oui_from_ieee.t',
    't/load_cache.t',
    't/normalize_mac.t',
    't/oui.t',
    't/parse_oui.t',
    't/run.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
