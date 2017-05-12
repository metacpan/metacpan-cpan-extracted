use strict;
use warnings;

use Test::More tests => 4;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

my $app = sub {
    my ( $env ) = @_;

    if($env->{'REQUEST_METHOD'} eq 'GET') {
        return [
            200,
            ['Content-Type' => 'text/plain'],
            ['OK'],
        ];
    } else {
        ...
    }
};

$app = builder {
    enable 'Acme::YadaYada';
    $app;
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    is $res->code, 200;
    is $res->content, 'OK';

    $res = $cb->(POST '/');
    is $res->code, 501;
    is $res->message, 'Not Implemented';
};
