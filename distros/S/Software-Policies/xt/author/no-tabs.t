use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Software/Policies.pm',
    'lib/Software/Policies/CodeOfConduct.pm',
    'lib/Software/Policies/CodeOfConduct/ContributorCovenant.pm',
    'lib/Software/Policies/Contributing.pm',
    'lib/Software/Policies/Contributing/PerlDistZilla.pm',
    'lib/Software/Policies/License.pm',
    'lib/Software/Policies/Security.pm',
    'lib/Software/Policies/Security/Individual.pm',
    't/00-load.t',
    't/contributing.t',
    't/policies.t'
);

notabs_ok($_) foreach @files;
done_testing;
