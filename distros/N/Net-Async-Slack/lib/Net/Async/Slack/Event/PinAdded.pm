package Net::Async::Slack::Event::PinAdded;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::PinAdded - A pin was added to a channel

=head1 DESCRIPTION

Example input data:

    pins:read

=cut

sub type { 'pin_added' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
