package Net::Async::Slack::Event::MessageMpim;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MessageMpim - A message was posted in a multiparty direct message channel

=head1 DESCRIPTION

Example input data:

    mpim:history

=cut

sub type { 'message.mpim' }

1;

