package Net::Async::Slack::Event::ImHistoryChanged;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ImHistoryChanged - Bulk updates were made to a DM's history

=head1 DESCRIPTION

Example input data:

    im:history

=cut

sub type { 'im_history_changed' }

1;

