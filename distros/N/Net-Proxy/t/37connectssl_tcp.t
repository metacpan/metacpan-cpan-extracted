use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use File::Spec::Functions;
use t::Util;

use Net::Proxy;

my @lines = (
    "saturday wednesday tuesday sunday friday\n",
    "agnes_nitt granny_weatherwax greebo vorbis jason_ogg\n",
    "Moins Scrof Ferla_Quist Caine Grove_Of_The_Unicorn\n",
    "rook pawn queen king bishop\n",
    "Fedora QiLinux gnuLinEx ZoneCD ROSLIMS\n",
);
my $tests = @lines + 3;

init_rand(@ARGV);

plan tests => $tests;

SKIP: {

    # check required modules for this test case
    for my $module (qw( LWP::UserAgent HTTP::Daemon IO::Socket::SSL )) {
        eval "require $module;";
        skip "$module required to test connect_ssl", $tests if $@;
    }

    # lock 2 ports
    my @free = find_free_ports(2);
    skip "Not enough available ports", $tests if @free < 2;

    my ( $proxy_port, $web_proxy_port ) = @free;
    my $pid = fork_proxy(
        {   in => {
                type => 'tcp',
                host => 'localhost',
                port => $proxy_port
            },
            out => {
                type       => 'connect_ssl',
                host       => 'zlonk.crunch.com',
                port       => 443,
                proxy_host => 'localhost',
                proxy_port => $web_proxy_port,
            },
        },
        2
    );

    skip "fork failed", $tests if !defined $pid;

    # wait for the proxy to set up
    sleep 1;

    # the parent process does the testing
    my $daemon = HTTP::Daemon->new(
        LocalAddr => 'localhost',
        LocalPort => $web_proxy_port,
    ) or skip "Couldn't start the server: $!", $tests;
    my $client = connect_to_port($proxy_port)
        or skip_fail "Couldn't start the client: $!", $tests;
    my $server = $daemon->accept()
        or skip_fail "Proxy didn't connect: $!", $tests;

    # the server will first play the role of the web proxy,
    # and after a 200 OK will also act as a real server

    # check the request
    my $req = $server->get_request();
    is( $req->method(), 'CONNECT', 'Proxy did a CONNECT' );
    is( $req->uri()->host_port(), 'zlonk.crunch.com:443', 'host:port' );

    # first time, the web proxy says 200
    $server->send_response( HTTP::Response->new('200') );

    # now the client will use SSL
    IO::Socket::SSL->start_SSL(
        $server,
        SSL_server    => 1,
        SSL_cert_file => catfile( 't', 'test.cert' ),
        SSL_key_file  => catfile( 't', 'test.key' ),
    );

    # send some data through
    # FIXME this blocks when $server speaks first
    for my $line (@lines) {
        print $client $line;
        is( <$server>, $line, "Line received" );
        ( $client, $server ) = random_swap( $client, $server );
    }
    $client->close();
    $server->close();

    # second time, the web proxy says 403 (how to test this?)
    $client = connect_to_port($proxy_port)
        or skip_fail "Couldn't start the client: $!", 1;
    $server = $daemon->accept()
        or skip_fail "Proxy didn't connect: $!", 1;

    $server->get_request();    # ignore it
    $server->send_response( HTTP::Response->new('403') );
    is_closed($client);
}
