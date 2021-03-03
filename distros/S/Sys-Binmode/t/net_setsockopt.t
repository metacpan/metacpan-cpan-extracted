#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Socket;

socket my $s, AF_INET, SOCK_STREAM, 0;

my $rcvbuf_bin = getsockopt($s, SOL_SOCKET, SO_RCVBUF);

if (length $rcvbuf_bin == 4) {
    my $rcvbuf = unpack 'L', $rcvbuf_bin;
    my $rcvbuf_orig = $rcvbuf;

    my $newsize_bin = q<>;

    while ($rcvbuf > 0) {
        $rcvbuf--;
        $newsize_bin = pack 'L', $rcvbuf;

        last if $newsize_bin =~ tr<\x80-\xff><>;
    }

    if ($newsize_bin !~ tr<\x80-\xff><>) {
        plan skip_all => "Failed to reduce socket rcvbuf ($rcvbuf_orig) to contain a >127 byte.";
    }

    utf8::upgrade $newsize_bin;

    use Sys::Binmode;
    ok(
        setsockopt( $s, SOL_SOCKET, SO_RCVBUF, $newsize_bin ),
        'setsockopt with upgraded string - no failure',
    );

    my $rcvbuf_bin = getsockopt($s, SOL_SOCKET, SO_RCVBUF);
    my $rcvbuf2= unpack 'L', $rcvbuf_bin;

    if ($^O =~ m<linux>) {

        # Linux doubles the SO_RCVBUF that you give. (weird?)
        is( $rcvbuf2, 2 * $rcvbuf, 'setsockopt took effect');
    }
    else {
        is( $rcvbuf2, $rcvbuf, 'setsockopt took effect');
    }
}

done_testing;

1;
