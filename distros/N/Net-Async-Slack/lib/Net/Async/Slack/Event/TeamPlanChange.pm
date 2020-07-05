package Net::Async::Slack::Event::TeamPlanChange;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamPlanChange - The account billing plan has changed

=head1 DESCRIPTION

Example input data:

    {
        "type": "team_plan_change",
        "plan": "std",
        "can_add_ura": false,
        "paid_features": ["feature1", "feature2"]
    }


=cut

sub type { 'team_plan_change' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
