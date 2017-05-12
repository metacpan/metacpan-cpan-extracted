
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Sietima.pm',
    'lib/Sietima/CmdLine.pm',
    'lib/Sietima/HeaderURI.pm',
    'lib/Sietima/MailStore.pm',
    'lib/Sietima/MailStore/FS.pm',
    'lib/Sietima/Message.pm',
    'lib/Sietima/Policy.pm',
    'lib/Sietima/Role/AvoidDups.pm',
    'lib/Sietima/Role/Debounce.pm',
    'lib/Sietima/Role/Headers.pm',
    'lib/Sietima/Role/ManualSubscription.pm',
    'lib/Sietima/Role/NoMail.pm',
    'lib/Sietima/Role/ReplyTo.pm',
    'lib/Sietima/Role/SubjectTag.pm',
    'lib/Sietima/Role/SubscriberOnly.pm',
    'lib/Sietima/Role/SubscriberOnly/Drop.pm',
    'lib/Sietima/Role/SubscriberOnly/Moderate.pm',
    'lib/Sietima/Role/WithMailStore.pm',
    'lib/Sietima/Role/WithOwner.pm',
    'lib/Sietima/Role/WithPostAddress.pm',
    'lib/Sietima/Runner.pm',
    'lib/Sietima/Subscriber.pm',
    'lib/Sietima/Types.pm',
    't/lib/Test/Sietima.pm',
    't/lib/Test/Sietima/MailStore.pm',
    't/tests/sietima.t',
    't/tests/sietima/cmdline.t',
    't/tests/sietima/headeruri.t',
    't/tests/sietima/mailstore.t',
    't/tests/sietima/message.t',
    't/tests/sietima/multi-role/debounce-moderate.t',
    't/tests/sietima/role/avoid-dups.t',
    't/tests/sietima/role/debounce.t',
    't/tests/sietima/role/headers.t',
    't/tests/sietima/role/manualsubscription.t',
    't/tests/sietima/role/nomail.t',
    't/tests/sietima/role/replyto.t',
    't/tests/sietima/role/subject-tag.t',
    't/tests/sietima/role/subscriberonly/drop.t',
    't/tests/sietima/role/subscriberonly/moderate.t',
    't/tests/sietima/subscriber.t'
);

notabs_ok($_) foreach @files;
done_testing;
