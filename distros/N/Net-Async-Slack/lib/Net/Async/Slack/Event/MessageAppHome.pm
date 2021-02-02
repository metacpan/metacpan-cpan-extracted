package Net::Async::Slack::Event::MessageAppHome;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MessageAppHome - A user sent a message to your Slack app

=head1 DESCRIPTION

Example input data:

    {
        "token": "one-long-verification-token",
        "team_id": "T061EG9R6",
        "api_app_id": "A0PNCHHK2",
        "event": {
            "type": "message",
            "user": "U061F7AUR",
            "text": "How many cats did we herd yesterday?",
            "ts": "1525215129.000001",
            "channel": "D0PNCRP9N",
            "event_ts": "1525215129.000001",
            "channel_type": "app_home"
        },
        "type": "event_callback",
        "authed_teams": [
            "T061EG9R6"
        ],
        "event_id": "Ev0PV52K25",
        "event_time": 1525215129
    }


=cut

sub type { 'message.app_home' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
