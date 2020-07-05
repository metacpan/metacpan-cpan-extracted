package Net::Async::Slack::Event::ImOpen;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ImOpen - You opened a DM

=head1 DESCRIPTION

Example input data:

    im:read

=cut

sub type { 'im_open' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
