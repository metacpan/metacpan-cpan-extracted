use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'examples/synopsis',
    'lib/JSON/Schema/Modern/Document/OpenAPI.pm',
    'lib/JSON/Schema/Modern/Vocabulary/OpenAPI.pm',
    'lib/OpenAPI/Modern.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/dialects.t',
    't/discriminator.t',
    't/document-parsing.t',
    't/document-paths.t',
    't/document-toplevel.t',
    't/end-to-end.t',
    't/find_path.t',
    't/lib/Helper.pm',
    't/oas-vocabulary.t',
    't/oas-vocabulary/discriminator.json',
    't/oas-vocabulary/formats.json',
    't/openapi-constructor.t',
    't/operationIds.t',
    't/parameters.t',
    't/recursive_get.t',
    't/results/oas-vocabulary.txt',
    't/validate_request.t',
    't/validate_response.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
