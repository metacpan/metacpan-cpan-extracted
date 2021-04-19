use strict;
use warnings;

use JSON::MaybeUTF8 qw(encode_json_utf8);

use Test::More;
use Test::Fatal;
use Test::MemoryGrowth;

use Storable qw(dclone);
# Myriad::RPC should be included to load exceptions.
use Myriad::RPC;
use Myriad::RPC::Message;

my $message_args = {
    rpc        => 'test',
    message_id => 1,
    who        => 'client',
    deadline   => time,
    args       => '{}',
    stash      => '{}',
    trace      => '{}'
};

is(exception {
    Myriad::RPC::Message->new(%$message_args)
}, undef, "->from_hash with correct params should succeed");

for my $key (qw/rpc message_id who deadline args/) {
    like(exception {
        my $args = dclone $message_args;
        delete $args->{$key};
        Myriad::RPC::Message::from_hash(%$args);
        my $json = encode_json_utf8($message_args);
        Myriad::RPC::Message::from_json($json)
    }, qr{^Invalid request.*}, "->from_* without $key should not succeed");
}

my $message = Myriad::RPC::Message::from_hash(%$message_args);
is(exception {
    $message->as_json();
    $message->as_hash();
}, undef, '->as_* should succeed');

no_growth {
    my $message = Myriad::RPC::Message::from_hash(%$message_args);
} 'no memory leak detected';

done_testing;
