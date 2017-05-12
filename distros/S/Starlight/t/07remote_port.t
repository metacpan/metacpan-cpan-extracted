#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} };

# workaround for HTTP::Tiny + Test::TCP
BEGIN { $INC{'threads.pm'} = 0 };
sub threads::tid { }

use Test::More;
use Test::TCP;
use IO::Socket::INET;
use Plack::Loader;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

test_tcp(
    client => sub {
        my $port = shift;
        sleep 1;
        my $sock = IO::Socket::INET->new(
            PeerAddr => "127.0.0.1:$port",
            Proto => 'tcp',
        );
        ok($sock);
        my $localport = $sock->sockport;
        my $req = "GET / HTTP/1.0\015\012\015\012";
        $sock->syswrite($req,length($req));
        $sock->sysread( my $buf, 1024);
        like( $buf, qr/HELLO $localport/);
        sleep 1;
    },
    server => sub {
        my $port = shift;
        my $loader = Plack::Loader->load(
            'Starlight',
            quiet => 1,
            port => $port,
            max_workers => 5,
        );
        $loader->run(sub{
            my $env = shift;
            my @headers = ();
            my $remote_port = $env->{REMOTE_PORT};
            [200, ['Content-Type'=>'text/html'], ['HELLO '.$remote_port]];
        });
        exit;
    },
);

done_testing;
