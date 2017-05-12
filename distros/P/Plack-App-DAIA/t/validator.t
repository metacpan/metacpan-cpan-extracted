use strict;
use warnings;
use v5.10;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::DAIA::Validator;

my $app = Plack::App::DAIA::Validator->new( warnings => 1 );
isa_ok $app, 'Plack::App::DAIA::Validator';

test_psgi $app, sub {
    my ($cb) = @_;

    my $res = $cb->(GET "/");
    is $res->code, 200;
    is $res->header('content-type'), 'text/html; charset=utf-8', 'HTML';

    $res = $cb->(GET "/daia.xsl");
    is $res->code, 200;
    like $res->content, qr/<xsl:stylesheet/m, 'XSLT';
};

done_testing;
