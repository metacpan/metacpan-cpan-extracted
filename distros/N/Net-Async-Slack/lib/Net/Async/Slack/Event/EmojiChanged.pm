package Net::Async::Slack::Event::EmojiChanged;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::EmojiChanged - A custom emoji has been added or changed

=head1 DESCRIPTION

Example input data:

    emoji:read

=cut

sub type { 'emoji_changed' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
