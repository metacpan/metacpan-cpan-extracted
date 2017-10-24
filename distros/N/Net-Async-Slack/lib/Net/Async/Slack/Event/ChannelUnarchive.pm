package Net::Async::Slack::Event::ChannelUnarchive;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelUnarchive - A channel was unarchived

=head1 DESCRIPTION

Example input data:

    channels:read

=cut

sub type { 'channel_unarchive' }

1;

