use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use File::Spec::Functions;
use t::Util;

use Net::Proxy;

my @lines = (
    "oscar delta sierra echo papa\n",
    "Laurent_Fignon Henri_Pelissier Lucien_Petit_Breton Firmin_Lambot\n",
    "Toronto London Herzliya Melbourne Munich\n",
    "holy_icepicks holy_corpusles holy_Luthor_Burbank holy_hyperdermics\n",
    "Woody_Long Alicia_Rio Dorothy_Le_May Janine_Lindemulder Barbara_Summer\n",
);
my $tests = @lines;

my $all_tests = $tests + 1;
plan tests => $all_tests;

init_rand(@ARGV);

# lock 2 ports
my @free = find_free_ports(2);

SKIP: {
    eval { require IO::Socket::SSL; };
    skip 'IO::Socket::SSL required to test ssl', $all_tests if $@;
    skip 'Not enough available ports',           $all_tests if @free < 2;

    no warnings 'once';
    $IO::Socket::SSL::DEBUG = $ENV{NET_PROXY_VERBOSITY} || 0;

    my ( $proxy_port, $server_port ) = @free;
    my $pid = fork_proxy(
        {   in => {
                type    => 'tcp',
                host    => 'localhost',
                port    => $proxy_port,
                timeout => 1,
            },
            out => {
                type => 'ssl',
                host => 'localhost',
                port => $server_port,
            },
        }
    );

    skip 'proxy fork failed', $tests if !defined $pid;

    # wait for the proxy to set up
    sleep 1;

    # start a SSL server
    my $listener = IO::Socket::SSL->new(
        Listen        => 1,
        LocalAddr     => 'localhost',
        LocalPort     => $server_port,
        Proto         => 'tcp',
        SSL_cert_file => catfile( 't', 'test.cert' ),
        SSL_key_file  => catfile( 't', 'test.key' ),
    ) or skip "Couldn't start the server: $!", $tests;

    # start a client
    my $client = connect_to_port($proxy_port)
        or skip_fail "Couldn't start the client: $!", $tests;

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
