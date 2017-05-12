use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use t::Util::Inherit;

my $handler = t::Util::Inherit->new;

my %test = (
    client => sub {
        my $cb  = shift;

        my $res = $cb->(GET "/index.txt");
        like $res->content, qr/新しい朝が来た/;
    },
    app => $handler,
);

test_psgi %test;

done_testing;
