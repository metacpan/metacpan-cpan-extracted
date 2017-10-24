package Net::Async::Slack::Event::TeamPrefChange;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamPrefChange - A team preference has been updated

=head1 DESCRIPTION

Example input data:

    {
        "type": "team_pref_change",
        "name": "slackbot_responses_only_admins",
        "value": true
    }


=cut

sub type { 'team_pref_change' }

1;

