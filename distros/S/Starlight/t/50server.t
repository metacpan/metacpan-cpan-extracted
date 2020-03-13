#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} };

# workaround for HTTP::Tiny + Test::TCP
BEGIN { $INC{'threads.pm'} = 0 };
sub threads::tid { }

use HTTP::Tiny;
use Test::TCP;
use Test::More;

use Starlight::Server;

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
        my $ua = HTTP::Tiny->new;
        my $res = $ua->get("http://127.0.0.1:$port/");
        ok $res->{success};
        like $res->{headers}{server}, qr/Starlight/;
        like $res->{content}, qr/Hello/;
        sleep 1;
    },
    server => sub {
        my $port = shift;
        Starlight::Server->new(
            quiet    => 1,
            host     => '127.0.0.1',
            port     => $port,
        )->run(
            sub { [ 200, [], ["Hello world\n"] ] },
        );
    }
);

done_testing;
