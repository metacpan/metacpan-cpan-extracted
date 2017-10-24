package Net::Async::Slack::Event::ReactionAdded;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ReactionAdded - A team member has added an emoji reaction to an item

=head1 DESCRIPTION

Example input data:

    reactions:read

=cut

sub type { 'reaction_added' }

1;

