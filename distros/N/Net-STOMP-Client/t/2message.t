#!perl

use strict;
use warnings;
use Test::More;

use Net::STOMP::Client::Frame;

eval { require Messaging::Message };
plan skip_all => "Messaging::Message required for this test" if $@;
plan tests => 12;

our($frame, $message);

#
# frame -> message
#

$frame = Net::STOMP::Client::Frame->new(
    command => "MESSAGE",
    headers => { "foo" => "bar" },
    body    => "test",
);
$message = $frame->messagify();
ok(!$message->text(), "frame -> message binary");
is($message->body(), $frame->body(), "frame -> message body (binary)");
is($message->header_field("foo"), "bar", "frame -> message header (binary)");

$frame = Net::STOMP::Client::Frame->new(
    command => "MESSAGE",
    headers => { "foo" => "bar", "content-type" => "text/plain" },
    body    => "test",
);
$message = $frame->messagify();
ok($message->text(), "frame -> message text");
is($message->body(), $frame->body(), "frame -> message body (text)");
is($message->header_field("foo"), "bar", "frame -> message header (text)");

#
# message -> frame
#

$message = Messaging::Message->new(
    header => { "foo" => "bar" },
    body   => "test",
    text   => 0,
);
$frame = Net::STOMP::Client::Frame->demessagify($message);
is($frame->body(), $message->body(), "message -> frame body (binary)");
is($frame->header("foo"), "bar", "message -> frame header (binary)");
ok(!$frame->header("content-type"), "message -> frame type (binary)");

$message = Messaging::Message->new(
    header => { "foo" => "bar" },
    body   => "test",
    text   => 1,
);
$frame = Net::STOMP::Client::Frame->demessagify($message);
is($frame->body(), $message->body(), "message -> frame body (text)");
is($frame->header("foo"), "bar", "message -> frame header (text)");
is($frame->header("content-type"), "text/unknown", "message -> frame type (text)");
