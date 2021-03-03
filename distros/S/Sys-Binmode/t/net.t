#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Socket;

plan skip_all => "This test needs UNIX sockets. (Unavailable via Socket.pm on $^O)" if !Socket->can('AF_UNIX');

plan skip_all => "Skipping on this OS ($^O)" if $^O !~ m<linux|darwin|bsd>;

use File::Temp;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

socket my $s, AF_UNIX, SOCK_STREAM, 0;

my $addr = Socket::pack_sockaddr_un("$dir/é");

utf8::upgrade($addr);

{
    use Sys::Binmode;
    bind $s, $addr;
}

ok(
    (-e "$dir/é"),
    'bind with upgraded string',
);

listen $s, 5;

socket my $c, AF_UNIX, SOCK_STREAM, 0;

utf8::upgrade($addr);

{
    use Sys::Binmode;

    ok(
        connect($c, $addr),
        'connect with upgraded string',
    );
}

done_testing;

1;
