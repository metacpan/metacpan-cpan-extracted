#!/usr/bin/perl

# vim: set syntax=perl

use Test::More tests => 6;

BEGIN {
    use_ok 'Mojo::IOLoop';
    use_ok 'IO::AIO';
    use_ok 'MojoX::AIO';
}

use Fcntl qw( O_RDONLY );
use FindBin;
use bytes;

use strict;
use warnings;

my $loop = Mojo::IOLoop->singleton;

sub _start {
    my $file = $FindBin::Bin.'/../Makefile.PL';
    Test::More::pass("started, opening $file");

    aio_open( $file, O_RDONLY, 0, sub { open_done( $file, @_ ) });
}

sub open_done {
    my ( $file, $fh ) = @_;

    unless ( defined $fh ) {
        Test::More::fail("aio open failed on $file: $!");
        return $loop->stop;
    }

    Test::More::pass("opened $file, going to read");

    my $buffer = '';
    aio_read( $fh, 0, 1024, $buffer, 0, sub { read_done( $buffer, @_ ) } );
}

sub read_done {
    my ( $buffer, $bytes ) = @_;

    unless( $bytes > 0 ) {
        Test::More::fail("aio read failed: $!");
        return $loop->stop;
    }

    unless ( length $buffer == $bytes ) {
        Test::More::fail("buffer doesn't match byte count");
        return $loop->stop;
    }

    Test::More::pass("read file: $bytes bytes");

    $loop->stop;
}

$loop->timer( 1 => \&_start );
$loop->timer( 10 => sub { Test::More::fail("test timed out after 10s"); $loop->stop; });

$loop->start;

1;
