# $Id: 11-updates.t 1783 2005-01-09 05:44:52Z btrott $

use warnings;
use strict;
use Test::More;
use POE qw( Component::BlogCloud Component::Server::TCP );

BEGIN { plan tests => 14 }

use constant TEST_PORT => 9999;

## Create the blo.gs client, and point it towards the fake server
## that we will create below.
POE::Component::BlogCloud->spawn(
    ReceivedUpdate => \&blog_update,
    RemoteAddress  => 'localhost',
    RemotePort     => TEST_PORT,
);

## Now create the server.
POE::Component::Server::TCP->new(
    Alias => 'myserver',
    Port => TEST_PORT,
    ClientConnected => \&client_connect,
    ClientInput => sub { },
);

{
    ## Supress "Client got read error 0 (Normal disconnection)" warning.
    local $SIG{__WARN__} = sub { };
    POE::Kernel->run;
}
exit;

our $count = 0;
sub blog_update {
    my($update) = $_[ ARG0 ];
    ok($update);
    is(ref($update), 'POE::Component::BlogCloud::Update');
    unless ($count++) {
        is($update->uri, 'http://btrott.typepad.com/');
        is($update->name, 'StupidFool.org');
        is($update->service, 'ping');
        is($update->feed_uri, 'http://btrott.typepad.com/typepad/atom.xml');
        is($update->updated_at->iso8601, '2005-01-03T01:09:50');
    } else {
        is($update->uri, 'http://mena.typepad.com/');
        is($update->name, 'Not a Dollarshort');
        is($update->service, 'ping');
        ok(!$update->feed_uri);
        is($update->updated_at->iso8601, '2005-01-03T01:10:00');
    }
}

sub client_connect {
    my($session, $kernel, $heap) = @_[ SESSION, KERNEL, HEAP ];
    $heap->{client}->put(<<XML);
<?xml version="1.0" encoding="utf-8"?>
<weblogUpdates version="1" time="20041127T22:51:58Z">
<weblog name="StupidFool.org" url="http://btrott.typepad.com/" rss="http://btrott.typepad.com/typepad/atom.xml" service="ping" ts="20050103T01:09:50Z" />
<weblog name="Not a Dollarshort" url="http://mena.typepad.com/" service="ping" ts="20050103T01:10:00Z" />
XML
    $kernel->yield('shutdown');
    $kernel->post(myserver => 'shutdown');
}
