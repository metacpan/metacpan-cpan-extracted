use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use t::Util;

use Net::Proxy;

plan tests => my $tests = 1;

# lock 2 ports
my @free = find_free_ports(2);

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    my ( $proxy_port, $server_port ) = @free;

    my $pid = fork;

SKIP: {
        skip "fork failed", $tests if !defined $pid;
        if ( $pid == 0 ) {

            # the child process runs the proxy
            my $proxy = Net::Proxy->new(
                {   in => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $proxy_port,
                    },
                    out => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $server_port,
                    },
                },
            );

            $proxy->register();
            Net::Proxy->mainloop(1);
            exit;
        }
        else {

            # wait for the proxy to set up
            sleep 1;

            # no server
            my $client = connect_to_port($proxy_port)
                or skip "Couldn't start the client: $!", $tests;

            # the client is actually not connected at all
            is_closed( $client, 'peer' );
            $client->close();
        }
    }
}
