use strict;
use warnings;
use Test::More tests => 6;

use Protocol::Redis::XS;
my $redis = new_ok 'Protocol::Redis::XS', [api => 1];

$redis->on_message([]);
eval { $redis->parse("+OK\r\n") };
like $@, qr/Not a CODE reference/, "Die on invalid callback";

$redis->on_message(undef);
$redis->parse(":1234567891234567890\r\n");
is $redis->get_message->{data}, 1234567891234567890, "Large integer is correct";
is $redis->encode({type => '*', data => [{type => '$', data => "\x00TEST\x00"}]}), "*1\r\n\$6\r\n\x00TEST\x00\r\n", 'Binary data';
is $redis->encode({type => '$', data => "\x00"}), "\$1\r\n\x00\r\n", 'Encode bulk single nul character';
is $redis->encode({type => '$', data => undef}), "\$-1\r\n", 'Encode bulk undef data';

