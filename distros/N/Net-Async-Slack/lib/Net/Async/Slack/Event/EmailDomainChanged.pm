package Net::Async::Slack::Event::EmailDomainChanged;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::EmailDomainChanged - The team email domain has changed

=head1 DESCRIPTION

Example input data:

    team:read

=cut

sub type { 'email_domain_changed' }

1;

