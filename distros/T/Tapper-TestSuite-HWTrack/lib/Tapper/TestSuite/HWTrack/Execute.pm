## no critic (RequireUseStrict)
package Tapper::TestSuite::HWTrack::Execute;
BEGIN {
  $Tapper::TestSuite::HWTrack::Execute::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::TestSuite::HWTrack::Execute::VERSION = '4.1.1';
}
# ABSTRACT: Support package for Tapper::TestSuite::HWTrack

        use 5.010;
        use Moose;

        use File::Temp 'tempfile';
        use IO::Select;
        use IO::Socket::INET;
        use Sys::Hostname;
        use XML::Simple;
        use YAML;

        has dst    => ( is => 'rw');


        sub generate {
                my ($self) = @_;

                my (undef, $file) = tempfile( CLEANUP => 1 );
                my $lshw = "lshw";
                my $exec = "$lshw -xml > $file";
                system($exec); # can't use Tapper::Base->log_and_exec since
                               # this puts STDERR into the resulting XML file
                               # which in turn becomes invalid XML
                return $self->gen_report($file);
        }


        sub gen_report {
                my ($self, $file) = @_;

                my $test_run = $ENV{TAPPER_TESTRUN};
                my $hostname = $ENV{TAPPER_HOSTNAME} || Sys::Hostname::hostname();
                my $xml      = XML::Simple->new(ForceArray => 1);
                my $data     = $xml->XMLin($file);
                my $yaml     = Dump($data);
                $yaml       .= "...\n";
                $yaml        =~ s/^(.*)$/  $1/mg;  # indent
                my $report   = sprintf("
TAP Version 13
1..2
# Tapper-Reportgroup-Testrun: %s
# Tapper-Suite-Name: HWTrack
# Tapper-Machine-Name: %s
# Tapper-Suite-Version: %s
ok 1 - Getting hardware information
%s
ok 2 - Sending
", $test_run, $hostname, $Tapper::TestSuite::HWTrack::VERSION, $yaml);
                return $report;
        }



        sub send {
                my ($self, $report) = @_;

                my $cfg;
                $cfg->{report_server}   = $ENV{TAPPER_REPORT_SERVER};
                $cfg->{report_api_port} = $ENV{TAPPER_REPORT_API_PORT};
                $cfg->{report_port}     = $ENV{TAPPER_REPORT_PORT};

                print STDERR "host:port = ".$cfg->{report_server}.":".$cfg->{report_port};
                # following options are not yet used in this class
                $cfg->{mcp_server}      = $ENV{TAPPER_SERVER};
                $cfg->{runtime}         = $ENV{TAPPER_TS_RUNTIME};

                my $sock = IO::Socket::INET->new(PeerAddr => $cfg->{report_server},
                                                 PeerPort => $cfg->{report_port},
                                                 Proto    => 'tcp');
                unless ($sock) { die "Can't open connection to ", $cfg->{report_server}, ":", $cfg->{report_port}, ": $!" }
                my $select = IO::Select->new();
                $select->add($sock);
                my $remaining = length($report);
                say STDERR "\n$remaining";
                my $offset    = 0;
                while ($remaining and $select->can_write()) {
                        my $written = syswrite($sock, $report, 1024, $offset);
                        $remaining -= $written;
                        $offset    += $written;
                }
                sleep 2;
                $sock->close;
                return 0;
        }

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::TestSuite::HWTrack::Execute - Support package for Tapper::TestSuite::HWTrack

=head2 generate

Generate lshw output and return it as a report string

@return success - report string

@return error   - undef

=head2 gen_report

Generate a report based upon the XML formatted data found in the
file given as parameter

@param string - file name

@return success - report string
@return error   - undef

=head2 gen_error

Generate an error report based upon given error string
the file given as parameter

@param string - error string

@return success - report string

@return error   - undef

        sub gen_error {
                my ($self, $error) = @_;

                my $test_run = $ENV{TAPPER_TESTRUN};
                my $hostname = $ENV{TAPPER_HOSTNAME};
                my $yaml     = Dump({error => $error});
                $yaml       .= "...\n";
                $yaml        =~ s/^(.*)$/  $1/mg;  # indent
                my $report   = sprintf("
TAP Version 13
1..2
# Tapper-Reportgroup-Testrun: %s
# Tapper-Suite-Name: HWTrack
# Tapper-Machine-Name: %s
# Tapper-Suite-Version: %s
not ok 1 - Generating lshw executable
%s
ok 2 - Sending
", $test_run, $hostname, $Tapper::TestSuite::HWTrack::VERSION, $yaml);
                return $report;
        }

=head2 send

Send a given report to report receiver.

@param string - report

@return success - 0

@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

