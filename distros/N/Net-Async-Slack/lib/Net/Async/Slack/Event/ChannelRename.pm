package Net::Async::Slack::Event::ChannelRename;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelRename - A channel was renamed

=head1 DESCRIPTION

Example input data:

    channels:read

=cut

sub type { 'channel_rename' }

1;

