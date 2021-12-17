package main;

use 5.020;
use utf8;
use strict;
use warnings;
use experimental qw/ signatures /;
use bytes ();

use lib 'lib/', 't/lib';

use Test::More ('import' => [qw/ done_testing is ok use_ok like /]);
use Test::Utils qw/ get_listen_socket start_server notify_parent /;

use Time::HiRes qw/ sleep /;


my $slots = 2;
my $host = 'localhost';
my $request_timeout = 1.5;
my $connect_timeout = 3;
my $wait_timeout = 3.5;

BEGIN { use_ok('MojoX::HTTP::Async') };

sub on_start_cb ($port) {

    my $client;
    my $socket = get_listen_socket($host, $port);

    notify_parent();

    while (my $peer = accept($client, $socket)) {

        my $pid;

        if ($pid = fork()) { # parent
            sleep(0.05);
        } elsif ($pid == 0) { # child
            close($socket);
            sleep($request_timeout + 0.5);
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
);

ok($ua->add("/page/01.html"), "Adding the first request");

# blocking requests processing
while (my $tx = $ua->wait_for_next_response($wait_timeout)) {
    my $res = $tx->res();
    is($res->body(), '', "checking the response body");
    like($res->message(), qr/^(Connection reset by peer|Request timeout)$/, 'checking the response message');
    ok($res->code() == 524 || $res->code() == 520, 'checking the response code');
}

done_testing();

$ua->close_all();
$server->stop();

1;
__END__
