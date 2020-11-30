package Net::Async::Slack::Event::ChannelCreated;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelCreated - A channel was created

=head1 DESCRIPTION

Example input data:

    channels:read

=cut

sub type { 'channel_created' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
