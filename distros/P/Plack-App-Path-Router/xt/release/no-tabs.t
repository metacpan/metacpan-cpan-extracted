use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/App/Path/Router.pm',
    'lib/Plack/App/Path/Router/Custom.pm',
    'lib/Plack/App/Path/Router/PSGI.pm',
    't/00-compile.t',
    't/basic.t',
    't/basic_custom.t',
    't/basic_psgi.t',
    't/basic_psgi_w_obj.t',
    't/basic_returning_psgi.t',
    't/basic_returning_response.t',
    't/basic_target_objects.t',
    't/basic_with_urlmap.t',
    't/custom_request.t',
    't/custom_response.t',
    't/load.t'
);

notabs_ok($_) foreach @files;
done_testing;
