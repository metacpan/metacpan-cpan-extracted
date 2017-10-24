package Net::Async::Slack::Event::EmojiChanged;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::EmojiChanged - A team custom emoji has been added or changed

=head1 DESCRIPTION

Example input data:

    emoji:read

=cut

sub type { 'emoji_changed' }

1;

