package Net::Async::Slack::Event::PresenceQuery;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::PresenceQuery - Determine the current presence status for a list of users

=head1 DESCRIPTION

Example input data:

    ids

=cut

sub type { 'presence_query' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
