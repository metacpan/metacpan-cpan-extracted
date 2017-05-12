use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::FakeRedis;

t::lib::FakeRedis->run;

my $app = builder {
    enable 'Debug',
        panels => [
            [ 'Redis::Keys', instance => 'localhost:6379', db => 0 ],
        ];
    sub { [200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ]] };
};

my @content_bundle = (
    string => 'coy:.*',    9000,
    list   => 'six:.*',      35,
    hash   => 'eleven:.*',   17,
    set    => 'two:.*',     101,
    zset   => 'tie:.*',      66,
);

test_psgi $app, sub {
    my ($cb) = @_;

    my $res = $cb->(GET '/');
    is $res->code, 200, 'response code 200';

    like $res->content,
        qr|<a href="#" title="Redis::Keys" class="plDebugKeys\d+Panel">|,
        'panel found';

    like $res->content,
        qr|<small>DB #0 \(5\)</small>|,
        'subtitle points to 5 keys in database 0';

    while (my ($type, $name, $size) = splice(@content_bundle, 0, 3)) {
        like $res->content, qr|<td>$name</td>[.\s\n\r]*<td>\U$type\E \($size\)</td>|m, "$type key found";
    }
};

done_testing();
