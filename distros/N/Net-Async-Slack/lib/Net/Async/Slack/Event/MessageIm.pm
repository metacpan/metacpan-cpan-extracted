package Net::Async::Slack::Event::MessageIm;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MessageIm - A message was posted in a direct message channel

=head1 DESCRIPTION

Example input data:

    im:history

=cut

sub type { 'message.im' }

1;

