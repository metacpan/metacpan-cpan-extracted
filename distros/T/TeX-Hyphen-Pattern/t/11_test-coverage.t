use strict;
use warnings;
use utf8;

use Test::More;
use TeX::Hyphen::Pattern;

if ( !eval { require Test::TestCoverage; 1 } ) {
    plan skip_all => q{Test::TestCoverage required for testing test coverage};
}
plan 'tests' => 1;
Test::TestCoverage::test_coverage('TeX::Hyphen::Pattern');

my $thp = TeX::Hyphen::Pattern->new();
$thp->label(q{nl});
$thp->filename();
$thp->filename();
$thp->label(q{Da_DK});
$thp->filename();
$thp->label(q{NON_EXISTING_LANGUAGE_LABEL});
$thp->filename();
$thp->meta();
$thp->packaged();
$thp->DESTROY();

Test::TestCoverage::ok_test_coverage('TeX::Hyphen::Pattern');
