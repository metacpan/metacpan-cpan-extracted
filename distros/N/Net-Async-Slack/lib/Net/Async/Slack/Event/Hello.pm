package Net::Async::Slack::Event::Hello;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::Hello - The client has successfully connected to the server

=head1 DESCRIPTION

Example input data:

    hello

=cut

sub type { 'hello' }

1;

