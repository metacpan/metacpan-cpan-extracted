package Net::Async::Slack::Event::GroupDeleted;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupDeleted - A private channel was deleted

=head1 DESCRIPTION

Example input data:

    groups:read

=cut

sub type { 'group_deleted' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
