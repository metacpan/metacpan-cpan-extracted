use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use File::Spec::Functions;
use t::Util;

use Net::Proxy;

my @lines = (
    "swa_a_p bang swish bap crunch\n",
    "zlonk zok zapeth crunch_eth crraack\n",
    "glipp zwapp urkkk cr_r_a_a_ck glurpp\n",
    "zzzzzwap thwapp zgruppp awk eee_yow\n",
);
my $tests = @lines + 1;

plan tests => $tests;

init_rand(@ARGV);

# lock 2 ports
my @free = find_free_ports(2);

SKIP: {
    eval { require IO::Socket::SSL; };
    skip 'IO::Socket::SSL required to test ssl', $tests if $@;
    skip 'Not enough available ports',           $tests if @free < 2;

    no warnings 'once';
    $IO::Socket::SSL::DEBUG = $ENV{NET_PROXY_VERBOSITY} || 0;

    my ( $proxy_port, $server_port ) = @free;
    my $pid = fork_proxy(
        {   in => {
                type          => 'ssl',
                port          => $proxy_port,
                timeout       => 1,
                SSL_cert_file => catfile( 't', 'test.cert' ),
                SSL_key_file  => catfile( 't', 'test.key' ),
            },
            out => {
                type => 'tcp',
                host => 'localhost',
                port => $server_port,
            },
        }
    );

    skip 'proxy fork failed', $tests if !defined $pid;

    # wait for the proxy to set up
    sleep 1;

    # start a server
    my $listener = listen_on_port($server_port)
        or skip "Couldn't start the server: $!", $tests;

    # start a client
    my $client = IO::Socket::SSL->new(
        PeerAddr => 'localhost',
        PeerPort => $proxy_port
    ) or skip "Couldn't start the client: $!", $tests;

    my $server = $listener->accept()
        or skip "Proxy didn't connect: $!", $tests;

    for my $line (@lines) {
        ( $client, $server ) = random_swap( $client, $server );
        print $client $line;
        is( <$server>, $line, "Line received" );
    }
    $client->close();
    is_closed( $server, 'peer' );
    $server->close();
}
