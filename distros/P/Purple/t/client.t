#/usr/local/bin/perl

# Make the test as the stub at the client

use strict;
use warnings;
use Test::More;
use LWP::UserAgent;
use HTTP::Request;
use Purple::Server;
use URI::Escape;
use Purple::Client;

my $PORT       = 9999;
my $SERVER_URL = "http://localhost:$PORT";

plan tests => 10;

unlink('t/purple.db') || unlink('purple.db');
my $server = get_server();
$server->setup();
my $pid = $server->background() or die "unable to start purple server";
my $client_net = {server_url => $SERVER_URL};
my $client_lib = {store => 't'};

foreach my $client ($client_net, $client_lib) {
    # clean up data
    if ($client->{store}) {
        unlink('t/purple.db') || unlink('purple.db');
    }
    $client = Purple::Client->new(%$client);
    my $url = 'http://www.example.com/url_one';

    my $new_nid = $client->getNext($url);

    is( $new_nid, '1', 'initial nid on clear should be 1' );

    my $retrieved_nid = $client->getNIDs($url);

    is(
        $new_nid, $retrieved_nid,
        'generated nid and retrieved nid should be the same'
    );

    my $retrieved_url = $client->getURL($new_nid);
    is(
        $retrieved_url, $url,
        'retrieved url should be the same as the provide'
    );

    my $new_url  = 'http://www.example.com/url_two';
    my $response = $client->updateURL( $new_url, $retrieved_nid );

    ok( $response, 'updateURL returned true' );

    $response = $client->deleteNIDs( $new_nid );

    ok( $response, 'deleteNIDs returned true' );
}
kill 15, $pid and diag "killed server on $pid";

sub get_server {
    my $server
        = Purple::Server->new( port => $PORT, store => 't' );

    return $server;
}

END {
    kill 15, $pid if defined $pid;
}
