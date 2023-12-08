package Net::Async::Slack::Event::SlashCommands;

use strict;
use warnings;

our $VERSION = '0.014'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::SlashCommands - /commands

=head1 DESCRIPTION

Example input data:

    {
        "type": "slash_commands",
        "user": "U061F7AUR",
        "channel": "D0LAN2Q65",
        "event_ts": "1515449522000016"
    }

=cut

sub type { 'slash_commands' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2023. Licensed under the same terms as Perl itself.
