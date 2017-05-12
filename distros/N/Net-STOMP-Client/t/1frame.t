#!perl

use strict;
use warnings;
use Net::STOMP::Client::Frame;
use Test::More tests => 11;

sub test ($%) {
    my($ok, %option) = @_;
    my($what, $frame);

    $what = "{" . join(", ", map("$_=$option{$_}", sort(keys(%option)))) . "}";
    eval { $frame = Net::STOMP::Client::Frame->new(%option) };
    if ($ok) {
	is($@, "", $what);
    } else {
	ok($@, $what);
    }
    return($frame);
}

my($frame);

$frame = test(1);
$frame = test(1, command => "SEND");
$frame = test(1, headers => {});
$frame = test(1, body => "hello");
is($frame->body(), "hello", "body check");
$frame = test(1, body_reference => \ "hello");
is($frame->body(), "hello", "body_reference check");
$frame = test(1, command => "SEND", body => "hello");

$frame = test(0, foo => 1);
$frame = test(0, header => {});
$frame = test(0, body => "hello", body_reference => \"hello");
