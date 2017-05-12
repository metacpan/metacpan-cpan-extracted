#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} };

# workaround for HTTP::Tiny + Test::TCP
BEGIN { $INC{'threads.pm'} = 0 };
sub threads::tid { }

use Test::TCP;
use Plack::Test;
use File::ShareDir;
use File::Temp;
use HTTP::Request;
use Test::More;
use Digest::MD5;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

$Plack::Test::Impl = "Server";
$ENV{PLACK_SERVER} = 'Starlight';
$ENV{PLACK_QUIET} = 1;

my ($fh, $filename) = File::Temp::tempfile(UNLINK=>1);
ok $fh;
print $fh 'A' x 100_000;
close $fh;

my $app = sub {
    my $env = shift;
    my $body;
    my $clen = $env->{CONTENT_LENGTH};
    while ($clen > 0) {
        $env->{'psgi.input'}->read(my $buf, $clen) or last;
        $clen -= length $buf;
        $body .= $buf;
    }
    return [ 200, [ 'Content-Type', 'text/plain', 'X-Content-Length', $env->{CONTENT_LENGTH} ], [ $body ] ];
};

test_psgi $app, sub {
    my $cb = shift;
    sleep 1;

    open my $fh, "<:raw", $filename;
    local $/ = \1024;

    my $req = HTTP::Request->new(POST => "http://127.0.0.1/");
    $req->content(sub { scalar <$fh> });

    my $res = $cb->($req);

    is $res->header('X-Content-Length'), 100_000;
    is Digest::MD5::md5_hex($res->content), '5793f7e3037448b250ae716b43ece2c2';

    sleep 1;
};

done_testing;
