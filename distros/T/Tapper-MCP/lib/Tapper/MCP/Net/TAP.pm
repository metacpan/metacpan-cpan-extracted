package Tapper::MCP::Net::TAP;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Net::TAP::VERSION = '5.0.9';
use 5.010;
use strict;
use warnings;

use Moose::Role;

requires 'testrun', 'cfg', 'log';


sub prc_headerlines {
        my ($self, $prc_number) = @_;

        my $hostname = $self->associated_hostname;

        my $testrun_id = $self->testrun->id;
        my $testplan_id = $self->cfg->{testplan}{id} // '';
        my $suitename =  ($prc_number > 0) ? "Guest-Overview-$prc_number" : "PRC0-Overview";

        my $headerlines = [
                           "# Test-reportgroup-testrun: $testrun_id",
                           ( $testplan_id ? "# Test-testplan-id: $testplan_id" : ()),
                           "# Test-suite-name: $suitename",
                           "# Test-suite-version: $Tapper::MCP::VERSION",
                           "# Test-machine-name: $hostname",
                           "# Test-section: prc-state-details",
                           "# Test-reportgroup-primary: 0",
                          ];
        return $headerlines;
}



sub tap_report_away
{
        my ($self, $tap) = @_;
        my $reportid;
        if (my $sock = IO::Socket::INET->new(PeerAddr => $self->cfg->{report_server},
                                             PeerPort => $self->cfg->{report_port},
                                             Proto    => 'tcp')) {
                eval{
                        my $timeout = 100;
                        local $SIG{ALRM}=sub{die("timeout for sending tap report ($timeout seconds) reached.");};
                        alarm($timeout);
                        ($reportid) = <$sock> =~m/(\d+)$/g;
                        $sock->print($tap);
                };
                alarm(0);
                $self->log->error($@) if $@;
                close $sock;
        } else {
                return(1,"Can not connect to report server: $!");
        }
        return (0,$reportid);

}


sub tap_report_send
{
        my ($self, $reportlines, $headerlines) = @_;
        my $tap = $self->tap_report_create($reportlines, $headerlines);
        $self->log->debug($tap);
        return $self->tap_report_away($tap);
}


sub associated_hostname
{
        my ($self) = @_;
        my $hostname;

        eval {
                # parts of this chain may not exists and thus thow an exception
                $hostname = $self->testrun->testrun_scheduling->host->name;
                };
        return ($hostname // 'No hostname set');
}



sub mcp_headerlines {
        my ($self) = @_;

        my $topic = $self->testrun->topic_name() || $self->testrun->shortname();
        $topic =~ s/\s+/-/g;
        my $hostname = $self->associated_hostname();
        my $testrun_id = $self->testrun->id;
        my $testplan_id = $self->cfg->{testplan}{id} // '';

        my $headerlines = [
                           "# Test-reportgroup-testrun: $testrun_id",
                           ( $testplan_id ? "# Test-testplan-id: $testplan_id" : ()),
                           "# Test-suite-name: Topic-$topic",
                           "# Test-suite-version: $Tapper::MCP::VERSION",
                           "# Test-machine-name: $hostname",
                           "# Test-section: MCP overview",
                           "# Test-reportgroup-primary: 1",
                          ];
        return $headerlines;
}


sub tap_report_create
{
        my ($self, $reportlines, $headerlines) = @_;
        my @reportlines  = @$reportlines;
        my $message;
        $message .= "1..".($#reportlines+1)."\n";

        foreach my $line (map { chomp; $_ } @$headerlines) {
                $message .= "$line\n";
        }

        # @reportlines starts with 0, reports start with 1
        for (my $i=1; $i<=$#reportlines+1; $i++) {
                $message .= "not " if $reportlines[$i-1]->{error};
                $message .="ok $i - ";
                $message .= $reportlines[$i-1]->{msg} if $reportlines[$i-1]->{msg};
                $message .="\n";

                $message .= "# ".$reportlines[$i-1]->{comment}."\n"
                  if $reportlines[$i-1]->{comment};
        }
        return ($message);
}



sub upload_files
{
        my ($self, $reportid, $testrunid) = @_;
        my $host = $self->cfg->{report_server};
        my $port = $self->cfg->{report_api_port};

        my $outputdir = $self->cfg->{paths}{output_dir};
        my $path = "$outputdir/$testrunid/";
        return 0 unless -d $path;
        my @files=`find $path -type f`;
        $self->log->debug(@files);
        foreach my $file(@files) {
                chomp $file;
                my $reportfile=$file;
                $reportfile =~ s|^$path||;
                #$reportfile =~ s|^./||;
                #$reportfile =~ s|[^A-Za-z0-9_-]|_|g;
                my $cmdline =  "#! upload $reportid ";
                $cmdline   .=  $reportfile;
                $cmdline   .=  " plain\n";

                my $server = IO::Socket::INET->new(PeerAddr => $host,
                                                   PeerPort => $port);
                return "Cannot open remote receiver $host:$port" if not $server;

                open(my $FH, "<",$file) or do{$self->log->warn("Can't open $file:$!"); $server->close();next;};
                $server->print($cmdline);
                while (my $line = <$FH>) {
                        $server->print($line);
                }
                close($FH);
                $server->close();
        }
        system(qq{find "$outputdir" -maxdepth 1 -type d -mtime +30 -exec rm -fr \\{\\} \\;});
        return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Net::TAP

=head2 prc_headerlines

Generate header lines for the TAP report containing the results of the
PRC with the number provided as argument.

=head2 tap_report_away

Actually send the tap report to receiver.

@param string - report to be sent

@return success - (0, report id)
@return error   - (1, error string)

=head2 tap_report_send

Send information of current test run status to report framework using TAP
protocol.

@param array -  report array
@param array - header lines

@return success - (0, report id)
@return error   - (1, error string)

=head2 associated_hostname

Return the name of the host associated to this testrun or 'No hostname
set'.

@return string - hostname

=head2 suite_headerlines

Generate TAP header lines for the main MCP report.

@param int - testrun id

@return array ref - header lines

=head2 tap_report_create

Create a report string from a report in array form. Since the function only
does data transformation, no error should ever occur.

@param array ref - report array
@param array ref - header lines

@return report string

=head2 upload_files

Upload files written in one stage of the testrun to report framework.

@param int - report id
@param int - testrun id

@return success - 0
@return error   - error string

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
