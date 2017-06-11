package Net::Async::Slack::Event::MessageChannels;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MessageChannels - A message was posted to a channel

=head1 DESCRIPTION

Example input data:

    channels:history

=cut

sub type { 'message.channels' }

1;

