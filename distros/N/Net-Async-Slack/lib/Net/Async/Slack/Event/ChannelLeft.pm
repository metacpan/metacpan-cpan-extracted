package Net::Async::Slack::Event::ChannelLeft;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelLeft - You left a channel

=head1 DESCRIPTION

Example input data:

    {
        "type": "channel_left",
        "channel": "C024BE91L"
    }


=cut

sub type { 'channel_left' }

1;

