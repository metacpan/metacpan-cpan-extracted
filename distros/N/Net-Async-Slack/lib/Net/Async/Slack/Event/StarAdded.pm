package Net::Async::Slack::Event::StarAdded;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::StarAdded - A team member has starred an item

=head1 DESCRIPTION

Example input data:

    stars:read

=cut

sub type { 'star_added' }

1;

