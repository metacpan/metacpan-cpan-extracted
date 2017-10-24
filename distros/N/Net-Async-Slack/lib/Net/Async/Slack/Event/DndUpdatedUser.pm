package Net::Async::Slack::Event::DndUpdatedUser;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::DndUpdatedUser - Do not Disturb settings changed for a team member

=head1 DESCRIPTION

Example input data:

    dnd:read

=cut

sub type { 'dnd_updated_user' }

1;

