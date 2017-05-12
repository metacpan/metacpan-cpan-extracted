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
    enable 'Deflater', content_type => 'text/html', vary_user_agent => 1;;
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] }
};
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        isnt $res->content_encoding, 'gzip';
        unlike $res->header('Vary') || '', qr/Accept-Encoding/;
        unlike $res->header('Vary') || '', qr/User-Agent/;
    };


## app2
my $app2 = builder {
    enable sub {
        my $cb = shift;
        sub {
            my $env = shift;
            $env->{HTTP_ACCEPT_ENCODING} =~ s/(gzip|deflate)//gi if $env->{HTTP_USER_AGENT} =~ m!^Mozilla/4! and $env->{HTTP_USER_AGENT} !~ m!\bMSIE\s(7|8)!;
            $cb->($env);
        }
    };
    enable 'Deflater', content_type => 'text/plain', vary_user_agent => 1;
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] }
};


## ua:lwp
test_psgi
    app => $app2,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        $req->accept_decodable;
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        is $res->content_encoding, 'gzip';
        like $res->header('Vary'), qr/Accept-Encoding/;
        like $res->header('Vary'), qr/User-Agent/;
    };

## ua:ie6 not gziped, vary:ua vary:ac will be added
test_psgi
    app => $app2,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        $req->accept_decodable;
        $req->user_agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 6.0; Trident/4.0)");
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        isnt $res->content_encoding, 'gzip';
        like $res->header('Vary'), qr/Accept-Encoding/;
        like $res->header('Vary'), qr/User-Agent/;
    };  

## ua:ie7 gziped
test_psgi
    app => $app2,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        $req->accept_decodable;
        $req->user_agent("Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; Trident/5.0)");
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        is $res->content_encoding, 'gzip';
        like $res->header('Vary'), qr/Accept-Encoding/;
        like $res->header('Vary'), qr/User-Agent/;
    };  

## ua:ie9 gziped
test_psgi
    app => $app2,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        $req->accept_decodable;
        $req->user_agent("Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)");
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        is $res->content_encoding, 'gzip';
        like $res->header('Vary'), qr/Accept-Encoding/;
        like $res->header('Vary'), qr/User-Agent/;
    };  


done_testing;
