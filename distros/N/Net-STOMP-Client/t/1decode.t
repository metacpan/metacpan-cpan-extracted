#!perl

use strict;
use warnings;
use Encode qw();
use Net::STOMP::Client::Frame qw();
use Test::More tests => 19;

my($frame, $data, $str, $enc);

$data = "FOO\nid: 123 \nid: 456\n\nbody\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.0");
is($frame->command(), "FOO", "command (1.0)");
is($frame->header("id"), "456", "header (1.0)");
is($frame->body(), "body", "body (1.0)");

$data = "FOO\nid: 123 \nid: 456\n\nbody\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.1");
is($frame->command(), "FOO", "command (1.1)");
is($frame->header("id"), " 123 ", "header (1.1)");
is($frame->body(), "body", "body (1.1)");

$data = "FOO\nid:123\r\na:b\r\n\r\nbody\r\n\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.1");
is($frame->command(), "FOO", "command (1.1)");
is($frame->header("id"), "123\r", "header (1.1)");
is($frame->body(), "body\r\n", "body (1.1)");

$data = "FOO\nid:123\r\na:b\r\n\r\nbody\r\n\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.2");
is($frame->command(), "FOO", "command (1.1)");
is($frame->header("id"), "123", "header (1.1)");
is($frame->body(), "body\r\n", "body (1.1)");

$str = "Théâtre Français";
$enc = Encode::encode("UTF-8", $data=$str, Encode::FB_CROAK);

$data = "FOO\nid:$enc\n\nbody\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.0");
is($frame->header("id"), $enc, "header (UTF-8 1.0)");

$data = "FOO\nid:$enc\n\nbody\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.1");
is($frame->header("id"), $str, "header (UTF-8 1.1)");

$data = "FOO\ncontent-type:text/plain\n\n$enc\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.0");
is($frame->body(), $enc, "body (UTF-8 1.0)");

$data = "FOO\ncontent-type:text/plain\n\n$enc\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.1");
is($frame->body(), $str, "body (UTF-8 1.1)");

$data = "FOO\ncontent-type:application/unknown\n\n$enc\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.1");
is($frame->body(), $enc, "body (UTF-8 1.1)");

$data = "FOO\nid:aaa\\\\bbb\\cccc\\nddd\n\nbody\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.0");
is($frame->header("id"), "aaa\\\\bbb\\cccc\\nddd", "header (escape 1.0)");

$data = "FOO\nid:aaa\\\\bbb\\cccc\\nddd\n\nbody\0";
$frame = Net::STOMP::Client::Frame::decode(\$data, version => "1.1");
is($frame->header("id"), "aaa\\bbb:ccc\nddd", "header (escape 1.1)");
