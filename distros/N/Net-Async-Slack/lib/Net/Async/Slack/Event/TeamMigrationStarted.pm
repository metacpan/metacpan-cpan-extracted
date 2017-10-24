package Net::Async::Slack::Event::TeamMigrationStarted;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamMigrationStarted - The team is being migrated between servers

=head1 DESCRIPTION

Example input data:

    {
        "type": "team_migration_started",
    }


=cut

sub type { 'team_migration_started' }

1;

