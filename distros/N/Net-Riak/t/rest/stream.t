use strict;
use warnings;
use Test::More;

use Net::Riak;
use HTTP::Response;

my $client = Net::Riak::Client->with_traits('Net::Riak::Transport::REST')->new();
ok my $bucket = Net::Riak::Bucket->new(name => 'bar', client => $client),
  'bucket created';

$bucket->client->useragent->add_handler(
    request_send => sub {
        my $response = HTTP::Response->new(200);
        $response->content(
            '{}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":["apple"]}{"keys":[]}{"keys":["pear","peach"]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}{"keys":[]}'
        );
        $response;
    }
);

ok my $props = $bucket->get_properties({props => 'false', keys => 'stream'}), 'get_properties';
is_deeply $props, { keys => [ qw(apple pear peach) ], props => {} }, 'keys ok';

ok my $keys  = $bucket->get_keys({stream => 1}), 'get_keys';
is_deeply $keys, [qw/apple pear peach/], 'keys ok';

my $result = '';
ok $bucket->get_properties({props => 'false', cb => sub { $result .= "** $_[0] " }}), 'get_properties with callback';
is $result, '** apple ** pear ** peach ', 'result ok';

$result = '';
ok ! defined $bucket->get_keys({cb => sub { $result .= "--> $_[0] " }}), 'get_keys with callback';
is $result, '--> apple --> pear --> peach ', 'result ok';

done_testing;

