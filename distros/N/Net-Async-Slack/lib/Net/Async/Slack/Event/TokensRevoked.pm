package Net::Async::Slack::Event::TokensRevoked;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TokensRevoked - API tokens for your app were revoked.

=head1 DESCRIPTION

Example input data:

    {
        "token": "XXYYZZ",
        "team_id": "TXXXXXXXX",
        "api_app_id": "AXXXXXXXXX",
        "event": {
            "type": "tokens_revoked",
            "tokens": {
                "oauth": [
                    "UXXXXXXXX"
                ],
                "bot": [
                    "UXXXXXXXX"
                ]
            }
        },
        "type": "event_callback",
        "event_id": "EvXXXXXXXX",
        "event_time": 1234567890
    }


=cut

sub type { 'tokens_revoked' }

1;

