
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/NanoMsg/Raw.pm',
    'lib/NanoMsg/Raw/Message.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/block.t',
    't/bus.t',
    't/domain.t',
    't/emfile.t',
    't/export.t',
    't/inproc.t',
    't/iovec.t',
    't/ipc.t',
    't/msg.t',
    't/pair.t',
    't/pipeline.t',
    't/poll.t',
    't/prio.t',
    't/pubsub.t',
    't/recv-free-segv.t',
    't/release-new-version.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/reqrep.t',
    't/send-recv.t',
    't/separation.t',
    't/survey.t',
    't/tcp.t',
    't/timeo.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
