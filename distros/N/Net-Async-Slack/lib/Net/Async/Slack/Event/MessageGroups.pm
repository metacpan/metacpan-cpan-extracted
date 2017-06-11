package Net::Async::Slack::Event::MessageGroups;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MessageGroups - A message was posted to a private channel

=head1 DESCRIPTION

Example input data:

    groups:history

=cut

sub type { 'message.groups' }

1;

