
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
    'lib/Mojolicious/Plugin/ExposeControllerMethod.pm',
    'lib/Mojolicious/Plugin/ExposeControllerMethod/Proxy.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/basic.t',
    't/my_app/lib/MyApp.pm',
    't/my_app/lib/MyApp/Controller/Example.pm',
    't/my_app/templates/example/welcome.html.ep',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-portability.t',
    't/release-tidyall.t'
);

notabs_ok($_) foreach @files;
done_testing;
