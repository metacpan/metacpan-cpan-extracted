use Test::More;
use strict;
use warnings;
use Net::Proxy;
use t::Util;

my @lines = (
    "thwapp qunckkk aiieee flrbbbbb clunk zlonk\n",
    "tutu bidon toto test3 pipo titi\n",
    "pique ratatam am gram stram colegram\n",
    "Signs_Point_to_Yes Reply_Hazy_Try_Again Cannot_Predict_Now\n",
);

my $tests = 2 * ( @lines + 1 );
plan tests => $tests;

init_rand(@ARGV);
my @free = find_free_ports(3);

SKIP: {
    skip 'Not enough available ports', $tests if @free < 3;

    my ( $proxy_port, $ssl_port, $ssh_port ) = @free;
    my $pid = fork_proxy(
        {   in => {
                type         => 'dual',
                port         => $proxy_port,
                timeout      => 0.5,
                server_first => {
                    type => 'tcp',
                    port => $ssh_port,
                },
                client_first => {
                    type => 'tcp',
                    port => $ssl_port,
                }
            },
            out => { type => 'dummy' },
        },
        2
    );

    skip "fork failed", $tests if !defined $pid;

    # wait for the proxy to set up
    sleep 1;

    # the parent process does the testing
    my $ssh_listener = listen_on_port($ssh_port)
        or skip "Couldn't start the ssh server: $!", $tests;
    my $ssl_listener = listen_on_port($ssl_port)
        or skip "Couldn't start the ssl server: $!", $tests;
    my ( $client, $server );

    # try 'ssh'
    $client = connect_to_port($proxy_port)
        or skip_fail "Couldn't start the client: $!", $tests;
    sleep 1;    # wait for the timeout
    $server = $ssh_listener->accept()
        or skip_fail "Proxy didn't connect: $!", $tests;

    # transmit data
    for my $line (@lines) {
        print $server $line;    # real server speaks first
        is( <$client>, $line, "SSH line received" );
        ( $client, $server ) = random_swap( $client, $server );
    }

    # close connections
    $server->close();
    is_closed( $client, 'peer' );
    $client->close();

    # try ssl
    $client = connect_to_port($proxy_port)
        or skip_fail "Couldn't start the client: $!", $tests;
    print $client $lines[0];    # real client speaks first

    $server = $ssl_listener->accept()
        or skip_fail "Proxy didn't connect: $!", $tests;
    is( <$server>, $lines[0], "SSL line received" );

    # transmit the rest of the data
    shift @lines;
    for my $line (@lines) {
        ( $client, $server ) = random_swap( $client, $server );
        print $client $line;    # real client speaks first
        is( <$server>, $line, "SSL line received" );
    }

    # close connections
    $client->close();
    is_closed( $server, 'peer' );
    $server->close();
}
