package Net::Async::Slack::Event::FileUnshared;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FileUnshared - A file was unshared

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_unshared' }

1;

