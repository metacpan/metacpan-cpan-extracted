use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/Types.pm',
    'lib/MooseX/Types/Base.pm',
    'lib/MooseX/Types/CheckedUtilExports.pm',
    'lib/MooseX/Types/Combine.pm',
    'lib/MooseX/Types/Moose.pm',
    'lib/MooseX/Types/TypeDecorator.pm',
    'lib/MooseX/Types/UndefinedType.pm',
    'lib/MooseX/Types/Util.pm',
    'lib/MooseX/Types/Wrapper.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10_moose-types.t',
    't/11_library-definition.t',
    't/12_wrapper-definition.t',
    't/13_typedecorator.t',
    't/14_compatibility-sub-exporter.t',
    't/15_recursion.t',
    't/16_introspection.t',
    't/17_syntax_errors.t',
    't/18_combined_libs.t',
    't/19_typelib_with_role.t',
    't/20_union_with_string_type.t',
    't/21_coerce_parameterized_types.t',
    't/22_class_type.t',
    't/23_any_subtype.t',
    't/24_class_can_isa.t',
    't/25-fully-qualified.t',
    't/26-multi-combined.t',
    't/lib/Combined.pm',
    't/lib/DecoratorLibrary.pm',
    't/lib/Empty.pm',
    't/lib/MultiCombined.pm',
    't/lib/SubExporterCompatibility.pm',
    't/lib/TestLibrary.pm',
    't/lib/TestLibrary2.pm',
    't/lib/TestNamespaceSep.pm',
    't/lib/TestWrapper.pm',
    't/regressions/01-is_subtype_of.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
