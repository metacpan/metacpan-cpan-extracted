package Net::Async::Slack::Event::ChannelCreated;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelCreated - A channel was created

=head1 DESCRIPTION

Example input data:

    channels:read

=cut

sub type { 'channel_created' }

1;

