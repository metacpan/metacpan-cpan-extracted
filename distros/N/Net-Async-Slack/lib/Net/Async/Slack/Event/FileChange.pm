package Net::Async::Slack::Event::FileChange;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FileChange - A file was changed

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_change' }

1;

