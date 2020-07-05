#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Sys::Pipe;

use Errno;
use Fcntl;

use IO::File;

SKIP: {
    skip "No pipe2 support (OS = $^O)", 1 if !Sys::Pipe::has_pipe2();

    Sys::Pipe::pipe( my ($r, $w), Fcntl::O_NONBLOCK() ) or die "pipe(): $!";

    ok( !$r->blocking(), 'non-blocking from the get-go' );
}

done_testing();
