package Tapper::SimNow;
# git description: v4.1.0-1-gefbd11b

BEGIN {
  $Tapper::SimNow::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::SimNow::VERSION = '4.1.1';
}
# ABSTRACT: Tapper - Support for running SimNow sessions

use Moose;
use common::sense;

use File::Basename;

use Tapper::Remote::Config;
use Tapper::Remote::Net;

extends 'Tapper::Base';

has cfg => (is      => 'rw',
            isa     => 'HashRef',
            default => sub { {} },
           );



sub get_static_tap_headers
{
        my ($self, $report) = @_;
        $report->{headers}{'Tapper-reportgroup-testrun'} = $self->cfg->{test_run};
        $report->{headers}{'Tapper-suite-name'}          = "SimNow-Metainfo";
        $report->{headers}{'Tapper-suite-version'}       = $Tapper::SimNow::VERSION;
        $report->{headers}{'Tapper-machine-name'}        = $self->cfg->{hostname};
        return $report;
}


sub generate_meta_report
{

        my ($self) = @_;
        my $report;
        $report = $self->get_static_tap_headers($report);

        my $error  = 0;
        my ($success, $retval) = $self->log_and_exec($self->cfg->{paths}->{simnow_path}."/simnow","--version");
        if ($success) {
                push @{$report->{tests}}, {error => 1, test => "Getting SimNow version"};
        } else {
                push @{$report->{tests}}, {test => "Getting SimNow version"};

                if ($retval =~ m/This is AMD SimNow version (\d+\.\d+\.\d+(-NDA)?)/) {
                        $report->{headers}{'Tapper-SimNow-Version'} = $1;
                } else {
                        $report->{headers}{'Tapper-SimNow-Version'} = 'Not set';
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Parsing SimNow version"};


                $error = 0;
                if ($retval =~ m/This internal release is built from revision: (.+) of SVN URL: (.+)/) {
                        $report->{headers}{'Tapper-SimNow-SVN-Version'}    =  $1;
                        $report->{headers}{'Tapper-SimNow-SVN-Repository'} =  $2;
                } elsif ($retval =~ m/Build number: (.+)/) {
                        $report->{headers}{'Tapper-SimNow-SVN-Version'}    =  $1;
                        $report->{headers}{'Tapper-SimNow-SVN-Repository'} =  'Not set';
                } else {
                        $report->{headers}{'Tapper-SimNow-SVN-Version'}    =  'Not set';
                        $report->{headers}{'Tapper-SimNow-SVN-Repository'} =  'Not set';
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Parsing SVN version"};

                $error = 0;
                if ($retval =~ m/supporting version (\d+) of the AMD SimNow Device Interface/) {
                        $report->{headers}{'Tapper-SimNow-Device-Interface-Version'} = $1;
                } else {
                        $report->{headers}{'Tapper-SimNow-Device-Interface-Version'} = 'Not set';
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Parsing device interface version"};
        }

        $error = 0;
        if (open my $fh ,"<", $self->cfg->{files}{simnow_script}) {
                my $content = do {local $/; <$fh>};
                close $fh;

                if ($content =~ m|open bsds/(\w+)\.bsd|) {
                        $report->{headers}{'Tapper-SimNow-BSD-File'} = $1;
                } else {
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Getting BSD file information"};

                $error = 0;
                if ($content =~ m|ide:0.image master .*/((?:\w\|\.)+?)(?:\.[a-zA-Z]+)?$|m) {
                        $report->{headers}{'Tapper-SimNow-Image-File'} = $1;
                } else {
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Getting image file information"};

                $error = 0;
        } else {
                $report->{headers}{'Tapper-SimNow-BSD-File'} = 'Not set';
                $report->{headers}{'Tapper-SimNow-Image-File'} = 'Not set';
                $error = 1;
        }
        push @{$report->{tests}}, {error => $error, test => "Reading Simnow config file"};
        return $report;

}




sub create_console
{
        my ($self) = @_;
        $self->log->debug("Creating console links");
        my $test_run        = $self->cfg->{test_run};
        my $out_dir         = $self->cfg->{paths}{output_dir}."/$test_run/test/";
        $self->makedir($out_dir) unless -d $out_dir;
        my $outfile         = $out_dir."/simnow_console";

        # create the file, otherwise simnow can't write to it
        open my $fh, ">", $outfile or return "Can not open $outfile: $!";
        close $fh;

        my $pipedir         = dirname($self->cfg->{files}{simnow_console});
        $self->makedir($pipedir) unless -d $pipedir;
        my $retval          = $self->log_and_exec("ln","-sf", $outfile, $self->cfg->{files}{simnow_console});
        return $retval;
}



sub start_simnow
{
        my ($self) = @_;
        $self->log->debug("starting simnow");

        my $simnow_script   = $self->cfg->{files}{simnow_script};
        my $test_run        = $self->cfg->{test_run};
        my $out_dir         = $self->cfg->{paths}{output_dir}."/$test_run/test/";
        $self->makedir($out_dir) unless -d $out_dir;
        my $output          = $out_dir.'/simnow';

        open (STDOUT, ">>", "$output.stdout") or return("Can't open output file $output.stdout: $!");
        open (STDERR, ">>", "$output.stderr") or return("Can't open output file $output.stderr: $!");

        my $retval          = $self->run_one({command  => $self->cfg->{paths}->{simnow_path}."/simnow",
                                              argv     => [ "-e", $simnow_script, '--nogui' ],
                                              pid_file => $self->cfg->{paths}->{pids_path}."/simnow.pid",
                                             });
        return $retval;
}



sub start_mediator
{
        my ($self) = @_;
        $self->log->debug("starting mediator");

        my $retval = $self->run_one({command  => $self->cfg->{paths}->{simnow_path}."/mediator",
                                     pid_file => $self->cfg->{paths}->{pids_path}."/mediator.pid",
                                    });
        return $retval;
}




sub run
{
        my ($self) = @_;
        $self->log->info("Starting Simnow");

        my $consumer = Tapper::Remote::Config->new();
        my $config   = $consumer->get_local_data('simnow');
        die $config unless ref($config) eq 'HASH';
        my $net      = Tapper::Remote::Net->new($config);
        $self->cfg( $config );
        $net->mcp_inform("start-test");

        # simnow only runs in its own directory due to lib issues
        chdir $self->cfg->{paths}->{simnow_path};

        my $retval;
        {
                $retval = $self->kill_instance($self->cfg->{paths}->{pids_path}."/simnow.pid");
                last if $retval;

                $retval = $self->create_console();
                last if $retval;


                $retval = $self->start_mediator();
                last if $retval;

                $retval = $self->start_simnow();
                last if $retval;

                my $report = $self->generate_meta_report();
                my $tap = $net->tap_report_create($report);
                my $error;
                ($error, $retval) = $net->tap_report_away($tap);
                last if $error;

        }
        if ($retval) {
                $net->mcp_send({state => 'error-guest', error => $retval});
                $self->log->logdie($retval);
        }
        $net->mcp_inform("end-test");

        $self->log->info("Simnow prepared and running");
        return 0;
}

1; # End of Tapper::SimNow

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::SimNow - Tapper - Support for running SimNow sessions

=head1 SYNOPSIS

Tapper::SimNow controls running SimNow session with Tapper. With this
module Tapper is able to treat similar to virtualisation tests.

    use Tapper::SimNow;

    my $simnow = Tapper::SimNow->new();
    $simnow->run();

=head1 FUNCTIONS

=head2 get_static_tap_headers

Create a report hash that contains all headers that do not need to be
produced somehow. This includes suite-name and suite-version for
example.

@return string - tap headers

=head2 generate_meta_report

Generate a report containing metainformation about the SimNow we use.

@return hash ref - report data as expected by Remote::Net->tap_report_create()

=head2 create_console

Create console file for output of system under test in simnow.

@param hash ref - config

@return success - 0
@return error   - error string

=head2 start_simnow

Start the simnow process.

@param hash ref - config

@return success - 0
@return error   - error string

=head2 start_mediator

Start the mediator process.

@param hash ref - config

@return success - 0
@return error   - error string

=head2 run

Control a SimNow session. Handles getting config, sending status
messages to MCP and console handling.

@return success - 0
@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

