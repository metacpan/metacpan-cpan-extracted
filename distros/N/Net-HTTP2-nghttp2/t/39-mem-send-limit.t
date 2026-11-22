#!/usr/bin/env perl
# mem_send($max_bytes) returns at most $max_bytes; the rest stays in nghttp2.
#
# A server that writes to a socket it cannot always write to keeps its own
# output buffer small by asking nghttp2 only for what fits. Whatever does not
# fit stays queued in the session, want_write stays true, and a later call
# takes it. Without an argument mem_send returns everything ready, as before.

use strict;
use warnings;
use Test::More;

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

plan skip_all => 'nghttp2 not available' unless Net::HTTP2::nghttp2->available;

# A server and a client in memory. The server records each request's stream;
# the client records each response's body and the error code its stream
# closed with.
sub pair {
    my %seen = (body => {}, closed => {}, requests => []);
    my $server = Net::HTTP2::nghttp2::Session->new_server(callbacks => {
        on_begin_headers   => sub { 0 },
        on_header          => sub { 0 },
        on_frame_recv      => sub {
            my ($frame) = @_;
            push @{ $seen{requests} }, $frame->{stream_id}
                if $frame->{type} == 1 && ($frame->{flags} & 0x1);   # HEADERS ending the request
            0;
        },
        on_data_chunk_recv => sub { 0 },
        on_stream_close    => sub { 0 },
    });
    my $client = Net::HTTP2::nghttp2::Session->new_client(callbacks => {
        on_begin_headers   => sub { 0 },
        on_header          => sub { 0 },
        on_frame_recv      => sub { 0 },
        on_data_chunk_recv => sub { $seen{body}{ $_[0] } .= $_[1]; 0 },
        on_stream_close    => sub { $seen{closed}{ $_[0] } = $_[1]; 0 },
    });
    $client->send_connection_preface;
    $server->send_connection_preface;
    pump($client, $server, sub { 0 }, undef, 5);
    return ($server, $client, \%seen);
}

# Moves frames both ways until $done says so or nothing more moves. With
# $limit, the server's output is taken $limit bytes at a time, and every
# chunk's length is recorded in @$sizes.
sub pump {
    my ($client, $server, $done, $limit, $max_rounds, $sizes) = @_;
    for (1 .. ($max_rounds // 1_000_000)) {
        my $sd = defined $limit ? $server->mem_send($limit) : $server->mem_send;
        push @$sizes, length $sd if $sizes && length $sd;
        $client->mem_recv($sd) if length $sd;
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

for my $limit (16384, 7) {
    subtest "a 1 MiB body read $limit bytes at a time" => sub {
        my ($server, $client, $seen) = pair();
        my $sid = get($client, $server, $seen);
        my $size = 1 << 20;
        $server->submit_response($sid, status => 200, headers => [], body => 'x' x $size);
        my @sizes;
        ok pump($client, $server, sub { exists $seen->{closed}{$sid} }, $limit, undef, \@sizes), 'the stream closed';
        is $seen->{closed}{$sid}, 0, 'cleanly';
        is length($seen->{body}{$sid} // ''), $size, 'every byte arrived';
        ok(($seen->{body}{$sid} // '') eq 'x' x $size, 'unchanged');
        my @over = grep { $_ > $limit } @sizes;
        is scalar(@over), 0, "no call returned more than $limit bytes";
        ok((grep { $_ == $limit } @sizes), "calls returned a full $limit bytes");
    };
}

subtest 'what does not fit stays queued, and want_write says so' => sub {
    my ($server, $client, $seen) = pair();
    my $sid = get($client, $server, $seen);
    $server->submit_response($sid, status => 200, headers => [], body => 'x' x 70000);
    my $first = $server->mem_send(16384);
    is length $first, 16384, 'the first call returns exactly the limit';
    ok $server->want_write, 'want_write is true while output remains';
    $client->mem_recv($first);
    ok pump($client, $server, sub { exists $seen->{closed}{$sid} }, 16384), 'later calls take the rest';
    is length($seen->{body}{$sid} // ''), 70000, 'every byte arrived';
};

subtest 'no limit: everything ready in one call, as before' => sub {
    my ($server, $client, $seen) = pair();
    my $sid = get($client, $server, $seen);
    $server->submit_response($sid, status => 200, headers => [], body => 'x' x 70000);
    my $all = $server->mem_send;
    cmp_ok length $all, '>', 16384, 'one call returns more than one frame';
    $client->mem_recv($all);
    ok pump($client, $server, sub { exists $seen->{closed}{$sid} }), 'the stream closed';
    is length($seen->{body}{$sid} // ''), 70000, 'every byte arrived';
};

subtest 'a limit must be a positive whole number of bytes' => sub {
    my ($server) = pair();
    for my $bad (0, -1, 1.5, 'abc') {
        eval { $server->mem_send($bad) };
        like $@, qr/mem_send's limit must be a positive number of bytes/, "mem_send('$bad') croaks";
    }
};

done_testing;
