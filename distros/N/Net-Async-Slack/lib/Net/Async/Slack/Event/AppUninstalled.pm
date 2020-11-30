package Net::Async::Slack::Event::AppUninstalled;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::AppUninstalled - Your Slack app was uninstalled.

=head1 DESCRIPTION

Example input data:

    {
        "token": "XXYYZZ",
        "team_id": "TXXXXXXXX",
        "api_app_id": "AXXXXXXXXX",
        "event": {
            "type": "app_uninstalled"
        },
        "type": "event_callback",
        "event_id": "EvXXXXXXXX",
        "event_time": 1234567890
    }


=cut

sub token { shift->{token} }

sub team_id { shift->{team_id} }

sub api_app_id { shift->{api_app_id} }

sub event_id { shift->{event_id} }

sub event_time { shift->{event_time} }

sub type { 'app_uninstalled' }

1;

