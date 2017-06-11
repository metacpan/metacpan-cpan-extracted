package Net::Async::Slack::Event::PinRemoved;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::PinRemoved - A pin was removed from a channel

=head1 DESCRIPTION

Example input data:

    pins:read

=cut

sub type { 'pin_removed' }

1;

