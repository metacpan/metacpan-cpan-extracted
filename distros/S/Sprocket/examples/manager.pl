#!/usr/bin/perl

use lib qw( lib );

use Sprocket qw(
    Server
    Plugin::Manager
);

my %opts = (
    LogLevel => 4,
    TimeOut => 0,
#    MaxConnections => 10000,
);

Sprocket::Server->spawn(
    %opts,
    Name => 'Manager Server',
    ListenAddress => '127.0.0.1',
    ListenPort => 5000,
    Plugins => [
        {
            Plugin => Sprocket::Plugin::Manager->new(),
            Priority => 0,
        }
    ],
);

$poe_kernel->run();

1;
