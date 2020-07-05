package Net::Async::Slack::Event::AppMention;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::AppMention - Subscribe to only the message events that mention your app or bot

=head1 DESCRIPTION

Example input data:

    {
        "type": "app_mention",
        "user": "U061F7AUR",
        "text": "<@U0LAN0Z89> is it everything a river should be?",
        "ts": "1515449522.000016",
        "channel": "C0LAN2Q65",
        "event_ts": "1515449522000016"
    }


=cut

sub type { 'app_mention' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
