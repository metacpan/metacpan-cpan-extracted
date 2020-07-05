package Net::Async::Slack::Event::GroupHistoryChanged;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupHistoryChanged - Bulk updates were made to a private channel's history

=head1 DESCRIPTION

Example input data:

    groups:history

=cut

sub type { 'group_history_changed' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
