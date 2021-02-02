package Net::Async::Slack::Event::SubteamCreated;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::SubteamCreated - A User Group has been added to the workspace

=head1 DESCRIPTION

Example input data:

    usergroups:read

=cut

sub type { 'subteam_created' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
