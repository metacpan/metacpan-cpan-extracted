package Net::Async::Slack::Event::AppHomeOpened;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::AppHomeOpened - User clicked into your App Home

=head1 DESCRIPTION

Example input data:

    {
        "type": "app_home_opened",
        "user": "U061F7AUR",
        "channel": "D0LAN2Q65",
        "event_ts": "1515449522000016"
    }


=cut

sub type { 'app_home_opened' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
