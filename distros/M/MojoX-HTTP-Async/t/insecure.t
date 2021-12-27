package main;

use 5.020;
use utf8;
use strict;
use warnings;
use experimental qw/ signatures /;
use bytes ();

use lib 'lib/', 't/lib';

use Test::More ('import' => [qw/ done_testing is ok use_ok like /]);
use Test::Utils qw/ get_listen_socket start_server notify_parent IS_NOT_WIN_AND_NOT_MACOS /;

use Time::HiRes qw/ sleep /;
use Mojo::Message::Request ();
use Mojo::URL ();


my $slots = 2;
my $host = 'localhost';
my $processed_slots = 0;
my $wait_timeout = 12;
my $request_timeout = 7.2;
my $connect_timeout = 6;

BEGIN { use_ok('MojoX::HTTP::Async') };

sub on_start_cb ($port) {

    my $client;
    my $socket = get_listen_socket($host, $port);
    my $default_response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
    my %responses_by_request_number = (
        '01' => "HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n0123456789",
        '02' => "HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n9876543210",
        '05' => "HTTP/1.1 200 OK\r\nContent-Length: 15\r\n\r\nHello, world!!!",
    );

    notify_parent();

    while (my $peer = accept($client, $socket)) {

        my $pid;

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

            if ($page && ($page eq '06' || $page eq '07' || $page eq '08')) { # tests for request timeouts
                sleep($request_timeout + 0.75);
            }

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
    'port' => $server->port(),
    'slots' => $slots,
    'connect_timeout' => $connect_timeout,
    'request_timeout' => $request_timeout,
    'ssl' => 0,
    &IS_NOT_WIN_AND_NOT_MACOS() ? (
        'sol_socket' => {'so_keepalive' => 1},
        'sol_tcp' => {
            'tcp_keepidle' => 15,
            'tcp_keepintvl' => 3,
            'tcp_keepcnt' => 2,
        }
    ) : (),
);

my $mojo_request = Mojo::Message::Request->new();

$mojo_request->parse("POST /page/01.html HTTP/1.1\r\nContent-Length: 3\r\nHost: localhost\r\nUser-Agent: Test\r\n\r\nabc");

ok( $ua->add($mojo_request), "Adding the first request");
ok( $ua->add(Mojo::URL->new("/page/02.html")), "Adding the second request");
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

# all connections were closed in Test::TCP after the response is sent
# but we don't know about this, so our new request will be timeouted

ok($ua->add("/page/04.html"), "Adding the fourth request");

$processed_slots = 0;

# blocking requests processing
while (my $tx = $ua->wait_for_next_response($wait_timeout)) {
    $processed_slots++;
    my $res = $tx->res();
    is($res->body(), '', "checking the response body");
    like($res->message(), qr/^(Connection reset by peer|Request timeout)$/, 'checking the response message');
    ok($res->code() == 524 || $res->code() == 520, 'checking the response code');
}

is($processed_slots, 1, "checking the amount of processed slots");

$ua->close_all();

$processed_slots = 0;

# one slot is OK, one slot is time-outed

ok($ua->add("/page/05.html"), "Adding the fifth request");
ok($ua->add("/page/06.html"), "Adding the sixth request");

while (my $tx = $ua->wait_for_next_response($wait_timeout)) {
    $processed_slots++;
    my $res = $tx->res();
    if ($tx->req()->url() =~ m#/05\.html$#) {
        is($res->body(), 'Hello, world!!!', "checking the response body");
        is($res->message(), 'OK', 'checking the response message');
    } else {
        is($res->body(), '', "checking the response body");
        is($res->message(), 'Request timeout', 'checking the response message');
    }
}

is($processed_slots, 2, "checking the amount of processed slots");

$ua->close_all();

$processed_slots = 0;

# all slots are timeouted

ok($ua->add("/page/07.html"), "Adding the seventh request");
ok($ua->add("/page/08.html"), "Adding the eight request");

while (my $tx = $ua->wait_for_next_response($wait_timeout)) {
    $processed_slots++;
    my $res = $tx->res();
    is($res->body(), '', "checking the response body");
    is($res->message(), 'Request timeout', 'checking the response message');
}

is($processed_slots, 2, "checking the amount of processed slots");

ok(! $ua->add("/page/09.html"), "Adding the nineth request");

# let's cleanup timeouted connections

$processed_slots = 0;

$ua->refresh_connections();

ok($ua->add("/page/10.html"), "Adding the tenth request");

while (my $tx = $ua->wait_for_next_response($wait_timeout)) {
    $processed_slots++;
}

is($processed_slots, 1, "checking the amount of processed slots");

done_testing();

$server->stop();

1;
__END__
