package Net::Async::Slack::Event::CommandsChanged;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::CommandsChanged - A team slash command has been added or changed

=head1 DESCRIPTION

Example input data:

    {
        "type": "commands_changed",
        "event_ts" : "1361482916.000004"
    }


=cut

sub type { 'commands_changed' }

1;

