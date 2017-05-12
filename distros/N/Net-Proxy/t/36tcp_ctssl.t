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
    "STARTTLS\n",
    "barkhausen schoenmaker sferics knoop fenice\n",
    "holy_icepicks holy_corpusles holy_Luthor_Burbank holy_hyperdermics\n",
    "STARTTLS\n",
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
                type            => 'ssl',
                host            => 'localhost',
                port            => $server_port,
                start_cleartext => 1,
                hook            => sub {
                    my ( $dataref, $sock, $connector ) = @_;
                    if ( $$dataref =~ s/^STARTTLS\n// ) {
                        print $sock "OK\n";
                        $connector->upgrade_SSL($sock);
                    }
                },
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
    my $client = connect_to_port($proxy_port)
        or skip_fail "Couldn't start the client: $!", $tests;

    my $server = $listener->accept()
        or skip "Proxy didn't connect: $!", $tests;

    # remember which was the original server
    my $o_server = $server;
    my $is_ssl   = 0;

    for my $line (@lines) {
        ( $client, $server ) = random_swap( $client, $server );
        if ( $line eq "STARTTLS\n" ) {
            print $o_server $line;
            is( <$o_server>, "OK\n", "STARTTLS acknowledged" );
            IO::Socket::SSL->start_SSL(
                $o_server,
                SSL_server    => 1,
                SSL_cert_file => catfile( 't', 'test.cert' ),
                SSL_key_file  => catfile( 't', 'test.key' ),

            ) if !$is_ssl++;    # do not upgrade twice
        }
        else {
            print $client $line;
            is( <$server>, $line, "Line received" );
        }
    }

    $client->close();
    is_closed( $server, 'peer' );
    $server->close();
}
