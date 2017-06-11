package Net::Async::Slack::Event::AccountsChanged;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 DESCRIPTION

{
"type":"accounts_changed",
}

=cut

sub type { 'accounts_changed' }

1;

