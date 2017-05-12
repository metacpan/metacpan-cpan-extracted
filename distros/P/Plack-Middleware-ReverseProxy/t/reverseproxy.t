use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 39;

use Plack::Builder;
use Plack::Test;
use Plack::Request;
use HTTP::Headers;
use HTTP::Request;
use Data::Dumper;

sub run {
    my ($tag, $block) = @_;
    my %input = map { split /: ?/, $_, 2  } split /\r?\n/, $block->{input};

    my $headers = HTTP::Headers->new;
    $headers->header( %input );

    my $handler = builder {
        enable 'Plack::Middleware::MangleEnv', %input;
        enable 'Plack::Middleware::ReverseProxy';
        sub {
            my $req = Plack::Request->new(shift);
            if ( $block->{address} ) {
                is( $req->address, $block->{address}, $tag . " of address" );
            }
            if ( $block->{secure} ) {
                is( ($req->env->{'psgi.url_scheme'} eq 'https'), $block->{secure}, $tag . " of secure" );
            }
            for my $url (qw/uri base /) {
                if ( $block->{$url} ) {
                    is( $req->$url->as_string, $block->{$url}, $tag . " of $url" );
                }
            }
            [200, ['Content-Type' => 'text/plain'], [ 'OK' ]];
        }
    };

    my %test = (
        client => sub {
            my $cb = shift;
            my $res = $cb->(
                HTTP::Request->new(
                    GET => 'http://example.com/?foo=bar', $headers,
                )
            );
        },
        app => $handler,
    );

    test_psgi %test;
}

my @test = (
'with https' => {
    input  => q{x-forwarded-https: on},
    secure => 1,
    base   => 'https://example.com/',
    uri    => 'https://example.com/?foo=bar'
},
'without https' => {
    input  => q{x-forwarded-https: off},
    secure => 0,
    base   => 'http://example.com/',
    uri    => 'http://example.com/?foo=bar'
},
'dummy' => {
    input  => q{dummy: 1},
    secure => 0,
    base   => 'http://example.com/',
    uri    => 'http://example.com/?foo=bar',
},
'https with HTTP_X_FORWARDED_PROTO' => {
    input  => q{x-forwarded-proto: https},
    secure => 1,
    base   => 'https://example.com/',
    uri    => 'https://example.com/?foo=bar'
},
'http with HTTP_X_FORWARDED_PROTO' => {
    input  => q{x-forwarded-proto: http},
    secure => '0',
    base   => 'http://example.com/',
    uri    => 'http://example.com/?foo=bar',
},
'with HTTP_X_FORWARDED_FOR' => {
    input   => q{x-forwarded-for: 192.168.3.2},
    address => '192.168.3.2',
    base    => 'http://example.com/',
    uri     => 'http://example.com/?foo=bar',
},
'with HTTP_X_FORWARDED_HOST' => {
    input => q{x-forwarded-host: 192.168.1.2:5235},
    base  => 'http://192.168.1.2:5235/',
    uri   => 'http://192.168.1.2:5235/?foo=bar',
},
'default port with HTTP_X_FORWARDED_HOST' => {
    input => q{x-forwarded-host: 192.168.1.2},
    base  => 'http://192.168.1.2/',
    uri   => 'http://192.168.1.2/?foo=bar',
},
'default https port with HTTP_X_FORWARDED_HOST' => {
    input => q{x-forwarded-https: on
x-forwarded-host: 192.168.1.2},
    base  => 'https://192.168.1.2/',
    uri   => 'https://192.168.1.2/?foo=bar',
},
'default port with HOST' => {
    input => q{host: 192.168.1.2},
    base  => 'http://192.168.1.2/',
    uri   => 'http://192.168.1.2/?foo=bar',
},
'default https port with HOST' => {
    input => q{host: 192.168.1.2
https: ON},
    base  => 'https://192.168.1.2/',
    uri   => 'https://192.168.1.2/?foo=bar',
},
'with HTTP_X_FORWARDED_HOST and HTTP_X_FORWARDED_PORT' => {
    input => q{x-forwarded-host: 192.168.1.5
x-forwarded-port: 1984},
    base  => 'http://192.168.1.5:1984/',
    uri   => 'http://192.168.1.5:1984/?foo=bar',
},
'with multiple HTTP_X_FORWARDED_HOST and HTTP_X_FORWARDED_FOR' => {
    input   => q{x-forwarded-host: outmost.proxy.example.com, middle.proxy.example.com
x-forwarded-for: 1.2.3.4, 192.168.1.6
host: 192.168.1.7:5000},
    address => '192.168.1.6',
    base    => 'http://middle.proxy.example.com/',
    uri     => 'http://middle.proxy.example.com/?foo=bar',
},
'normal plackup status' => {
    input => q{host: 127.0.0.1:5000},
    base  => 'http://127.0.0.1:5000/',
    uri   => 'http://127.0.0.1:5000/?foo=bar',
},
'HTTP_X_FORWARDED_PORT to secure port' => {
    input  => q{x-forwarded-host: 192.168.1.2
x-forwarded-port: 443},
    secure => 1,
},
'HTTP_X_FORWARDED_PORT to secure port (apache2)' => {
    input  => q{x-forwarded-server: proxy.example.com
x-forwarded-host: proxy.example.com:8443
x-forwarded-https: on
x-forwarded-port: 8443},
    base   => 'https://proxy.example.com:8443/',
    uri    => 'https://proxy.example.com:8443/?foo=bar',
    secure => 1,
},
'with HTTP_X_FORWARDED_SERVER including 443 port (apache1)' => {
    input  => q{x-forwarded-server: proxy.example.com:443
x-forwarded-host: proxy.example.com},
    base   => 'https://proxy.example.com/',
    uri    => 'https://proxy.example.com/?foo=bar',
    secure => 1,
}
);

for ( my $i=0; $i < @test; $i = $i+2 ) {
    my $tag = $test[$i];
    my $test = $test[$i+1];
    run($tag,$test);
}

