# $Id: 1-basic.t 225 2008-02-12 23:49:44Z davidp $

use Test::More tests => 1;

BEGIN {
use_ok( 'Net::Shoutcast::Admin' );
}


# at the moment, there's no decent automated tests (boo! hiss!).
# to test its operation properly, connection details to a working Shoutcast
# server are required.
# In the next version I hope to rustle up some decent tests, using
# Test::MockObject to fake communication with a server.

# if you have a server you want to test against, uncomment the exit,
# and add the server details below.
exit;

my $shoutcast = Net::Shoutcast::Admin->new(
    host => '',
    port => ,
    admin_password => '',
);


my @listeners = $shoutcast->listeners;

for my $listener (@listeners) {
    diag( sprintf "%s is using %s and has been on for %s",
        $listener->host, $listener->agent, $listener->listen_time
    );
}

diag("Total listeners: " . $shoutcast->listeners);

diag("Current song: "    . $shoutcast->currentsong->title);
