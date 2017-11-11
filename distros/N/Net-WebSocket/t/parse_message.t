#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    eval 'use autodie';
}

use Test::More;
use Test::Deep;

use File::Slurp;
use File::Temp;

use IO::Framed ();

plan tests => 6;

use Net::WebSocket::Endpoint::Server ();
use Net::WebSocket::Parser ();

my $full_buffer;

(undef, my $out_path) = File::Temp::tempfile( CLEANUP => 1);

my @tests = (
    [
        "\x81\x06Hello\x0a",
        sub {
            cmp_deeply(
                $_,
                all(
                    Isa('Net::WebSocket::Message'),
                    methods(
                        get_type => 'text',
                        get_payload => "Hello\x0a",
                    ),
                ),
                'single hello - text',
            ) or diag explain $_;
        },
    ],
    [
        "\x82\x0dHello-binary\x0a",
        sub {
            cmp_deeply(
                $_,
                all(
                    Isa('Net::WebSocket::Message'),
                    methods(
                        get_type => 'binary',
                        get_payload => "Hello-binary\x0a",
                    ),
                ),
                'single hello - binary',
            ) or diag explain $_;
        },
    ],
    [
        "\x89\x0bHello-ping\x0a" . "\x82\x00",
        sub {
            open my $read_out_fh, '<', $out_path;

            my $io = IO::Framed->new($read_out_fh);
            my $out_parser = Net::WebSocket::Parser->new( $io );

            cmp_deeply(
                $out_parser->get_next_frame(),
                all(
                    Isa('Net::WebSocket::Frame'),
                    methods(
                        get_type => 'pong',
                        get_payload => "Hello-ping\x0a",
                    ),
                ),
                'hello - ping',
            ) or diag explain $_;
        },
    ],
    [
        "\x02\x06Hello\x0a" . "\x80\x06Hello\x0a",
        sub {
            cmp_deeply(
                $_,
                all(
                    Isa('Net::WebSocket::Message'),
                    methods(
                        get_type => 'binary',
                        get_payload => "Hello\x0aHello\x0a",
                    ),
                ),
                'fragmented double hello',
            ) or diag explain $_;
        },
    ],
    [
        "\x02\x06Hello\x0a" . "\x89\x00" . "\x80\x06Hello\x0a",
        sub {
            cmp_deeply(
                $_,
                all(
                    Isa('Net::WebSocket::Message'),
                    methods(
                        get_type => 'binary',
                        get_payload => "Hello\x0aHello\x0a",
                    ),
                ),
                'fragmented double hello with ping in the middle',
            ) or diag explain $_;

            open my $read_out_fh, '<', $out_path;

            my $io = IO::Framed->new($read_out_fh);
            my $out_parser = Net::WebSocket::Parser->new( $io );

            my $resp = $out_parser->get_next_frame();

            cmp_deeply(
                $resp,
                all(
                    Isa('Net::WebSocket::Frame'),
                    methods(
                        get_type => 'pong',
                        get_payload => q<>,
                        get_fin => 1,
                        is_control_frame => 1,
                        get_mask_bytes => q<>,
                    ),
                ),
                'ping in the middle gets a reply as expected',
            );
        },
    ],
);

(my $in_fh, my $in_path) = File::Temp::tempfile( CLEANUP => 1);
syswrite( $in_fh, $_->[0] ) for @tests;
close $in_fh;

open my $full_read_fh, '<', $in_path;

open my $out_fh, '>>', $out_path;

$out_fh->blocking(1);

my $io = IO::Framed->new( $full_read_fh, $out_fh );

my $parser = Net::WebSocket::Parser->new( $io );

my $ept = Net::WebSocket::Endpoint::Server->new(
    parser => $parser,
    out => $io,
);

for my $t (@tests) {
    truncate $out_fh, 0;

    my $msg;

    while (1) {
        $msg = $ept->get_next_message();
        last if $msg;
    }

    $t->[1]->() for $msg;
}
