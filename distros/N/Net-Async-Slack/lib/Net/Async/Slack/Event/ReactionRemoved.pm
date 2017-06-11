package Net::Async::Slack::Event::ReactionRemoved;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ReactionRemoved - A team member removed an emoji reaction

=head1 DESCRIPTION

Example input data:

    reactions:read

=cut

sub type { 'reaction_removed' }

1;

