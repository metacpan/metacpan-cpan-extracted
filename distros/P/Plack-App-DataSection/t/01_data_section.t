use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Plack::App::DataSection;

my $handler = Plack::App::DataSection->new;

my %test = (
    client => sub {
        my $cb  = shift;

        my $res = $cb->(GET "/sample.txt");
        like $res->content, qr/さんぷる/;

        $res = $cb->(GET "/");
        is $res->code, 404;
    },
    app => $handler,
);

test_psgi %test;

done_testing;
