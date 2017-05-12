#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} };

use Test::More;
use Plack::Loader;
use File::Temp;
use IO::Socket::UNIX;
use Socket;

if ($^O eq 'MSWin32') {
    plan skip_all => 'UNIX socket tests on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

my ($fh, $filename) = File::Temp::tempfile(UNLINK=>1);
unlink($filename);

my $pid = fork;
if ( $pid == 0 ) {
    # server
    my $loader = Plack::Loader->load(
        'Starlight',
        quiet => 1,
        max_workers => 5,
        socket => $filename,
    );
    $loader->run(sub{
        my $env = shift;
        my $remote = $env->{REMOTE_ADDR} || 'UNIX';
        [200, ['Content-Type'=>'text/html'], ["HELLO $remote"]];
    });
    exit;
}

sleep 1;

my $client = IO::Socket::UNIX->new(
    Peer  => $filename,
    timeout => 3,
) or die "failed to listen to socket $filename:$!";

$client->syswrite("GET / HTTP/1.0\015\012\015\012");
$client->sysread(my $buf, 1024);
like $buf, qr/Starlight/;
like $buf, qr/HELLO UNIX/;

sleep 1;

done_testing();

kill 'TERM',$pid;
waitpid($pid,0);
unlink($filename);
