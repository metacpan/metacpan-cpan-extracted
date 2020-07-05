package Net::Async::Slack::Event::TeamDomainChange;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamDomainChange - The workspace domain has changed

=head1 DESCRIPTION

Example input data:

    team:read

=cut

sub type { 'team_domain_change' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
