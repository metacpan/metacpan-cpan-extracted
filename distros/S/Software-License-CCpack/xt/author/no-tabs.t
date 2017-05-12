use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Software/License/CC_BY_1_0.pm',
    'lib/Software/License/CC_BY_2_0.pm',
    'lib/Software/License/CC_BY_3_0.pm',
    'lib/Software/License/CC_BY_4_0.pm',
    'lib/Software/License/CC_BY_NC_1_0.pm',
    'lib/Software/License/CC_BY_NC_2_0.pm',
    'lib/Software/License/CC_BY_NC_3_0.pm',
    'lib/Software/License/CC_BY_NC_4_0.pm',
    'lib/Software/License/CC_BY_NC_ND_2_0.pm',
    'lib/Software/License/CC_BY_NC_ND_3_0.pm',
    'lib/Software/License/CC_BY_NC_ND_4_0.pm',
    'lib/Software/License/CC_BY_NC_SA_1_0.pm',
    'lib/Software/License/CC_BY_NC_SA_2_0.pm',
    'lib/Software/License/CC_BY_NC_SA_3_0.pm',
    'lib/Software/License/CC_BY_NC_SA_4_0.pm',
    'lib/Software/License/CC_BY_ND_1_0.pm',
    'lib/Software/License/CC_BY_ND_2_0.pm',
    'lib/Software/License/CC_BY_ND_3_0.pm',
    'lib/Software/License/CC_BY_ND_4_0.pm',
    'lib/Software/License/CC_BY_ND_NC_1_0.pm',
    'lib/Software/License/CC_BY_SA_1_0.pm',
    'lib/Software/License/CC_BY_SA_2_0.pm',
    'lib/Software/License/CC_BY_SA_3_0.pm',
    'lib/Software/License/CC_BY_SA_4_0.pm',
    'lib/Software/License/CC_PDM_1_0.pm',
    'lib/Software/License/CCpack.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t'
);

notabs_ok($_) foreach @files;
done_testing;
