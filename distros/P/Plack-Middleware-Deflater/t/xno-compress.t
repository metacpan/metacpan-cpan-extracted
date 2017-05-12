use strict;
use Test::More;
use Test::Requires qw(IO::Handle::Util);
use IO::Handle::Util qw(:io_from);
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Plack::Middleware::Deflater;
$Plack::Test::Impl = "Server";

## content_type nomatch, no vary sets.
my $app = builder {
    enable sub {
        my $cb = shift;
        sub {
            my $env = shift;
            $env->{"psgix.no-compress"} = 1;
            $cb->($env);
        }
    };
    enable 'Deflater', content_type => 'text/html', vary_user_agent => 1;
    sub { [200, [ 'Content-Type' => 'text/html' ], [ "Hello World" ]] }
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        isnt $res->content_encoding, 'gzip';
        like $res->header('Vary') || '', qr/Accept-Encoding/;
        like $res->header('Vary') || '', qr/User-Agent/;
    };


my $app2 = builder {
    enable sub {
        my $cb = shift;
        sub {
            my $env = shift;
            $env->{"psgix.compress-only-text/html"} = 1;    
            $cb->($env);
        }
    };
    enable 'Deflater', content_type => 'text/plain', vary_user_agent => 1;
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] }
};

test_psgi
    app => $app2,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        isnt $res->content_encoding, 'gzip';
        like $res->header('Vary') || '', qr/Accept-Encoding/;
        like $res->header('Vary') || '', qr/User-Agent/;
    };


done_testing;

