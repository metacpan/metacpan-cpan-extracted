#!/usr/bin/env perl
# Bodies larger than one DATA frame arrive whole.
#
# A DATA frame carries at most SETTINGS_MAX_FRAME_SIZE bytes (16384 unless
# the peer raises it), and flow control may allow fewer; that limit is the
# $max_length a data callback is given. However a body is handed over (a
# static body, submit_data, or a callback returning more than $max_length),
# every byte is sent, over as many frames as it takes, and END_STREAM comes
# after the last of them.

use strict;
use warnings;
use Test::More;

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

plan skip_all => 'nghttp2 not available' unless Net::HTTP2::nghttp2->available;

# A server and a client in memory. The server records each request's stream
# and the request body; the client records each response's body, trailers,
# and the error code its stream closed with.
sub pair {
    my %seen = (body => {}, closed => {}, trailers => {}, request_body => {}, requests => []);
    my $server = Net::HTTP2::nghttp2::Session->new_server(callbacks => {
        on_begin_headers   => sub { 0 },
        on_header          => sub { 0 },
        on_frame_recv      => sub {
            my ($frame) = @_;
            push @{ $seen{requests} }, $frame->{stream_id}
                if $frame->{type} == 1 && ($frame->{flags} & 0x1);   # HEADERS ending the request
            push @{ $seen{requests} }, $frame->{stream_id}
                if $frame->{type} == 0 && ($frame->{flags} & 0x1);   # DATA ending the request
            0;
        },
        on_data_chunk_recv => sub { $seen{request_body}{ $_[0] } .= $_[1]; 0 },
        on_stream_close    => sub { 0 },
    });
    my $client = Net::HTTP2::nghttp2::Session->new_client(callbacks => {
        on_begin_headers   => sub { 0 },
        on_header          => sub { my ($sid, $n, $v) = @_; $seen{trailers}{$sid}{$n} = $v if $n !~ /^:/; 0 },
        on_frame_recv      => sub { 0 },
        on_data_chunk_recv => sub { $seen{body}{ $_[0] } .= $_[1]; 0 },
        on_stream_close    => sub { $seen{closed}{ $_[0] } = $_[1]; 0 },
    });
    $client->send_connection_preface;
    $server->send_connection_preface;
    pump($client, $server, sub { 0 }, 5);
    return ($server, $client, \%seen);
}

# Moves frames both ways until $done says so or nothing more moves.
sub pump {
    my ($client, $server, $done, $limit) = @_;
    for (1 .. ($limit // 100_000)) {
        my $sd = $server->mem_send; $client->mem_recv($sd) if length $sd;
        my $cd = $client->mem_send; $server->mem_recv($cd) if length $cd;
        return 1 if $done->();
        return 0 if !length $sd && !length $cd && $_ > 5;
    }
    return 0;
}

# A GET from the client; returns the stream the server sees it on.
sub get {
    my ($client, $server, $seen) = @_;
    my $sid = $client->submit_request(method => 'GET', path => '/', scheme => 'http', authority => 'localhost');
    pump($client, $server, sub { grep { $_ == $sid } @{ $seen->{requests} } });
    return $sid;
}

for my $size (16384, 16385, 65535, 70000, 1 << 20) {
    subtest "static body, $size bytes" => sub {
        my ($server, $client, $seen) = pair();
        my $sid = get($client, $server, $seen);
        $server->submit_response($sid, status => 200, headers => [], body => 'x' x $size);
        ok pump($client, $server, sub { exists $seen->{closed}{$sid} }), 'the stream closed';
        is $seen->{closed}{$sid}, 0, 'cleanly';
        is length($seen->{body}{$sid} // ''), $size, 'every byte arrived';
        ok(($seen->{body}{$sid} // '') eq 'x' x $size, 'unchanged');
    };
}

subtest 'a callback returning more than $max_length: nothing is lost' => sub {
    my ($server, $client, $seen) = pair();
    my $sid = get($client, $server, $seen);
    my @chunks = ('a' x 200_000, 'b' x 50_000);
    my ($calls, @max) = (0);
    $server->submit_response($sid, status => 200, headers => [], data_callback => sub {
        my ($stream_id, $max_length) = @_;
        $calls++;
        push @max, $max_length;
        my $chunk = shift @chunks;
        return ($chunk, @chunks ? 0 : 1);
    });
    ok pump($client, $server, sub { exists $seen->{closed}{$sid} }), 'the stream closed';
    is $seen->{closed}{$sid}, 0, 'cleanly';
    ok(($seen->{body}{$sid} // '') eq ('a' x 200_000) . ('b' x 50_000), 'both chunks, whole, in order');
    ok !(grep { $_ > 16384 } @max), 'each call was offered at most a frame';
    is $calls, 2, 'and the callback was called once per chunk, not once per frame';
};

subtest 'a callback returning more than $max_length, then trailers' => sub {
    my ($server, $client, $seen) = pair();
    my $sid = get($client, $server, $seen);
    my $sent = 0;
    $server->submit_response($sid, status => 200, headers => [], data_callback => sub {
        return if $sent++;
        return ('t' x 100_000, 1, 1);   # the end of the body, END_STREAM saved for the trailers
    });
    pump($client, $server, sub { length($seen->{body}{$sid} // '') >= 100_000 });
    $server->submit_trailer($sid, headers => [['x-checksum', 'abc']]);
    ok pump($client, $server, sub { exists $seen->{closed}{$sid} }), 'the stream closed';
    is $seen->{closed}{$sid}, 0, 'cleanly';
    is length($seen->{body}{$sid} // ''), 100_000, 'the whole body';
    is $seen->{trailers}{$sid}{'x-checksum'}, 'abc', 'then the trailers';
};

subtest 'submit_data with more than a frame' => sub {
    my ($server, $client, $seen) = pair();
    my $sid = get($client, $server, $seen);
    $server->submit_response($sid, status => 200, headers => [], data_callback => sub { return });
    pump($client, $server, sub { 0 }, 5);
    $server->submit_data($sid, 'd' x (1 << 20), 1);
    ok pump($client, $server, sub { exists $seen->{closed}{$sid} }), 'the stream closed';
    is $seen->{closed}{$sid}, 0, 'cleanly';
    is length($seen->{body}{$sid} // ''), 1 << 20, 'every byte arrived';
};

subtest 'submit_data again before the last has all gone: both are sent' => sub {
    my ($server, $client, $seen) = pair();
    my $sid = get($client, $server, $seen);
    $server->submit_response($sid, status => 200, headers => [], data_callback => sub { return });
    pump($client, $server, sub { 0 }, 5);
    $server->submit_data($sid, 'e' x 100_000, 0);
    my $sd = $server->mem_send;   # sends what the window allows, the rest still waiting
    $client->mem_recv($sd);
    $server->submit_data($sid, 'f' x 10, 1);
    ok pump($client, $server, sub { exists $seen->{closed}{$sid} }), 'the stream closed';
    ok(($seen->{body}{$sid} // '') eq ('e' x 100_000) . ('f' x 10), 'the first, whole, then the second');
};

subtest 'a client request body of more than a frame' => sub {
    my ($server, $client, $seen) = pair();
    my $sid = $client->submit_request(method => 'POST', path => '/', scheme => 'http',
        authority => 'localhost', body => 'r' x (1 << 20));
    ok pump($client, $server, sub { grep { $_ == $sid } @{ $seen->{requests} } }), 'the request ended';
    is length($seen->{request_body}{$sid} // ''), 1 << 20, 'every byte arrived';
};

done_testing;
