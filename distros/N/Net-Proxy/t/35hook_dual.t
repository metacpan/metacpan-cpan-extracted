use Test::More;
use strict;
use warnings;
use Net::Proxy;
use t::Util;

my @lines = (
    [   "thwapp qunckkk aiieee flrbbbbb clunk zlonk\n",
        "thwapp qunckkk aiieee flrbbbbb clunk zowie\n",
        "thwapp qunckkk aiieee flrbbbbb clunk zlonk\n",
    ],
    [   "cr_r_a_a_ck splatt crr_aaack awkkkkkk clunk zlopp ooooff pow\n",
        "cr_r_a_a_ck splatt crr_aaack awkkkkkk clunk zowie ooooff pow\n",
        "cr_r_a_a_ck splatt crr_aaack awkkkkkk clunk zlonk ooooff pow\n",
    ],
    [   "zgruppp clange clank_est whack zlopp pow awk swish\n",
        "zowie clange clank_est whack zowie pow awk swish\n",
        "zlonk clange clank_est whack zlonk pow awk swish\n",
    ],
    [   "bonk ouch_eth swa_a_p clank_est clash whack splatt zamm\n",
        "bonk ouch_eth swa_a_p clank_est clash whack splatt zowie\n",
        "bonk ouch_eth swa_a_p clank_est clash whack splatt zlonk\n",
    ],
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
                type    => 'dual',
                port    => $proxy_port,
                timeout => 0.5,
                hook    => sub {
                    my ( $dataref, $sock, $connector ) = @_;
                    $$dataref =~ s/\bz\w+/zowie/g;
                },
                server_first => {
                    type => 'tcp',
                    port => $ssh_port,
                },
                client_first => {
                    type => 'tcp',
                    port => $ssl_port,
                    hook => sub {
                        my ( $dataref, $sock, $connector ) = @_;
                        $$dataref =~ s/\bz\w+/zlonk/g;
                    },
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
    my $orig_client = $client;
    for my $line (@lines) {
        print $server $line->[0];    # real server speaks first
        my $trans = $client ne $orig_client;
        is( <$client>, $line->[$trans],
            'SSH line received ' . ( 'intact', 'transformed' )[$trans] );
        ( $client, $server ) = random_swap( $client, $server );
    }

    # close connections
    $server->close();
    is_closed( $client, 'peer' );
    $client->close();

    # try ssl
    $client = connect_to_port($proxy_port)
        or skip_fail "Couldn't start the client: $!", $tests;
    print $client $lines[0][0];    # real client speaks first

    $server = $ssl_listener->accept()
        or skip_fail "Proxy didn't connect: $!", $tests;
    is( <$server>, $lines[0][1],
        "First SSL line received transformed (client)" );

    # transmit the rest of the data
    shift @lines;
    $orig_client = $client;
    for my $line (@lines) {
        ( $client, $server ) = random_swap( $client, $server );
        my $trans = $client eq $orig_client ? 1 : 2;
        print $client $line->[0];    # real client speaks first
        is( <$server>, $line->[$trans],
            'SSL line received transformed '
                . ( '', '(client)', '(server)' )[$trans] );
    }

    # close connections
    $client->close();
    is_closed( $server, 'peer' );
    $server->close();
}
