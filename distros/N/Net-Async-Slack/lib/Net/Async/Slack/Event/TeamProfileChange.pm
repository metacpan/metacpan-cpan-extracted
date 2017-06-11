package Net::Async::Slack::Event::TeamProfileChange;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamProfileChange - Team profile fields have been updated

=head1 DESCRIPTION

Example input data:

    {
        "type": "team_profile_change",
        "profile": {
            "fields": [
                {
                    "id": "Xf06054AAA",
                    ...
                },
                ...
            ]
        }
    }


=cut

sub type { 'team_profile_change' }

1;

