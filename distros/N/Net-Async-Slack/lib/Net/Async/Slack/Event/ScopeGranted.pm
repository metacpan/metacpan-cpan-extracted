package Net::Async::Slack::Event::ScopeGranted;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ScopeGranted - OAuth scopes were granted to your app

=head1 DESCRIPTION

Example input data:

    {
        "token": "verification-token",
        "team_id": "T1DD3JH3K",
        "api_app_id": "A7449NRUL",
        "event": {
            "type": "scope_granted",
            "scopes": [
                "files:read",
                "files:write",
                "chat:write"
            ],
            "trigger_id": "241582872337.47445629121.string"
        },
        "type": "event_callback",
        "authed_teams": [],
        "event_id": "Ev74V2J98E",
        "event_time": 1505519097
    }


=cut

sub type { 'scope_granted' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
