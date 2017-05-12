use strict;
use warnings;
use Test::More tests => 3;

use Protocol::Redis::XS;
my $redis = new_ok 'Protocol::Redis::XS', [api => 1];

$redis->on_message([]);
eval { $redis->parse("+OK\r\n") };
like $@, qr/Not a CODE reference/, "Die on invalid callback";

$redis->on_message(undef);
$redis->parse(":1234567891234567890\r\n");
is $redis->get_message->{data}, 1234567891234567890, "Large integer is correct";

