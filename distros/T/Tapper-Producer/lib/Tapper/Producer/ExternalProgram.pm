## no critic (RequireUseStrict)
package Tapper::Producer::ExternalProgram;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: produce preconditions via external program
$Tapper::Producer::ExternalProgram::VERSION = '5.0.1';
use Moose;
use File::Temp 'tempfile';
use YAML       'Load';
use Tapper::Config;
use Try::Tiny;


sub produce
{
        my ($self, $job, $produce) = @_;

        my $program = $produce->{program};

        my %environment = %{$produce->{environment} || {}};
        my @parameters  = @{$produce->{parameters}  || []};

        # provide Tapper config
        my $cfg = Tapper::Config->subconfig;
        $ENV{TAPPER_SERVER}          = $cfg->{mcp_server};
        $ENV{TAPPER_SERVER_PORT}     = $cfg->{mcp_port};
        $ENV{TAPPER_REPORT_SERVER}   = $cfg->{report_server};
        $ENV{TAPPER_REPORT_PORT}     = $cfg->{report_port};
        $ENV{TAPPER_REPORT_API_PORT} = $cfg->{report_api_port};

        # provide Job details
        $ENV{TAPPER_HOSTNAME}        = $job->host->name;
        $ENV{TAPPER_TESTRUN}         = $job->testrun_id;
        $ENV{TAPPER_TESTPLAN}        = $job->testrun->testplan_id;

        # provide precondition "environment" details
        $ENV{$_} = $environment{$_} foreach keys %environment;

        # doing all in one qx() allows use of shell - benefit or hazard?
        my $cmd = join(" ", $program, @parameters);
        my $precondition = qx($cmd);

        # error handling
        if ($?) {
                my $error_msg = "ExternalProgram error.\n";
                $error_msg   .= "Error code: $?\n";
                $error_msg   .= "Error message: $precondition\n";
                die $error_msg;
        }

        # validation
        try { Load($precondition) } catch { die "Generated precondition not loadable: $_\n\n$precondition:\n"};

        return { precondition_yaml => $precondition };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Producer::ExternalProgram - produce preconditions via external program

=head2 produce

Call an external program, provide cmdline params and env vars to it.
The external program is responsible for everything else.

@param Job object - the job we build a package for
@param hash ref   - producer precondition

@return success - hash ref containing list of new preconditions

@throws die()

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
