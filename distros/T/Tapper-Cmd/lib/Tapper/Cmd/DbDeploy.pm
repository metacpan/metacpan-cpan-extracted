package Tapper::Cmd::DbDeploy;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Backend functions for DB deployment
$Tapper::Cmd::DbDeploy::VERSION = '5.0.14';
use 5.010;
use strict;
use warnings;

use Moose;
use Tapper::Config;
use Tapper::Schema::TestrunDB;

extends 'Tapper::Cmd';



sub insert_initial_values
{
        my ($self, $db) = @_;

        if ($db eq 'TestrunDB')
        {
                my $dsn    = Tapper::Config->subconfig->{database}{$db}{dsn};
                my $user   = Tapper::Config->subconfig->{database}{$db}{username};
                my $pw     = Tapper::Config->subconfig->{database}{$db}{password};
                my $schema = Tapper::Schema::TestrunDB->connect ($dsn, $user, $pw);

                # ---------- Topic ----------

                require DateTime;

                # official topics
                my %topic_description = %Tapper::Schema::TestrunDB::Result::Topic::topic_description;

                foreach my $topic_name(keys %topic_description) {
                        $schema->resultset('Topic')->find_or_create
                            ({ name        => $topic_name,
                               description => $topic_description{$topic_name},
                             });
                }
                $schema->resultset('Queue')->find_or_create
                  ({ name     => 'AdHoc',
                     priority => 1000,
                     active   => 1,
                   });

                $schema->resultset('ChartTypes')->find_or_create
                  ({ chart_type_name        => 'points',
                     chart_type_description => 'points',
                     chart_type_flot_name   => 'points',
                     created_at             => DateTime->now(),
                   });
                $schema->resultset('ChartTypes')->find_or_create
                  ({ chart_type_name        => 'lines',
                     chart_type_description => 'lines',
                     chart_type_flot_name   => 'lines',
                     created_at             => DateTime->now(),
                   });

                $schema->resultset('ChartAxisTypes')->find_or_create
                  ({ chart_axis_type_name => 'numeric',
                     created_at           => DateTime->now(),
                   });
                $schema->resultset('ChartAxisTypes')->find_or_create
                  ({ chart_axis_type_name => 'alphanumeric',
                     created_at           => DateTime->now(),
                   });
                $schema->resultset('ChartAxisTypes')->find_or_create
                  ({ chart_axis_type_name => 'date',
                     created_at           => DateTime->now(),
                   });
        }
}


sub dbdeploy
{
        my ($self, $db) = @_;

        local $| =1;

        my $dsn  = Tapper::Config->subconfig->{database}{$db}{dsn};
        my $user = Tapper::Config->subconfig->{database}{$db}{username};
        my $pw   = Tapper::Config->subconfig->{database}{$db}{password};
        my $answer;

        # ----- really? -----
        print "REALLY DROP AND RE-CREATE DATABASE TABLES [$dsn] (y/N)? ";
        if ( lc substr(<STDIN>, 0, 1) ne 'y') {
                say "Skip.";
                return;
        }

        # ----- delete sqlite file -----
        if ($dsn =~ /dbi:SQLite:dbname/) {
                my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
                unlink $tmpfname;
        }

        my $stderr = '';
        {
                my $schema;
                $schema = Tapper::Schema::TestrunDB->connect ($dsn, $user, $pw);
                $schema->deploy({add_drop_table => 1}); # fails with {add_drop_table => 1}, does not provide correct order to drop tables
        }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::DbDeploy - Tapper - Backend functions for DB deployment

=head1 SYNOPSIS

This module provides functions to initially set up Tapper in C<$HOME/.tapper/>.

    use Tapper::Cmd::DbDeploy;
    my $cmd = Tapper::Cmd::DbDeploy->new;
    $cmd->dbdeploy("TestrunDB");

=head1 NAME

Tapper::Cmd::DbDeploy - Tapper - Backend functions for deploying databases

=head1 METHODS

=head2 $self->insert_initial_values($db)

Insert required minimal set of values.

=head2 $self->dbdeploy($db)

Deploy a schema into DB.

$db can be "TestrunDB" or "ReportsDB";

Connection info is determined via Tapper::Config.

TODO: still an interactive tool but interactivity should be migrated back into Tapper::CLI::*.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
