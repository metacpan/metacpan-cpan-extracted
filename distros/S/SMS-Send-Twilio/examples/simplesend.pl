#! /usr/bin/env perl

use strict;
use warnings;

use SMS::Send;

# Create a sender
my $sender = SMS::Send->new(
    'Twilio',
    _accountsid => 'ACb657bdcb16f06893fd127e099c070eca',
    _authtoken  => 'b857f7afe254fa86c689648447e04cff',
    _from       => '+15005550006',
);

# Send a message
my $sent = $sender->send_sms(
    text => 'This is a test message',
    to   => '+31645742418',
);

# Did the send succeed.
if ($sent) {
    print "Message sent ok\n";
}
else {
    print "Failed to send message\n";
}
