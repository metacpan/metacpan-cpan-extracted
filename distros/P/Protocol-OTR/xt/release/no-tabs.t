use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Protocol/OTR.pm',
    'lib/Protocol/OTR/Account.pm',
    'lib/Protocol/OTR/Channel.pm',
    'lib/Protocol/OTR/Contact.pm',
    'lib/Protocol/OTR/Fingerprint.pm'
);

notabs_ok($_) foreach @files;
done_testing;
