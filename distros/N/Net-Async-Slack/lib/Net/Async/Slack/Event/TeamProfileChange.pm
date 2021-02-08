package Net::Async::Slack::Event::TeamProfileChange;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamProfileChange - The workspace profile fields have been updated

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

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
