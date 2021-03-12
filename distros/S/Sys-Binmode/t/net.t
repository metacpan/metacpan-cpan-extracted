#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Socket;

plan skip_all => "This test needs UNIX sockets. (Unavailable via Socket.pm on $^O)" if !Socket->can('AF_UNIX');

plan skip_all => "Skipping on this OS ($^O)" if $^O !~ m<linux|darwin|bsd>;

$| = 1;

use File::Temp;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

socket my $s, AF_UNIX, SOCK_STREAM, 0 or do {
    plan skip_all => "Failed to create local socket: $!";
};

_can_bind_unix() or plan skip_all => "Can’t bind to a local socket.";

my $addr = Socket::pack_sockaddr_un("$dir/é");

utf8::upgrade($addr);

{
    use Sys::Binmode;
    bind $s, $addr or warn "bind: $!";
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

    my $ok = connect($c, $addr) or warn "connect: $!";

    # NB: This hangs on Cygwin, assumedly because it’s using an IP socket
    # under the hood rather than a real local socket.
    ok(
        $ok,
        'connect with upgraded string',
    );
}

done_testing;

#----------------------------------------------------------------------

sub _can_bind_unix {
    socket my $s, AF_UNIX, SOCK_STREAM, 0 or die "socket: $!";

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $test_addr = "$dir/haha";

    bind $s, Socket::pack_sockaddr_un($test_addr) or do {
        diag "bind($test_addr): $!";
        return 0;
    };

    return 1;
}

1;
