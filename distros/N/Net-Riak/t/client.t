use strict;
use warnings;

use Test::More;

use Net::Riak;
use Net::Riak::Client;

my $riak = Net::Riak->new(r => 3, w => 4, dw => 5);
is $riak->client->r,  3, 'r set to 3';
is $riak->client->dw, 5, 'r set to 5';

$riak = Net::Riak::Client->new(r => 5, w => 4, dw => 3);
is $riak->r,  5, 'r set to 5';
is $riak->dw, 3, 'r set to 3';

ok $riak->client_id, 'id set';

done_testing;

