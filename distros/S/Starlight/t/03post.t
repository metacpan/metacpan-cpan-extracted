#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} };

# workaround for HTTP::Tiny + Test::TCP
BEGIN { $INC{'threads.pm'} = 0 };
sub threads::tid { }

use HTTP::Tiny;
use Plack::Runner;
use Test::More;

use Test::TCP;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

if (not eval { HTTP::Tiny->VERSION(0.014) }) {
    plan skip_all => 'HTTP::Tiny >= 0.014 required';
    exit 0;
}

test_tcp(
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(
            qw(--server Starlight --env test --quiet --max-workers 0 --port), $port,
        );
        $runner->run(
            sub {
                my $env = shift;
                my $buf = '';
                        while (length($buf) != $env->{CONTENT_LENGTH}) {
                    my $rlen = $env->{'psgi.input'}->read(
                        $buf,
                        $env->{CONTENT_LENGTH} - length($buf),
                        length($buf),
                    );
                    last unless $rlen > 0;
                }
                return [
                    200,
                    [ 'Content-Type' => 'text/plain' ],
                    [ $buf ],
                ];
            },
        );
    },
    client => sub {
        my $port = shift;
        sleep 1;
        note 'send a broken request';
        my $sock = IO::Socket::INET->new(
            PeerAddr => "127.0.0.1:$port",
            Proto    => 'tcp',
        ) or die "failed to connect to server:$!";
        $sock->print(<< "EOT");
POST / HTTP/1.0\r
Content-Length: 6\r
\r
EOT
        undef $sock;
        note 'send next request';
        my $ua = HTTP::Tiny->new( timeout => 10 );
        my $res = $ua->post_form("http://127.0.0.1:$port/", { a => 1 });
        ok $res->{success};
        is $res->{status}, 200;
        is $res->{content}, 'a=1';
    },
);

done_testing;
