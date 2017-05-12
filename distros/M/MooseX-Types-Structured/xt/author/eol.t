use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/Meta/TypeCoercion/Structured.pm',
    'lib/MooseX/Meta/TypeCoercion/Structured/Optional.pm',
    'lib/MooseX/Meta/TypeConstraint/Structured.pm',
    'lib/MooseX/Meta/TypeConstraint/Structured/Optional.pm',
    'lib/MooseX/Types/Structured.pm',
    'lib/MooseX/Types/Structured/MessageStack.pm',
    'lib/MooseX/Types/Structured/OverflowHandler.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-tuple.t',
    't/03-dict.t',
    't/04-combined.t',
    't/04-map.t',
    't/05-advanced.t',
    't/06-api.t',
    't/07-coerce.t',
    't/08-examples.t',
    't/09-optional.t',
    't/10-recursion.t',
    't/11-overflow.t',
    't/12-error.t',
    't/13-deeper_error.t',
    't/14-fully-qualified.t',
    't/bug-incorrect-message.t',
    't/bug-is-subtype.t',
    't/bug-mixed-stringy.t',
    't/bug-optional.t',
    't/regressions/01-is_type_of.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/test-version.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/pod-no404s.t',
    'xt/release/portability.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
