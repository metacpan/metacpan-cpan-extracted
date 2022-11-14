use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Protocol/FIX.pm',
    'lib/Protocol/FIX/BaseComposite.pm',
    'lib/Protocol/FIX/Component.pm',
    'lib/Protocol/FIX/Component.pod',
    'lib/Protocol/FIX/Field.pm',
    'lib/Protocol/FIX/Group.pm',
    'lib/Protocol/FIX/Message.pm',
    'lib/Protocol/FIX/MessageInstance.pm',
    'lib/Protocol/FIX/Parser.pm',
    'lib/Protocol/FIX/TagsAccessor.pm'
);

notabs_ok($_) foreach @files;
done_testing;
