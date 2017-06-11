package Net::Async::Slack::Event::UserTyping;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::UserTyping - A channel member is typing a message

=head1 DESCRIPTION

Example input data:

    {
        "type": "user_typing",
        "channel": "C02ELGNBH",
        "user": "U024BE7LH"
    }


=cut

sub type { 'user_typing' }

1;

