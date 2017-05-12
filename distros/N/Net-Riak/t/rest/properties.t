use strict;
use warnings;
use Test::More;

use Net::Riak;
use HTTP::Response;

my $client = Net::Riak::Client->with_traits('Net::Riak::Transport::REST')->new();
ok my $bucket = Net::Riak::Bucket->new(name => 'bar', client => $client),
  'client created';

$bucket->client->useragent->add_handler(
    request_send => sub {
        my $response = HTTP::Response->new(200);
        $response->content(
            '{"props":{"name":"foo","allow_mult":false,"big_vclock":50,"chash_keyfun":{"mod":"riak_util","fun":"chash_std_keyfun"},"linkfun":{"mod":"jiak_object","fun":"mapreduce_linkfun"},"n_val":3,"old_vclock":86400,"small_vclock":10,"young_vclock":20},"keys":["bar"]}'
        );
        $response;
    }
);

ok my $props = $bucket->get_properties(), 'fetch properties';
ok my $keys  = $bucket->get_keys(),       'fetch list of keys';

is_deeply $keys, [qw/bar/], 'keys is bar';

ok my $name = $bucket->get_property('name'), 'get props name';
is $name, 'foo', 'name is foo';

done_testing;
