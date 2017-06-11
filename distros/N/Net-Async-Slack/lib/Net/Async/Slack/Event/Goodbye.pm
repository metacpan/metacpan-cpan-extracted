package Net::Async::Slack::Event::Goodbye;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::Goodbye - The server intends to close the connection soon.

=head1 DESCRIPTION

Example input data:

    {
        "type": "goodbye"
    }


=cut

sub type { 'goodbye' }

1;

