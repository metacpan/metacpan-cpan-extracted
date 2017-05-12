#!/usr/bin/perl

use lib qw( lib );

use Sprocket qw(
    Server::UNIX
    Plugin::Manager
);

my %opts = (
    LogLevel => 4,
    TimeOut => 0,
#    MaxConnections => 10000,
);

Sprocket::Server::UNIX->spawn(
    %opts,
    Name => 'Manager Server',
    ListenAddress => '/tmp/manager',
    Plugins => [
        {
            Plugin => Sprocket::Plugin::Manager->new(),
            Priority => 0,
        }
    ],
);

$poe_kernel->run();

1;
