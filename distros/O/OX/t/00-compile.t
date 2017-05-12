use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.039

use Test::More  tests => 35 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Bread/Board/LifeCycle/Request.pm',
    'OX.pm',
    'OX/Application.pm',
    'OX/Application/Role/Request.pm',
    'OX/Application/Role/RouteBuilder.pm',
    'OX/Application/Role/Router.pm',
    'OX/Application/Role/Router/Path/Router.pm',
    'OX/Application/Role/RouterConfig.pm',
    'OX/Application/Role/Sugar.pm',
    'OX/Meta/Conflict.pm',
    'OX/Meta/Middleware.pm',
    'OX/Meta/Mount.pm',
    'OX/Meta/Mount/App.pm',
    'OX/Meta/Mount/Class.pm',
    'OX/Meta/Role/Application.pm',
    'OX/Meta/Role/Application/ToClass.pm',
    'OX/Meta/Role/Application/ToInstance.pm',
    'OX/Meta/Role/Application/ToRole.pm',
    'OX/Meta/Role/Class.pm',
    'OX/Meta/Role/Composite.pm',
    'OX/Meta/Role/HasMiddleware.pm',
    'OX/Meta/Role/HasRouteBuilders.pm',
    'OX/Meta/Role/HasRoutes.pm',
    'OX/Meta/Role/Path.pm',
    'OX/Meta/Role/Role.pm',
    'OX/Meta/Route.pm',
    'OX/Request.pm',
    'OX/Response.pm',
    'OX/Role.pm',
    'OX/RouteBuilder.pm',
    'OX/RouteBuilder/Code.pm',
    'OX/RouteBuilder/ControllerAction.pm',
    'OX/RouteBuilder/HTTPMethod.pm',
    'OX/Types.pm',
    'OX/Util.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


