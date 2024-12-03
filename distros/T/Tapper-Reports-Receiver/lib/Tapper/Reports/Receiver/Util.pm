package Tapper::Reports::Receiver::Util;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Receive test reports
$Tapper::Reports::Receiver::Util::VERSION = '5.0.2';
use 5.010;
use strict;
use warnings;

use Data::Dumper;
use DateTime::Format::Natural;
use File::MimeInfo::Magic;
use IO::Scalar;
use Moose;
use YAML::Syck;
use Devel::Backtrace;
use Try::Tiny;
use Sys::Syslog; # core module since 1994

use Tapper::Config;
use Tapper::Model 'model';
use Tapper::TAP::Harness;

extends 'Tapper::Base';

has report => (is => 'rw');
has tap    => (is => 'rw');



sub cfg
{
        my ($self) = @_;
        return Tapper::Config->subconfig();
}


sub start_new_report {
        my ($self, $host, $port) = @_;

        $self->report( model('ReportsDB')->resultset('Report')->new({
                                                                     peerport => $port,
                                                                     peerhost => $host,
                                                                    }));
        $self->report->insert;
        my $tap = model('ReportsDB')->resultset('Tap')->new({
                                                             tap => '',
                                                             report_id => $self->report->id,
                                                            });
        $tap->insert;
        return $self->report->id;
}


sub tap_mimetype {
        my ($self) = shift;

        my $TAPH      = IO::Scalar->new(\($self->tap));
        return mimetype($TAPH);
}


sub tap_is_archive
{
        my ($self) = shift;

        return $self->tap_mimetype =~ m,application/(x-)?(octet-stream|compressed|gzip), ? 1 : 0;
}



sub write_tap_to_db
{
        my ($self) = shift;

        $self->report->tap->tap_is_archive(1) if $self->tap_is_archive;
        $self->report->tap->tap( $self->tap );
        $self->report->tap->update;
        return;
}


sub get_suite {
        my ($self, $suite_name, $suite_type) = @_;

        $suite_name ||= 'unknown';
        $suite_type ||= 'software';

        my $suite = model("ReportsDB")->resultset('Suite')->search({name => $suite_name }, {rows => 1})->first;
        if (not $suite) {
                $suite = model("ReportsDB")->resultset('Suite')->new({
                                                                      name => $suite_name,
                                                                      type => $suite_type,
                                                                      description => "$suite_name test suite",
                                                                     });
                $suite->insert;
        }
        return $suite;
}


sub create_report_sections
{
        my ($self, $parsed_report) = @_;

        # meta keys
        my $section_nr = 0;
        foreach my $section ( @{$parsed_report->{tap_sections}} ) {
                $section_nr++;
                my $report_section = model('ReportsDB')->resultset('ReportSection')->new
                    ({
                      report_id  => $self->report->id,
                      succession => $section_nr,
                      name       => $section->{section_name},
                     });

                foreach (keys %{$section->{db_section_meta}})
                {
                        my $value = $section->{db_section_meta}{$_};
                        $report_section->$_ ($value) if defined $value;
                }

                $report_section->insert;
        }
}


sub update_reportgroup_testrun_stats
{
        my ($self, $testrun_id) = @_;

        my $reportgroupstats = model('ReportsDB')->resultset('ReportgroupTestrunStats')->find($testrun_id);
        unless ($reportgroupstats and $reportgroupstats->testrun_id) {
                $reportgroupstats = model('ReportsDB')->resultset('ReportgroupTestrunStats')->new({ testrun_id => $testrun_id });
                $reportgroupstats->insert;
        }

        $reportgroupstats->update_failed_passed;
        $reportgroupstats->update;
}


sub create_report_groups
{
        my ($self, $parsed_report) = @_;

        my ($reportgroup_arbitrary,
            $reportgroup_testrun,
            $reportgroup_primary,
            $owner
           ) = (
                $parsed_report->{db_report_reportgroup_meta}{reportgroup_arbitrary},
                $parsed_report->{db_report_reportgroup_meta}{reportgroup_testrun},
                $parsed_report->{db_report_reportgroup_meta}{reportgroup_primary},
                $parsed_report->{db_report_reportgroup_meta}{owner},
               );

        if ($reportgroup_arbitrary and $reportgroup_arbitrary ne 'None') {
                my $reportgroup = model('ReportsDB')->resultset('ReportgroupArbitrary')->new
                    ({
                      report_id     => $self->report->id,
                      arbitrary_id  => $reportgroup_arbitrary,
                      primaryreport => $reportgroup_primary,
                      owner         => $owner,
                     });
                $reportgroup->insert;
        }

        if ($reportgroup_testrun and $reportgroup_testrun ne 'None') {
                if (not $owner) {
                        # don't check existance of each element in the search chain
                        eval {
                                $owner = model('TestrunDB')->resultset('Testrun')->find($reportgroup_testrun)->owner->login;
                        };
                }

                my $reportgroup = model('ReportsDB')->resultset('ReportgroupTestrun')->new
                    ({
                      report_id     => $self->report->id,
                      testrun_id    => $reportgroup_testrun,
                      primaryreport => $reportgroup_primary,
                      owner         => $owner,
                     });
                $reportgroup->insert;

                $self->update_reportgroup_testrun_stats($reportgroup_testrun);
        }
}


sub create_report_comment
{
        my ($self, $parsed_report) = @_;

        my ($comment) = ( $parsed_report->{db_report_reportcomment_meta}{reportcomment} );
        if ($comment) {
                my $reportcomment = model('ReportsDB')->resultset('ReportComment')->new
                    ({
                      report_id  => $self->report->id,
                      comment    => $comment,
                      succession => 1,
                     });
                $reportcomment->insert;
        }
}


sub update_parsed_report_in_db
{
        my ($self, $parsed_report) = @_;

        no strict 'refs'; ## no critic (ProhibitNoStrict)

        # lookup missing values in db
        $parsed_report->{db_report_meta}{suite_id} = $self->get_suite($parsed_report->{report_meta}{'suite-name'},
                                                                      $parsed_report->{report_meta}{'suite-type'},
                                                                     )->id;

        # report information
        foreach (keys %{$parsed_report->{db_report_meta}})
        {
                my $value = $parsed_report->{db_report_meta}{$_};
                $self->report->$_( $value ) if defined $value;
        }

        # report information - date fields
        foreach (keys %{$parsed_report->{db_report_date_meta}})
        {
                my $value = $parsed_report->{db_report_date_meta}{$_};
                $self->report->$_( DateTime::Format::Natural->new->parse_datetime($value ) ) if defined $value;
        }

        # success statistics
        foreach (keys %{$parsed_report->{stats}})
        {
                my $value = $parsed_report->{stats}{$_};
                $self->report->$_( $value ) if defined $value;
        }

        $self->report->update;

        $self->create_report_sections($parsed_report);
        $self->create_report_groups($parsed_report);
        $self->create_report_comment($parsed_report);
}


sub forward_to_level2_receivers
{
        my ($self) = @_;

        my @level2_receivers = (keys %{$self->cfg->{receiver}{level2} || {}});

        foreach my $l2receiver (@level2_receivers) {
                $self->log->debug( "L2 receiver: $l2receiver" );

                my $options = $self->cfg->{receiver}{level2}{$l2receiver};
                next if $options->{disabled};

                my $l2r_class = "Tapper::Reports::Receiver::Level2::$l2receiver";
                eval "use $l2r_class"; ## no critic
                if ($@) {
                        return "Could not load $l2r_class";
                } else {
                        no strict 'refs'; ## no critic
                        $self->log->debug( "Call ${l2r_class}::submit()" );
                        my ($error, $retval) = &{"${l2r_class}::submit"}($self, $self->report, $options);
                        if ($error) {
                                $self->log->error( "Error calling ${l2r_class}::submit: " . $retval );
                                return $retval;
                        }
                        return 0;
                }
        }
}



sub process_request
{
        my ($self, $tap) = @_;

        $SIG{CHLD} = 'IGNORE';
        my $pid = fork();
        if ($pid == 0) {
                try {
                        $0 = "tapper-reports-receiver-".$self->report->id;
                        $self->log->debug("Processing ".$self->report->id);
                        $SIG{USR1} = sub {
                                local $SIG{USR1}  = 'ignore'; # make handler reentrant, don't handle signal twice
                                my $backtrace = Devel::Backtrace->new(-start=>2, -format => '%I. %s');
                                open my $fh, ">>", '/tmp/tapper-receiver-util-'.$self->report->id;
                                print $fh $backtrace;
                                close $fh;
                        };

                        $self->tap($tap);

                        $self->write_tap_to_db();

                        my $harness = Tapper::TAP::Harness->new( tap => $self->tap,
                                                                 tap_is_archive => $self->report->tap->tap_is_archive );
                        $harness->evaluate_report();

                        $self->update_parsed_report_in_db( $harness->parsed_report );
                        $self->forward_to_level2_receivers();

                        # mark as processed
                        $self->report->tap->processed(1);
                        $self->report->tap->update;

                } catch {
                        # We can not use log4perl, because that might throw another
                        # exception e.g. when logfile is not writable
                        openlog('Tapper-Reports-Receiver', 'nofatal, ndelay', 'local0');
                        syslog('ALERT', "Error in processing report and can not safely log with Log4perl: $_");
                        closelog();
                };
                exit 0;
        } else {
                # noop in parent, return immediately
        }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Receiver::Util - Receive test reports

=head2 cfg

Provide Tapper config.

=head2 start_new_report

Create database entries to store the new report.

@param string - remote host name
@param int    - remote port

@return success - report id

=head2 tap_mimetype

Return mimetype of received TAP (Text vs. TAP::Archive).

=head2 tap_is_archive

Return true when TAP is TAP::Archive.

=head2 write_tap_to_db

Put tap string into database.

@return success - undef
@return error   - die

=head2 get_suite

Get suite name from TAP.

=head2 create_report_sections

Divide TAP into sections (a Tapper specific extension).

=head2 update_reportgroup_testrun_stats

Update testrun stats where this report belongs to.

=head2 create_report_groups

Create reportgroup from testrun details or arbitrary IDs.

=head2 create_report_comment

Reports can be attached with a comment. Create this.

=head2 update_parsed_report_in_db

Carve out details from report and update those values in DB.

=head2 forward_to_level2_receivers

Load configured I<Level 2 receiver> plugins and call them with this
report.

=head2 process_request

Process the tap and put it into the database.

@param string - tap

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
