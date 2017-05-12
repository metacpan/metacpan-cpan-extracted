use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use File::Spec::Functions;
use t::Util;

use Net::Proxy;

my @lines = (
    "pete_peters sophie les mr_dork vijay\n",
    "d_fence abacus_remote ups_onlinet d2k_datamover2 ssslog_mgr\n",
    "Scooby_Doo Velma Freddy Daphne Shaggy\n",
    "STARTTLS\n",
    "Brian Florence Dougal Ermintrude Zebedee\n",
    "ale sherry cider wine whiskey\n",
    "Arcadio The_Witch_of_Kaan Drumm Rufferto Gravito\n",
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
                type            => 'ssl',
                port            => $proxy_port,
                timeout         => 1,
                start_cleartext => 1,
                SSL_cert_file   => catfile( 't', 'test.cert' ),
                SSL_key_file    => catfile( 't', 'test.key' ),
                hook            => sub {
                    my ( $dataref, $sock, $connector ) = @_;
                    if ( $$dataref =~ s/^STARTTLS\n// ) {
                        print $sock "OK\n";
                        $connector->upgrade_SSL($sock);
                    }
                },
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
    my $client = connect_to_port($proxy_port)
        or skip "Couldn't start the client: $!", $tests;
    my $server = $listener->accept()
        or skip "Proxy didn't connect: $!", $tests;

    # remember which was the original client
    my $o_client = $client;

    # exchange the data
    for my $line (@lines) {
        ( $client, $server ) = random_swap( $client, $server );
        if ( $line eq "STARTTLS\n" ) {
            print $o_client $line;
            is( <$o_client>, "OK\n", "STARTTLS acknowledged" );
            IO::Socket::SSL->start_SSL($o_client);
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
