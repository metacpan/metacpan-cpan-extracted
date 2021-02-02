package Net::Async::Slack::Event::TeamProfileReorder;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamProfileReorder - The workspace profile fields have been reordered

=head1 DESCRIPTION

Example input data:

    {
        "type": "team_profile_reorder",
        "profile": {
            "fields": [
                {
                    "id": "Xf06054AAA",
                    "ordering": 0,
                },
                ...
            ]
        }
    }


=cut

sub type { 'team_profile_reorder' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
