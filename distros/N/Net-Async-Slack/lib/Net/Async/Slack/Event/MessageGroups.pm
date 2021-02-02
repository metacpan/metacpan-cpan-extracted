package Net::Async::Slack::Event::MessageGroups;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MessageGroups - A message was posted to a private channel

=head1 DESCRIPTION

Example input data:

    groups:history

=cut

sub type { 'message.groups' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
