package Net::Async::Slack::Event::FileCreated;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FileCreated - A file was created

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_created' }

1;

