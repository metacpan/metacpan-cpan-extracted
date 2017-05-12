#!/usr/bin/env perl

use Test::More tests => 8;
BEGIN { use_ok('RTSP::Client') };

# to test, pass url of an RTSP server in $ENV{RTSP_CLIENT_TEST_URI}
# e.g.   RTSP_CLIENT_TEST_URI="rtsp://foo:bar@10.0.1.105:554/mpeg4/media.amp" perl -Ilib t/RTSP-Client.t
my $uri = $ENV{RTSP_CLIENT_TEST_URI};

SKIP: {
    skip "No RTSP server URI provided for testing", 7 unless $uri;
    
    # parse uri
    my $client = RTSP::Client->new_from_uri(uri => $uri, client_port_range => '6970-6971');
    skip "Invalid RTSP server URI provided for testing", 7 unless $client;

    $client->open or die $!;
    pass("opened connection to RTSP server");
    
    my @public_options = $client->options_public;
    ok(@public_options, "got public allowed methods: " . join(', ', @public_options));
    
    $client = RTSP::Client->new_from_uri(uri => $uri, client_port_range => '6970-6971');
    ok($client->describe, "got SDP info");
    $client->reset;
    
    ok($client->setup, "setup");
    ok($client->play, "play");
        
    # it's ok if these return 405 (method not allowed)
    {
        my $status;

        $client->pause;
        $status = $client->status;
        ok(($status == 200 || $status == 405), "pause");
    }
    
    ok($client->teardown, "teardown");
};

