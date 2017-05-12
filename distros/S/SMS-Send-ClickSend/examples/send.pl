#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use SMS::Send;

die 'env CLCIKSEND_USERNAME and CLICKSEND_APIKEY is required.'
    unless $ENV{CLCIKSEND_USERNAME} and $ENV{CLICKSEND_APIKEY};

my $sender = SMS::Send->new('ClickSend',
    _username => $ENV{CLCIKSEND_USERNAME},
    _api_key  => $ENV{CLICKSEND_APIKEY}
);

# Send a message
my $sent = $sender->send_sms(
    text => 'This is a test message',
    to   => '+61411111111',
);

# Did the send succeed.
if ( $sent ) {
    print "Message sent ok\n";
} else {
    print "Failed to send message\n";
}