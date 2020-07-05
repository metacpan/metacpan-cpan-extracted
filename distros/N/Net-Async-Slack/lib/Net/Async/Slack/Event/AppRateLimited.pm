package Net::Async::Slack::Event::AppRateLimited;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::AppRateLimited - Indicates your app's event subscriptions are being rate limited

=head1 DESCRIPTION

Example input data:

    {
        "token": "Jhj5dZrVaK7ZwHHjRyZWjbDl",
        "type": "app_rate_limited",
        "team_id": "T123456",
        "minute_rate_limited": 1518467820,
        "api_app_id": "A123456"
    }


=cut

sub type { 'app_rate_limited' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
