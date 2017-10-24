package Net::Async::Slack::Event::FileShared;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FileShared - A file was shared

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_shared' }

1;

