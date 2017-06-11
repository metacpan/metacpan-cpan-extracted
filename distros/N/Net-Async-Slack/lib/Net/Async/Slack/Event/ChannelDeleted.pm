package Net::Async::Slack::Event::ChannelDeleted;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelDeleted - A channel was deleted

=head1 DESCRIPTION

Example input data:

    channels:read

=cut

sub type { 'channel_deleted' }

1;

