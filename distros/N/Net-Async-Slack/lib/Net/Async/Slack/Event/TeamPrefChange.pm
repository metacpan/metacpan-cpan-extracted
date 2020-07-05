package Net::Async::Slack::Event::TeamPrefChange;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamPrefChange - A preference has been updated

=head1 DESCRIPTION

Example input data:

    {
        "type": "team_pref_change",
        "name": "slackbot_responses_only_admins",
        "value": true
    }


=cut

sub type { 'team_pref_change' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
