package Net::Async::Slack::Event::GroupHistoryChanged;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupHistoryChanged - Bulk updates were made to a private channel's history

=head1 DESCRIPTION

Example input data:

    groups:history

=cut

sub type { 'group_history_changed' }

1;

