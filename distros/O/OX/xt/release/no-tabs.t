use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Bread/Board/LifeCycle/Request.pm',
    'lib/OX.pm',
    'lib/OX/Application.pm',
    'lib/OX/Application/Role/Request.pm',
    'lib/OX/Application/Role/RouteBuilder.pm',
    'lib/OX/Application/Role/Router.pm',
    'lib/OX/Application/Role/Router/Path/Router.pm',
    'lib/OX/Application/Role/RouterConfig.pm',
    'lib/OX/Application/Role/Sugar.pm',
    'lib/OX/Meta/Conflict.pm',
    'lib/OX/Meta/Middleware.pm',
    'lib/OX/Meta/Mount.pm',
    'lib/OX/Meta/Mount/App.pm',
    'lib/OX/Meta/Mount/Class.pm',
    'lib/OX/Meta/Role/Application.pm',
    'lib/OX/Meta/Role/Application/ToClass.pm',
    'lib/OX/Meta/Role/Application/ToInstance.pm',
    'lib/OX/Meta/Role/Application/ToRole.pm',
    'lib/OX/Meta/Role/Class.pm',
    'lib/OX/Meta/Role/Composite.pm',
    'lib/OX/Meta/Role/HasMiddleware.pm',
    'lib/OX/Meta/Role/HasRouteBuilders.pm',
    'lib/OX/Meta/Role/HasRoutes.pm',
    'lib/OX/Meta/Role/Path.pm',
    'lib/OX/Meta/Role/Role.pm',
    'lib/OX/Meta/Route.pm',
    'lib/OX/Request.pm',
    'lib/OX/Response.pm',
    'lib/OX/Role.pm',
    'lib/OX/RouteBuilder.pm',
    'lib/OX/RouteBuilder/Code.pm',
    'lib/OX/RouteBuilder/ControllerAction.pm',
    'lib/OX/RouteBuilder/HTTPMethod.pm',
    'lib/OX/Types.pm',
    'lib/OX/Util.pm'
);

notabs_ok($_) foreach @files;
done_testing;
