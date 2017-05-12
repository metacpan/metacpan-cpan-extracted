use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use JSON;

use lib 'eg';
use
    PLite;

my $app = PLite->new->to_psgi;

test_psgi
    app => $app,
    client => sub {
        my $cb  = shift;
        my $req = GET '/';
        my $res = $cb->($req);
        like $res->decoded_content, qr{<p>あなたは1回目の訪問ですね</p>};
    };

test_psgi
    app => $app,
    client => sub {
        my $cb  = shift;
        my $req = POST '/api';
        my $res = $cb->($req);

        my $hash = decode_json $res->content;
        ok $hash->{counter};
    };

done_testing;
