package Net::Async::Slack::Event::ChannelHistoryChanged;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelHistoryChanged - Bulk updates were made to a channel's history

=head1 DESCRIPTION

Example input data:

    channels:history

=cut

sub type { 'channel_history_changed' }

1;

