package Tapper::TestSuite::Netperf::Client;
BEGIN {
  $Tapper::TestSuite::Netperf::Client::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::TestSuite::Netperf::Client::VERSION = '4.1.1';
}
# ABSTRACT: Tapper - Network performance measurements - Client

        use Moose;
        extends 'Tapper::TestSuite::Netperf';
        use IO::Socket::INET;
        use YAML;

        our $netperf_desc = "benchmarks-netperf";


        sub tap_report_away {
                my ($self, $tap) = @_;

                my $reportid;
                if (my $sock = IO::Socket::INET->new(PeerAddr => $ENV{TAPPER_REPORT_SERVER},
                                                     PeerPort => $ENV{TAPPER_REPORT_PORT},
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


        sub tap_report_send {
                my ($self, $report) = @_;

                my $tap = $self->tap_report_create($report);
                $self->log->debug($tap);
                return $self->tap_report_away($tap);
        }



        sub tap_report_create {
                my ($self, $report) = @_;

                my @report   = @$report;
                my $hostname = $ENV{TAPPER_HOSTNAME};
                my $testrun  = $ENV{TAPPER_TESTRUN};
                $hostname = $hostname // 'No hostname set';
                my $message;
                $message .= "1..".scalar @report."\n";
                $message .= "# Tapper-reportgroup-testrun: $testrun\n";
                $message .= "# Tapper-suite-name: Netperf\n";
                $message .= "# Tapper-suite-version: $Tapper::TestSuite::Netperf::VERSION\n";
                $message .= "# Tapper-machine-name: $hostname\n";

                # @report starts with 0, reports start with 1
                for (my $i=0; $i<=$#report; $i++) {
                        chomp($report[$i]);
                        $message .="$report[$i]\n";
                }
                return ($message);
        }



        sub get_bandwidth {
                my ($self, $socket) = @_;

                my ($buf1, $buf2, $start_time, $end_time, $msg, $size);
                my $offset=0; # get rid of warning

                $size           = 1024*1024*32;
                $buf1           = 'U'x($size);
                $start_time     = time();
                my $tmpbuf;
                while ($offset < length($buf1)) {
                        $offset += $socket->syswrite($buf1, 1024, $offset);
                        $socket->sysread($tmpbuf, 1024);
                        $buf2  .= $tmpbuf;
                }
                $end_time = time();
                $end_time++ if not $end_time > $start_time;
                $msg      = 'not ' unless $buf1 eq $buf2;
                $msg     .= "ok - benchmarks-custom";
                $msg     .= "\n   ---";
                $msg     .= "\n   bytes_per_second: "; $msg .= ($size)/(($end_time-$start_time)*1.0);
                $msg     .= "\n   length_send_buffer: "; $msg .= length($buf1);
                $msg     .= "\n   length_receive_buffer: "; $msg .= length($buf2);
                $msg     .= "\n   ...\n";
                return $msg;
        }


        sub parse_netperf {
                my ($self, $server, $netperf_file) = @_;

                my $output = `$netperf_file -P0 $server`;
                if ($output !~ m/^[0-9. ]+$/) {
                        $output =~ s/\n/\n#/gx;
                        return "not ok - $netperf_desc\n#$output";

                }
                $output=~s|^\s*(\S)|$1|;
                my @output = split /\s+/,$output;

                return "ok - $netperf_desc
   ---
   recv_socket_size_bytes: $output[0]
   send_socket_size_bytes: $output[1]
   send_message_size_bytes: $output[2]
   time: $output[3]
   throughput: $output[4]
   ...
";
        }



        sub run
        {
                my ($self) = @_;

                my $config_file = $ENV{TAPPER_SYNC_FILE};
                return "Config file is not set" if not $config_file;

                my @report;
                my $peers = YAML::LoadFile($config_file);
                # even though, server and client are synced by PRC, the
                # server may take a little more time to set up than the
                # client so give it some extra time
                sleep(2);
                my $socket = IO::Socket::INET->new(PeerHost => $peers->[0], PeerPort => 5000);
                my $msg;
                $msg  = 'not ' if not $socket;
                $msg .= "ok - Connect to peer";
                push @report, $msg;

                $msg = $self->get_bandwidth($socket);
                push @report, $msg;

                my $netperf_file = `which netperf`;
                chomp($netperf_file);
                if (-e $netperf_file) {
                        $msg = $self->parse_netperf($peers->[0], $netperf_file);
                        push @report, $msg;
                }
                else {
                        push @report, 'not ok - $netperf_desc # SKIP no netperf available in PATH';
                }

                my ($fail, $retval) = $self->tap_report_send(\@report);
                return $retval if $fail;
                return 0;
        }

1;



=pod

=encoding utf-8

=head1 NAME

Tapper::TestSuite::Netperf::Client - Tapper - Network performance measurements - Client

=head1 SYNOPSIS

You most likely want to run the frontend cmdline tool like this

  # host 1
  $ tapper-testsuite-netperf-server

  # host 2
  $ tapper-testsuite-netperf-client

=head1 METHODS

=head2 tap_report_away

Actually send the tap report to receiver.

@param string - report to be sent

@return success - (0, report id)
@return error   - (1, error string)

=head2 tap_report_send

Send information of current test run status to report framework using TAP
protocol.

@param array -  report array

@return success - (0, report id)
@return error   - (1, error string)

=head2 tap_report_create

Create a report string from a report in array form. Since the function only
does data transformation, no error should ever occur.

@param int   - test run id
@param array -  report array

@return report string

=head2 get_bandwidth

Get network bandwidth on network to server given as network socket.

@param socket  - connected to server

@return string - report message string

=head2 parse_netperf

Parse output of netperf command.

=head2 run

Run the netperf client.

@param

@return success - 0
@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut


__END__

