use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/Method/Signatures.pm',
    'lib/MooseX/Method/Signatures/Meta/Method.pm',
    'lib/MooseX/Method/Signatures/Types.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attributes.t',
    't/basic.t',
    't/caller.t',
    't/closure.t',
    't/declarators.t',
    't/errors.t',
    't/eval.t',
    't/lib/InvalidCase01.pm',
    't/lib/InvalidCase02.pm',
    't/lib/MXMSLabeled.pm',
    't/lib/MXMSMoody.pm',
    't/lib/My/Annoyingly/Long/Name/Space.pm',
    't/lib/Redefined.pm',
    't/lib/TestClass.pm',
    't/lib/TestClassTrait.pm',
    't/lib/TestClassWithMxTypes.pm',
    't/list.t',
    't/meta.t',
    't/method-trait.t',
    't/named_defaults.t',
    't/no_signature.t',
    't/placeholders.t',
    't/precedence.t',
    't/quoted_name.t',
    't/return_value.t',
    't/signatures.t',
    't/sigs-optional.t',
    't/structured.t',
    't/synopsis.t',
    't/too_many_args.t',
    't/traits.t',
    't/type_alias.t',
    't/types.t',
    't/undef_method_arg.t',
    't/undef_method_arg2.t',
    't/where.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/author/transactional-authorized.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
