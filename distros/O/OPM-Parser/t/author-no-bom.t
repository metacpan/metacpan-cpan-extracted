
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'bin/de_opm.pl',
    'lib/OPM/Parser.pm',
    'lib/OPM/Parser/Types.pm',
    't/02_opm.t',
    't/03_invalid_xml_opm.t',
    't/05_framework_version_string.t',
    't/06_minimum_framework.t',
    't/07_validate.t',
    't/08_documentation.t',
    't/09_parse.t',
    't/10_validate_otobo.t',
    't/11_product.t',
    't/data/ProductNews-6.0.5.opm',
    't/data/QuickMerge-3.3.2.opm',
    't/data/QuickMerge-4.0.2.opm',
    't/data/QuickMerge-4.0.3.opm',
    't/data/QuickMergeInvalid-3.3.2.opm',
    't/data/QuickMergeInvalid-3.3.3.opm',
    't/data/QuickMergeInvalid-3.3.4.opm',
    't/data/QuickMergeOtobo-4.0.3.opm',
    't/data/QuickMergeTwoDocs-3.3.2.opm',
    't/data/config.yml',
    't/data/validate.opm'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
