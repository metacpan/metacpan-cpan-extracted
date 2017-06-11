package Net::Async::Slack::Event::ChannelJoined;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelJoined - You joined a channel

=head1 DESCRIPTION

Example input data:

    {
        "type": "channel_joined",
        "channel": {
            ...
        }
    }


=cut

sub type { 'channel_joined' }

1;

