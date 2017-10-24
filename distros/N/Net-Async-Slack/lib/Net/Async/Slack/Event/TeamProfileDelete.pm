package Net::Async::Slack::Event::TeamProfileDelete;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamProfileDelete - Team profile fields have been deleted

=head1 DESCRIPTION

Example input data:

    {
        "type": "team_profile_delete",
        "profile": {
            "fields": [
                "Xf06054AAA",
                ...
            ]
        }
    }


=cut

sub type { 'team_profile_delete' }

1;

