
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
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
    't/lib/Plack/Test/MockHTTP.pm',
    't/lib/Test/XSRFBlock/App.pm',
    't/lib/Test/XSRFBlock/Util.pm',
    't/release-kwalitee.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
