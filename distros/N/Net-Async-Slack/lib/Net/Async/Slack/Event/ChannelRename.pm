package Net::Async::Slack::Event::ChannelRename;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ChannelRename - A channel was renamed

=head1 DESCRIPTION

Example input data:

    channels:read

=cut

sub type { 'channel_rename' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
