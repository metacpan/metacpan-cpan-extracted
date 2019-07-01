
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
    'lib/Parallel/WorkUnit.pm',
    'lib/Parallel/WorkUnit/Procedural.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-Basic.t',
    't/02-Bug-System.t',
    't/03-Bug-Storable_Error.t',
    't/04-Queue.t',
    't/05-AnyEvent.t',
    't/06-AnyEvent-Queue.t',
    't/07-Ordered-Basic.t',
    't/08-Ordered-Queue.t',
    't/09-Ordered-AnyEvent-Queue.t',
    't/10-Destruction.t',
    't/11-RequireCodelike.t',
    't/12-Nested.t',
    't/13-Start.t',
    't/14-Start-ForceThread.t',
    't/15-Procedural.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/data/perlcriticrc',
    't/release-changes_has_content.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
