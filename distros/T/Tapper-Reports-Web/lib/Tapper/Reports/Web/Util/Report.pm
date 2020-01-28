package Tapper::Reports::Web::Util::Report;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Util::Report::VERSION = '5.0.15';
use Moose;
use Tapper::Model 'model';

extends 'Tapper::Reports::Web::Util';

use common::sense;

sub prepare_simple_reportlist {

        my ( $self, $c, $reports ) = @_;

        # Mnemonic:
        #           rga = ReportGroup Arbitrary
        #           rgt = ReportGroup Testrun

        my $or_schema = model('TestrunDB');
        my @all_reports;
        my @reports;
        my %rgt;
        my %rga;
        my %rgt_prims;
        my %rga_prims;
        while (my $report = $reports->next)
        {
                my %cols = $report->get_columns;
                my $rga_id      = $cols{rga_id};
                my $rga_primary = $cols{rga_primary};
                my $rgt_id      = $cols{rgt_id};
                my $rgt_primary = $cols{rgt_primary};
                my $suite_name  = $cols{suite_name} || 'unknownsuite';
                my $suite_id    = $cols{suite_id}   || '0';
                my $r = {
                         id                    => $report->id,
                         suite_name            => $suite_name,
                         suite_id              => $suite_id,
                         machine_name          => $report->machine_name || 'unknownmachine',
                         created_at_ymd_hms    => $report->created_at->ymd('-')." ".$report->created_at->hms(':'),
                         created_at_ymd_hm     => sprintf("%s %02d:%02d",$report->created_at->ymd('-'), $report->created_at->hour, $report->created_at->minute),
                         created_at_ymd        => $report->created_at->ymd('-'),
                         success_ratio         => $report->success_ratio,
                         successgrade          => $report->parse_errors ? 'ERROR' : $report->successgrade,
                         total                 => $report->total,
                         rga_id                => $rga_id,
                         rga_primary           => $rga_primary,
                         rgt_id                => $rgt_id,
                         rgt_primary           => $rgt_primary,
                         parse_errors          => $report->parse_errors,
                         peerport              => $report->peerport,
                         peeraddr              => $report->peeraddr,
                         peerhost              => $report->peerhost,
                };

                # --- scheduling state ---
                my $testrun_scheduling = $or_schema->resultset('TestrunScheduling')->search({testrun_id => $rgt_id}, {rows => 1})->first;
                $r->{testrunscheduling_status} = $testrun_scheduling->status if $testrun_scheduling;

                # --- arbitrary ---
                if ($rga_id and $rga_primary)
                {
                        $r->{owner} = $report->reportgrouparbitrary->owner;
                        push @reports, $r;
                        $rga_prims{$rga_id} = 1;
                }
                if ($rga_id and not $rga_primary)
                {
                        push @{$rga{$rga_id}}, $r;
                }

                # --- testrun ---
                if ($rgt_id and $rgt_primary)
                {
                        $r->{owner} = $report->reportgrouptestrun->owner;
                        push @reports, $r;
                        $rgt_prims{$rgt_id} = 1;
                }
                if ($rgt_id and not $rgt_primary)
                {
                        push @{$rgt{$rgt_id}}, $r;
                }

                # --- none ---
                if (! $rga_id and ! $rgt_id)
                {
                        push @reports, $r;
                }

                push @all_reports, $r; # for easier overall stats
        }

        # Find groups without primary report
        my @rga_noprim;
        my @rgt_noprim;
        foreach (keys %rga) {
                push @rga_noprim, $_ unless $rga_prims{$_};
        }
        foreach (keys %rgt) {
                push @rgt_noprim, $_ unless $rgt_prims{$_};
        }
        # Pull out latest one and put into @reports as primary
        foreach (@rga_noprim) {
                my $rga_primary = pop @{$rga{$_}};
                $rga_primary->{rga_primary} = 1;
                push @reports, $rga_primary;
        }
        foreach (@rgt_noprim) {
                my $rgt_primary = pop @{$rgt{$_}};
                $rgt_primary->{rgt_primary} = 1;

                my $testrun = model('TestrunDB')->resultset('Testrun')->find($_);
                $rgt_primary->{owner} = $testrun->owner->login if $testrun;

                push @reports, $rgt_primary;
        }

        return {
                all_reports => \@all_reports,
                reports     => \@reports,
                rga         => \%rga,
                rgt         => \%rgt,
        };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Util::Report

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
