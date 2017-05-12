use strict;
use warnings;

use HTTP::Request;
use Plack::Builder;
use Plack::Test;
use Test::More;

use_ok('Plack::Middleware::AddDefaultCharset');

my $app = builder {
    enable 'AddDefaultCharset', charset => 'utf-8';
    sub {
        my $env = shift;
        my $ct = $env->{QUERY_STRING};
        $ct =~ s/\%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        return [
            200,
            [ 'Content-Type', $ct ],
            [ 'hello' ],
        ];
    };
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        
        my $res = $cb->(
            HTTP::Request->new(
                GET => 'http://0/?text/html',
            ),
        );
        is(
            $res->header('Content-Type'),
            'text/html; charset=utf-8',
            'add charset',
        );
        
        $res = $cb->(
            HTTP::Request->new(
                GET => 'http://0/?text/html%3B%20charset=us-ascii',
            ),
        );
        is(
            $res->header('Content-Type'),
            'text/html; charset=us-ascii',
            'exists',
        );
        
        $res = $cb->(
            HTTP::Request->new(
                GET => 'http://0/?image/gif',
            ),
        );
        is(
            $res->header('Content-Type'),
            'image/gif',
            'skip by type',
        );
    };

done_testing;
