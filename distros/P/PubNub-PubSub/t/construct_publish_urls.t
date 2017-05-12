use strict;
use Test::More;
use PubNub::PubSub;
use Mojo::URL;
use Mojo::JSON qw/decode_json/;

my $pubnub = PubNub::PubSub->new(
    pub_key  => 'demo',
    sub_key  => 'demo',
    channel  => 'sandbox',
);

my @urls = $pubnub->__construct_publish_urls(
    messages => ['message1', 'message2']
);
is scalar(@urls), 2;
is $urls[0]->{url}, 'http://pubsub.pubnub.com/publish/demo/demo/0/sandbox/0/%22message1%22';
is $urls[1]->{url}, 'http://pubsub.pubnub.com/publish/demo/demo/0/sandbox/0/%22message2%22';

@urls = $pubnub->__construct_publish_urls(
    messages => [
        {
            message => 'test1',
            ortt => {
                "r" => 13,
                "t" => "13978641831137500"
            },
            meta => {
                "stuff" => []
            },
            ear  => 'True',
            seqn => 12345,
        },
        {
            message => 'test2',
            ortt => {
                "r" => 13,
                "t" => "13978641831137501"
            },
            meta => {
                "stuff" => []
            },
            ear  => 'True',
            seqn => 12346,
        }
    ]
);
is scalar(@urls), 2;
my $uri = Mojo::URL->new($urls[0]->{url});
is $uri->path, '/publish/demo/demo/0/sandbox/0/%22test1%22';
is $uri->query->param('ear'), '"True"';
is $uri->query->param('seqn'), '12345';
is_deeply decode_json($uri->query->param('meta')), { "stuff" => [] };
is_deeply decode_json($uri->query->param('ortt')), {
    "r" => 13,
    "t" => "13978641831137500"
};
$uri = Mojo::URL->new($urls[1]->{url});
is $uri->path, '/publish/demo/demo/0/sandbox/0/%22test2%22';
is $uri->query->param('ear'), '"True"';
is $uri->query->param('seqn'), '12346';
is_deeply decode_json($uri->query->param('meta')), { "stuff" => [] };
is_deeply decode_json($uri->query->param('ortt')), {
    "r" => 13,
    "t" => "13978641831137501"
};

@urls = $pubnub->__construct_publish_urls(
    messages => [
        {
            message => 'test3',
            ortt => {
                "r" => 13,
                "t" => "13978641831137500"
            },
            seqn => 12345,
        },
        {
            message => 'test4',
            ortt => {
                "r" => 13,
                "t" => "13978641831137502"
            },
            seqn => 12347,
            ear  => 'False',
        }
    ],
    meta => {
        "stuff" => []
    },
    ear  => 'True',
);
is scalar(@urls), 2;
$uri = Mojo::URL->new($urls[0]->{url});
is $uri->path, '/publish/demo/demo/0/sandbox/0/%22test3%22';
is $uri->query->param('ear'), '"True"';
is $uri->query->param('seqn'), '12345';
is_deeply decode_json($uri->query->param('meta')), { "stuff" => [] };
is_deeply decode_json($uri->query->param('ortt')), {
    "r" => 13,
    "t" => "13978641831137500"
};
$uri = Mojo::URL->new($urls[1]->{url});
is $uri->path, '/publish/demo/demo/0/sandbox/0/%22test4%22';
is $uri->query->param('ear'), '"False"';
is $uri->query->param('seqn'), '12347';
is_deeply decode_json($uri->query->param('meta')), { "stuff" => [] };
is_deeply decode_json($uri->query->param('ortt')), {
    "r" => 13,
    "t" => "13978641831137502"
};

done_testing;
