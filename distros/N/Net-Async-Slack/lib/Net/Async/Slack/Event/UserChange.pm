package Net::Async::Slack::Event::UserChange;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::UserChange - A team member's data has changed

=head1 DESCRIPTION

Example input data:

    users:read

=cut

sub type { 'user_change' }

1;

