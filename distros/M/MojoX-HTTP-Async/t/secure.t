package main;

use 5.020;
use utf8;
use strict;
use warnings;
use experimental qw/ signatures /;
use bytes ();

use lib 'lib/', 't/lib';

use Test::More ('import' => [qw/ done_testing is ok use_ok note diag /]);
use Test::Utils qw/ start_server notify_parent /;

use Time::HiRes qw/ sleep /;
use IO::Socket::SSL qw/ SSL_VERIFY_NONE /;
use FindBin qw/ $Bin /;
use Mojo::Message::Request ();

my $host = '127.0.0.1';
my $processed_slots = 0;
my $wait_timeout = 12;
my $request_timeout = 7.2;
my $connect_timeout = 6;
my $inactivity_timeout = 6.5;
my $can_go_further = 0;

BEGIN { use_ok('MojoX::HTTP::Async') };

sub on_start_cb ($port) {
    my $QUEUE_LENGTH = 3;
    my $socket = IO::Socket::SSL->new(
        'LocalAddr' => $host,
        'LocalPort' => $port,
        'Listen'    => $QUEUE_LENGTH,
        'SSL_cert_file' => "${Bin}/certs/server-cert.pem",
        'SSL_key_file' => "${Bin}/certs/server-key.pem",
        'SSL_passwd_cb' => sub { 1234 },
    ) or die "Can't create socket: $!";

    my $default_response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
    my %responses_by_request_number = (
        '01' => "HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n0123456789",
        '02' => "HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n9876543210",
    );

    notify_parent();

    while (1) {

        my $pid;
        my $client = $socket->accept();

        die("failed to accept or SSL handshake: ${!}, ${IO::Socket::SSL::SSL_ERROR}") if $!;
        sleep(0.1) && next if !$client;

        if ($pid = fork()) { # parent
            sleep(0.05);
        } elsif ($pid == 0) { # child
            close($socket);

            local $| = 1; # autoflush

            my $rh = '';
            vec($rh, fileno($client), 1) = 1;
            my ($wh, $eh) = ($rh) x 2;

            select($rh, undef, $eh, undef);

            die($!) if ( vec($eh, fileno($client), 1) != 0 );

            my $data = <$client>; # GET /page/01.html HTTP/1.1
            my ($page) = (($data // '') =~ m#^[A-Z]{3,}\s/page/([0-9]+)\.html#);
            my $response = $default_response;

            $response = $responses_by_request_number{$page} // $response if $page;

            $eh = $wh;

            select(undef, $wh, $eh, undef);

            die($!) if ( vec($eh, fileno($client), 1) != 0 );

            my $bytes = syswrite($client, $response, bytes::length($response), 0);

            warn("Can't send the response") if $bytes != bytes::length($response);

            sleep(0.1);
            close($client);
            exit(0);
        } else {
            die("Can't fork: $!");
        }
    }
}


my $server = start_server(\&on_start_cb, $host);
my $ua = MojoX::HTTP::Async->new(
    'host' => $host,
    'port' => $server->port,
    'slots' => 2,
    'connect_timeout' => $connect_timeout,
    'request_timeout' => $request_timeout,
    'ssl' => 1,
    'ssl_opts' => {
        'SSL_verify_mode' => &SSL_VERIFY_NONE,
    },
    'sol_socket' => {},
    'sol_tcp' => {},
    'inactivity_conn_ts' => $inactivity_timeout,
);

my $mojo_request = Mojo::Message::Request->new();

$mojo_request->parse("POST /page/01.html HTTP/1.1\r\nContent-Length: 3\r\nHost: localhost\r\nUser-Agent: Test\r\n\r\nabc");

eval { $ua->_make_connections(1); };

if ($@ && $@ =~ m/\QConnection refused\E/i) {
    note("1..0 # Skipped: can't connect to the test SSL server");
    diag("1..0 # Skipped: can't connect to the test SSL server");
    done_testing();
    $server->stop();
    exit;
}

ok( $ua->add($mojo_request), "Adding the first request");
ok( $ua->add("/page/02.html"), "Adding the second request");
ok(!$ua->add("/page/03.html"), "Adding the third request");

# non-blocking requests processing
while ( $ua->not_empty() ) {
    if (my $tx = $ua->next_response) { # returns an instance of Mojo::Transaction::HTTP class
        my $res = $tx->res();
        $processed_slots++;
        is($res->headers()->to_string(), 'Content-Length: 10', "checking the response headers");
        is($res->code(), '200', 'checking the response code');
        is($res->message(), 'OK', 'checking the response message');
        if ($tx->req()->url() =~ m#/01\.html$#) {
            is($res->body(), '0123456789', "checking the response body");
        } else {
            is($res->body(), '9876543210', "checking the response body");
        }
    } else {
        # waiting for a response
    }
}

is($processed_slots, 2, "checking the amount of processed slots");

done_testing();

$server->stop();

1;
__END__
