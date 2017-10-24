package Net::Async::Slack::Event::StarRemoved;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::StarRemoved - A team member removed a star

=head1 DESCRIPTION

Example input data:

    stars:read

=cut

sub type { 'star_removed' }

1;

