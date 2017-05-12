package Net::WAMP::Messages;

use strict;
use warnings;

use constant MSGS => {

    #Session
    HELLO => 1,
    WELCOME => 2,
    ABORT => 3,
    CHALLENGE => 4,
    AUTHENTICATE => 5,
    GOODBYE => 6,

    ERROR => 8,

    #PubSub
    PUBLISH => 16,
    PUBLISHED => 17,
    SUBSCRIBE => 32,
    SUBSCRIBED => 33,
    UNSUBSCRIBE => 34,
    UNSUBSCRIBED => 35,
    EVENT => 36,

    #RPC
    CALL => 48,
    CANCEL => 49,
    RESULT => 50,
    REGISTER => 64,
    REGISTERED => 65,
    UNREGISTER => 66,
    UNREGISTERED => 67,
    INVOCATION => 68,
    INTERRUPT => 69,
    YIELD => 70,
};

my %NAMES;

sub get_type_number {
    my ($name) = @_;

    return 0 + MSGS()->{$name};
}

sub get_type {
    my ($number) = @_;

    %NAMES = (reverse %{ MSGS() }) if !%NAMES;

    return $NAMES{$number};
}

1;
