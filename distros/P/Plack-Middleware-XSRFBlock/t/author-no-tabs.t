
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
    'lib/Plack/Middleware/XSRFBlock.pm',
    't/00-load.t',
    't/01.basic.t',
    't/02.content.t',
    't/03.blocked.t',
    't/03.meta_tag.t',
    't/03.request_header.t',
    't/03.token_per_request.t',
    't/04.cookie_options.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/lib/Plack/Test/MockHTTP.pm',
    't/lib/Test/XSRFBlock/App.pm',
    't/lib/Test/XSRFBlock/Util.pm',
    't/release-kwalitee.t'
);

notabs_ok($_) foreach @files;
done_testing;
