use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'examples/tic_tac_toe.pl',
    'examples/units/bytes.pl',
    'examples/units/time.pl',
    'lib/Moose/Autobox.pm',
    'lib/Moose/Autobox/Array.pm',
    'lib/Moose/Autobox/Code.pm',
    'lib/Moose/Autobox/Defined.pm',
    'lib/Moose/Autobox/Hash.pm',
    'lib/Moose/Autobox/Indexed.pm',
    'lib/Moose/Autobox/Item.pm',
    'lib/Moose/Autobox/List.pm',
    'lib/Moose/Autobox/Number.pm',
    'lib/Moose/Autobox/Ref.pm',
    'lib/Moose/Autobox/Scalar.pm',
    'lib/Moose/Autobox/String.pm',
    'lib/Moose/Autobox/Undef.pm',
    'lib/Moose/Autobox/Value.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/000_load.t',
    't/001_basic.t',
    't/002_role_hierarchy.t',
    't/003_p6_example.t',
    't/004_list_compressions.t',
    't/005_string.t',
    't/006_y_combinator.t',
    't/007_base.t',
    't/008_flatten.t',
    't/009_number.t',
    't/010_each.t',
    't/011_each_n_values.t',
    't/012_first_last.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/portability.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
