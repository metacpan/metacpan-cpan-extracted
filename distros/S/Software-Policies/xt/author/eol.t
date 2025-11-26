use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
