
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
    'lib/Raisin.pm',
    'lib/Raisin/API.pm',
    'lib/Raisin/Decoder.pm',
    'lib/Raisin/Encoder.pm',
    'lib/Raisin/Encoder/JSON.pm',
    'lib/Raisin/Encoder/Text.pm',
    'lib/Raisin/Encoder/YAML.pm',
    'lib/Raisin/Entity.pm',
    'lib/Raisin/Entity/Object.pm',
    'lib/Raisin/Logger.pm',
    'lib/Raisin/Middleware/Formatter.pm',
    'lib/Raisin/Param.pm',
    'lib/Raisin/Plugin.pm',
    'lib/Raisin/Plugin/Logger.pm',
    'lib/Raisin/Plugin/Swagger.pm',
    'lib/Raisin/Request.pm',
    'lib/Raisin/Routes.pm',
    'lib/Raisin/Routes/Endpoint.pm',
    'lib/Raisin/Util.pm',
    'script/raisin',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/behaviour/app-deserialize.t',
    't/behaviour/app-hooks.t',
    't/behaviour/app-routes.t',
    't/behaviour/app-serialize-provides.t',
    't/behaviour/app-serialize.t',
    't/behaviour/plugin-openapi.t',
    't/unit/api.t',
    't/unit/encoder.t',
    't/unit/entity.t',
    't/unit/entity/object.t',
    't/unit/logger.t',
    't/unit/middleware/formatter.t',
    't/unit/param.t',
    't/unit/param/moose.t',
    't/unit/plugin.t',
    't/unit/plugin/logger.t',
    't/unit/plugin/swagger.t',
    't/unit/plugin/swagger/moose.t',
    't/unit/request.t',
    't/unit/routes.t',
    't/unit/routes/endpoint.t',
    't/unit/util.t'
);

notabs_ok($_) foreach @files;
done_testing;
