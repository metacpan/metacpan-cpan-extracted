package Tapper::Remote::Net;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Remote::Net::VERSION = '5.0.0';
use strict;
use warnings;

use Moose::Role;

requires qw(cfg log);

use IO::Socket::INET;
use YAML::Syck;
use URI::Escape;


sub mcp_inform
{

        my ($self, $msg) = @_;

        $msg = {state => $msg} if not ref($msg) eq 'HASH';

        # set PRC number
        if ($self->cfg->{guest_number}) {
                $msg->{prc_number} = $self->{cfg}->{guest_number};
        } else {
                # guest numbers start with 1, 0 is host or no virtualisation
                $msg->{prc_number} = 0;
        }
        return $self->mcp_send($msg);
};



sub mcp_send
{
        my ($self, $message) = @_;
        my $server = $self->cfg->{mcp_host} || $self->cfg->{mcp_server} or return "MCP host unknown";
        my $port   = $self->cfg->{mcp_port} || $self->cfg->{port}       or return "MCP port unknown";
        $message->{testrun_id} ||= $self->cfg->{testrun_id} || $self->cfg->{test_run};
        my %headers;

        my $url = "GET /state/";

        # state always needs to be first URL part because server uses it as filter
        $url   .= $message->{state} || 'unknown';
        delete $message->{state};

        foreach my $key (keys %$message) {
                if ($message->{$key} =~ m|/| ) {
                        $headers{$key} = $message->{$key};
                } else {
                        $url .= "/$key/";
                        $url .= uri_escape($message->{$key});
                }
        }
        $url .= " HTTP/1.0\r\n";
        foreach my $header (keys %headers) {
                $url .= "X-Tapper-$header: ";
                $url .= $headers{$header};
                $url .= "\r\n";
        }

        $self->log->info("Sending $url to $server");
        if (my $sock = IO::Socket::INET->new(PeerAddr => $server,
                                             PeerPort => $port,
                                             Proto    => 'tcp')){
                $sock->print("$url\r\n");
                close $sock;
        } else {
                $self->log->error("Can't connect to MCP on $server:$port: $@");
                return("Can't connect to MCP: $!");
        }
        return(0);
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



sub tap_report_create
{
        my ($self, $report) = @_;
        my $message;
        my @tests = @{$report->{tests}};

        $message .= "1..".int (@tests);
        $message .= "\n";
        foreach my $header (keys %{$report->{headers}}) {
                $message .= "# $header: ";
                $message .= $report->{headers}->{$header};
                $message .= "\n";
        }

        # @tests starts with 0, reports start with 1
        for (my $i=1; $i<=@tests; $i++) {
                $message .= "not " if $tests[$i-1]->{error};
                $message .="ok $i - ";
                $message .= $tests[$i-1]->{test} if $tests[$i-1]->{test};
                $message .="\n";
        }
        return ($message);
}


sub nfs_mount
{
        my ($self) = @_;
        my ($error, $retval);
        $error = $self->makedir($self->cfg->{paths}{prc_nfs_mountdir});
        return $error if $error;

        ($error, $retval) = $self->log_and_exec("mount",
                                                $self->cfg->{prc_nfs_server}.":".$self->cfg->{paths}{prc_nfs_mountdir},
                                                $self->cfg->{paths}{prc_nfs_mountdir});
        return "Can't mount ".$self->cfg->{paths}{prc_nfs_mountdir}.":$retval" if $error;
        return 0;
}


sub log_to_file
{

        my ($self, $state) = @_;
        my $output = $self->cfg->{paths}{output_dir};
        $output   .= "/".($self->cfg->{testrun_id} || $self->cfg->{test_run});
        $output   .= "/$state";

        my $error  = $self->makedir ($output);
        return $error if $error;

        $output   .= "/Tapper";
        open (STDOUT, ">>", "$output.stdout") or $self->logdie("Can't open output file $output.stdout: $!");
        open (STDERR, ">>", "$output.stderr") or $self->logdie("Can't open output file $output.stderr: $!");
        return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Remote::Net

=head1 SYNOPSIS

 use Tapper::Remote::Net;

=head1 NAME

Tapper::Remote::Net - Communication with MCP

=head1 FUNCTIONS

=head2 mcp_inform

Generate the message to be send to MCP and hand it over to mcp_send.
If the message is given as string its converted to hash.

@param string or hash reference - message to send to MCP

@return success - 0
@return error   - error string

=head2 mcp_send

Tell the MCP server our current status. This is done using a HTTP request.

@param hash ref - message to send to MCP

@return success - 0
@return error   - error string

=head2 tap_report_away

Actually send the tap report to receiver.

@param string - report to be sent

@return success - (0, report id)
@return error   - (1, error string)

=head2 tap_report_create

Create a report string from a report in hash form. Since the function only
does data transformation, no error should ever occur.
The expected hash should contain the following keys:
* tests    - contains an array of hashes with
** error   - indicated whether this test failed (if true)
** test    - description of the test
* headers  - Tapper headers with values
* sections - array of hashes containing tests and headers ad described above and
             a section_name

@param hash ref -  report data

@return report string

=head2 nfs_mount

Mount the output directory from an NFS server. This method is used since we
only want to mount this NFS share in live mode.

@return success - 0
@return error   - error string

=head2 log_to_file

Turn stdout and stderr into files. This way we get output that would
otherwise be lost. The function expects a state that will be used.

@param string - state

@return success - 0
@return error   - string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
