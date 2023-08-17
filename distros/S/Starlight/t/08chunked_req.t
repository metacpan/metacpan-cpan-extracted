#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} }

use Digest::MD5;
use File::ShareDir;
use File::Temp;
use HTTP::Request;
use LWP::UserAgent;
use Test::More;
use Test::TCP;

use Starlight::Server;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Broken on cygwin';
    exit 0;
}

my ($fh, $filename) = File::Temp::tempfile(UNLINK => 1);
ok $fh, '$fh';
print $fh 'A' x 100_000;
close $fh;

test_tcp(
    client => sub {
        my $port = shift;

        my $status = open my $fh, '<:raw', $filename;
        ok $status, 'open';

        local $/ = \1024;

        sleep 1;

        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        my $req = HTTP::Request->new(POST => "http://127.0.0.1:$port/");
        $req->headers->remove_header('Content-Length');
        $req->content(sub { scalar <$fh> });
        my $res = $ua->request($req);

        close $fh;

        ok $res->is_success, 'is_success';
        is $res->code, '200', 'code';
        is $res->message, 'OK', 'message';
        is $res->header('x-content-length'), 100_000, 'length';
        is Digest::MD5::md5_hex($res->content), '5793f7e3037448b250ae716b43ece2c2', 'content';
        like $res->content, qr/^A{25000}A{25000}A{25000}A{25000}$/, 'content';

        sleep 1;
    },
    server => sub {
        my $port = shift;
        Starlight::Server->new(
            quiet => 1,
            host  => '127.0.0.1',
            port  => $port,
            ipv6  => 0,
        )->run(
            sub {
                my $env = shift;
                my $body;
                eval {
                    my $clen = $env->{CONTENT_LENGTH};
                    while ($clen > 0) {
                        $env->{'psgi.input'}->read(my $buf, $clen) or last;
                        $clen -= length $buf;
                        $body .= $buf;
                    }
                    1;
                } or $body = $@;
                return [200, ['Content-Type', 'text/plain', 'X-Content-Length', $env->{CONTENT_LENGTH}], [$body]];
            }
        );
    },
);

done_testing;
