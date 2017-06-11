package Net::Async::Slack::Event::ManualPresenceChange;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ManualPresenceChange - You manually updated your presence

=head1 DESCRIPTION

Example input data:

    {
        "type": "manual_presence_change",
        "presence": "away"
    }


=cut

sub type { 'manual_presence_change' }

1;

