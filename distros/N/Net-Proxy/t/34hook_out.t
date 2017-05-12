use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use t::Util;

use Net::Proxy;

my @lines = (
    [ "swa_a_p zamm swish bap crunch\n", "swa_a_p zowie swish bap crunch\n" ],
    [   "zlonk zok zapeth crunch_eth crraack\n",
        "zowie zowie zowie crunch_eth crraack\n"
    ],
    [   "glipp zwapp urkkk cr_r_a_a_ck glurpp\n",
        "glipp zowie urkkk cr_r_a_a_ck glurpp\n"
    ],
    [   "zzzzzwap thwapp zgruppp awk eee_yow\n",
        "zowie thwapp zowie awk eee_yow\n"
    ],
);
my $tests = @lines + 1;

plan tests => $tests;

init_rand(@ARGV);

# lock 2 ports
my @free = find_free_ports(2);

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    my ( $proxy_port, $server_port ) = @free;
    my $pid = fork_proxy(
        {   in => {
                type    => 'tcp',
                host    => 'localhost',
                port    => $proxy_port,
                timeout => 1,
            },
            out => {
                type => 'tcp',
                host => 'localhost',
                port => $server_port,
                hook => sub {
                    my ( $dataref, $sock, $connector ) = @_;
                    $$dataref =~ s/\bz\w+/zowie/g;
                },
            },
        }
    );

    skip "fork failed", $tests if !defined $pid;

    # wait for the proxy to set up
    sleep 1;

    # the parent process does the testing
    my $listener = listen_on_port($server_port)
        or skip "Couldn't start the server: $!", $tests;
    my $client = connect_to_port($proxy_port)
        or skip "Couldn't start the client: $!", $tests;
    my $server = $listener->accept()
        or skip "Proxy didn't connect: $!", $tests;

    # data from the client is transformed by the hook
    my $orig_server = $server;
    for my $line (@lines) {

        # anyone speaks first
        ( $client, $server ) = random_swap( $server, $client );

        # send some data through
        print $client $line->[0];

        my $trans = $server ne $orig_server;
        is( <$server>, $line->[$trans],
            "Line received " . ( "intact", "transformed" )[$trans] );
    }
    $client->close();
    is_closed( $server, 'peer' );
    $server->close();
}
