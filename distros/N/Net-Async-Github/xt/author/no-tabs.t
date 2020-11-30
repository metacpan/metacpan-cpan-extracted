use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/Async/Github.pm',
    'lib/Net/Async/Github.pod',
    'lib/Net/Async/Github/Branch.pm',
    'lib/Net/Async/Github/Branch.pod',
    'lib/Net/Async/Github/Common.pm',
    'lib/Net/Async/Github/Plan.pm',
    'lib/Net/Async/Github/Plan.pod',
    'lib/Net/Async/Github/PullRequest.pm',
    'lib/Net/Async/Github/PullRequest.pod',
    'lib/Net/Async/Github/RateLimit.pm',
    'lib/Net/Async/Github/RateLimit/Core.pm',
    'lib/Net/Async/Github/Repository.pm',
    'lib/Net/Async/Github/Repository.pod',
    'lib/Net/Async/Github/Team.pm',
    'lib/Net/Async/Github/Team.pod',
    'lib/Net/Async/Github/User.pm',
    'lib/Net/Async/Github/User.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
