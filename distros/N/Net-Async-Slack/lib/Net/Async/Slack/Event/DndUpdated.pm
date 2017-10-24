package Net::Async::Slack::Event::DndUpdated;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::DndUpdated - Do not Disturb settings changed for the current user

=head1 DESCRIPTION

Example input data:

    dnd:read

=cut

sub type { 'dnd_updated' }

1;

