use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/TOON/XS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/data-toon-01_encode_decode.t',
    't/data-toon-02_validate.t',
    't/data-toon-03_nested_objects.t',
    't/data-toon-04_list_format_arrays.t',
    't/data-toon-05_security.t',
    't/data-toon-06_delimiters.t',
    't/data-toon-07_root_forms.t',
    't/data-toon-08_column_priority.t',
    't/data-toon-09_nested_hash_from_json.t',
    't/interop-01_dual_syntax.t',
    't/pod-coverage.t',
    't/pod.t',
    't/toonpm-01-functions.t',
    't/toonpm-02-object.t',
    't/toonpm-03-errors.t',
    't/toonpm-04-complex.t'
);

notabs_ok($_) foreach @files;
done_testing;
