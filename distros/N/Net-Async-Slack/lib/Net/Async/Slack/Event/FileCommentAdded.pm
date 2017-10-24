package Net::Async::Slack::Event::FileCommentAdded;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FileCommentAdded - A file comment was added

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_comment_added' }

1;

