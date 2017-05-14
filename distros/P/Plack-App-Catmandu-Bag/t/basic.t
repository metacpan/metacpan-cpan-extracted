use strict;
use warnings;
use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common;
use Catmandu;
use JSON qw(decode_json);

my $pkg;

BEGIN {
    $pkg = 'Plack::App::Catmandu::Bag';
    use_ok $pkg;
}

my $data = [
    {_id => 1, foo => 'bar'},
    {_id => 2, bar => 'foo'},
    {_id => 1, foo => 'baz'},
    ],

    Catmandu->define_store('test',
    Hash => (bags => {test => {plugins => ['Versioning']}}));

my $bag = Catmandu->store('test')->bag('test');

$bag->add($_) for @$data;

my $app = Plack::App::Catmandu::Bag->new(store => 'test', bag => 'test');

test_psgi $app, sub {
    my $cb = $_[0];
    my $res;

    $res = $cb->(GET "/");
    is $res->code, 200;
    is_deeply decode_json($res->content),
        {data => Catmandu->store('test')->bag('test')->to_array};

    $res = $cb->(GET "/1");
    is $res->code, 200;
    is_deeply decode_json($res->content),
        {data => Catmandu->store('test')->bag('test')->get(1)};

    $res = $cb->(GET "/x");
    is $res->code, 404;

    # record with versions
    $res = $cb->(GET "/1/versions");
    is $res->code, 200;
    is_deeply decode_json($res->content),
        {data => Catmandu->store('test')->bag('test')->get_history(1)};

    $res = $cb->(GET "/1/versions/2");
    is $res->code, 200;
    is_deeply decode_json($res->content),
        {data => Catmandu->store('test')->bag('test')->get_version(1, 2)};

    # record with no versions yet behave the same
    $res = $cb->(GET "/2/versions");
    is $res->code, 200;
    is_deeply decode_json($res->content),
        {data => Catmandu->store('test')->bag('test')->get_history(2)};

    $res = $cb->(GET "/2/versions/1");
    is $res->code, 200;
    is_deeply decode_json($res->content),
        {data => Catmandu->store('test')->bag('test')->get_version(2, 1)};
};

done_testing;
