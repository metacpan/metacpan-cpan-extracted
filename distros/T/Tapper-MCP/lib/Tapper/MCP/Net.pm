package Tapper::MCP::Net;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Net::VERSION = '5.0.9';
use strict;
use warnings;
use English '-no_match_vars';

use 5.010;

use Moose;
use Socket;
use Net::SSH;
use Net::SCP;
use IO::Socket::INET;
use Sys::Hostname;
use File::Basename;
use YAML;

extends 'Tapper::MCP';

use Tapper::Model qw(model get_hardware_overview);



sub start_simnow
{
        my ($self, $hostname) = @_;

        my $simnow_installer = $self->cfg->{files}{simnow_installer};
        my $server = Sys::Hostname::hostname() || $self->cfg->{mcp_host};
        my $retval = Net::SSH::ssh("root\@$hostname",$simnow_installer, "--host=$server");
        return "Can not start simnow installer: $!" if $retval;


        $self->log->info("Simnow installation started on $hostname.");
        return 0;

}



sub start_ssh
{
        my ($self, $hostname) = @_;

        my $tapper_script = $self->cfg->{files}{tapper_prc};
        my $tftp_host = $self->cfg->{mcp_host};
        my $error = Net::SSH::ssh("$hostname","TAPPER_TEST_TYPE=ssh $tapper_script --host $tftp_host");
        return "Can not start PRC with ssh: $error" if $error;
        return 0;
}


sub start_local
{
        my ($self, $path_to_config) = @_;

        my $tapper_script = $self->cfg->{files}{tapper_prc};
        my $error = qx($tapper_script --config $path_to_config);
        return "Can not start PRC locally: $error" if $error;
        return 0;
}



sub wait_for_minion_job {
  my ($self, $testrun_id, $hostname) = @_;

  my $state = '';
  do {
    my $minion_cfg = $self->cfg->{minion}{frontend}{Minion};
    my $minion     = Minion->new(%$minion_cfg);
    my $backend    = $minion->backend;
    my $job        = $backend->list_jobs
      (0, 1,
       {
         tasks => ['tapper_testrun'],
         queues => [$hostname],
       })->{jobs}[0];

    # don't wait if already running different testrun?
    return if $job->{notes}{testrun_id} != $testrun_id;

    my $job_id = $job->{id};
    $state     = $job->{state};
    $self->log->debug("minion: wait for 'finished' ".
                      "job:$job_id testrun:$testrun_id host:$hostname state:$state");
    sleep 5;
  } while ($state ne 'finished');
}



sub start_minion
{
  my ($self, $path_to_config, $revive) = @_;

  require Minion;

  # Tapper details
  my $prc_cfg    = YAML::LoadFile($path_to_config);
  my $testrun_id = $prc_cfg->{testrun_id};
  my $hostname   = $prc_cfg->{hostname};

  # Minion details
  my $minion_cfg = $self->cfg->{minion}{frontend}{Minion};
  my $minion     = Minion->new(%$minion_cfg);
  my $backend    = $minion->backend;
  my $queue_name = $hostname; # Mapping Tapper <---> Minion

  # Potentially already running job
  my $last_job = $backend->list_jobs
    (0, 1, {
      tasks => ['tapper_testrun'],
      queues => [$queue_name],
    })->{jobs}[0];
  my $last_job_id =$last_job->{id};

  # Revive and corresponding job already running? Wait for it.
  if ($revive
        and $last_job->{notes}{testrun_id} == $testrun_id
        and $last_job->{state} ne 'finished' # or better eq 'active'?
      )
    {
      $self->log->debug("minion: revive - skip enqueue of testrun $testrun_id");
      return 0;
    }

  # Start job
  my @job_args = (prc_cfg => $prc_cfg);  # a "sorted hash"
  my $job_id = $minion->enqueue('tapper_testrun'
                                  => [@job_args]
                                  => { queue => $queue_name,
                                       notes => { testrun_id => $testrun_id },
                                     },
                              );
  $self->log->debug("minion: started job:$job_id testrun:$testrun_id host:$hostname");

  # TODO: error handling - what could go wrong?

  # success
  return 0;
}



sub stop_minion
{
  my ($self, $testrun_id, $hostname) = @_;

  require Minion;

  # Minion details
  my $minion_cfg = $self->cfg->{minion}{frontend}{Minion};
  my $minion     = Minion->new(%$minion_cfg);
  my $backend    = $minion->backend;
  my $queue_name = $hostname; # Mapping Tapper <---> Minion
  my $jobs       = $backend->list_jobs(0, 1, {
    tasks  => ['tapper_testrun'],
    queues => [$queue_name],
  });
  my $job_state    = $jobs->{jobs}[0]{state};
  my $job_id
      = $jobs->{jobs}[0]{id};
  my $job_testrun  = $jobs->{jobs}[0]{notes}{testrun_id};

  # Send Minion the 'stop' command;
  if ($job_testrun == $testrun_id) {
    $self->log->debug(
      "minion: CANCEL/STOP job:$job_id testrun:$job_testrun");
    $minion->broadcast('kill', ['INT', $job_id]);
  } else {
    $self->log->debug(
      "minion: NO CANCEL/STOP of job:$job_id testrun:$job_testrun != stopped testrun:$testrun_id");
  }

}


sub install_client_package
{
        my ($self, $hostname, $package) = @_;

        my $dest_path  = $package->{dest_path} || '/tmp';
        $dest_path .= "/tapper-clientpkg.tgz";

        my $arch = $package->{arch};
        return "No architecture defined. Can not install client package" if not $arch;
        my $clientpkg = $self->cfg->{files}{tapper_package}{$arch};

        $clientpkg = $self->cfg->{paths}{package_dir}.$clientpkg
          if not $clientpkg =~ m,^/,;

        my $scp     = Net::SCP->new($hostname);
        my $success = $scp->put(
                               $clientpkg,
                               $dest_path,
                              );
        return "Can not copy client package '$clientpkg' to $hostname:/$dest_path: ".$scp->{errstr} if not $success;

        my $error = Net::SSH::ssh("$hostname","tar -xzf $dest_path -C /");
        return "Can not unpack client package on $hostname: $!" if $error;
        return 0;
}



sub write_grub_file
{
        my ($self, $system, $text) = @_;
        return "No grub text given" unless $text;

        my $grub_file    = $self->cfg->{paths}{grubpath}."/$system.lst";
        $self->log->debug("writing grub file $grub_file");

        # create the initial grub file for installation of the test system,
        open (my $GRUBFILE, ">", $grub_file) or return "Can open ".$self->cfg->{paths}{grubpath}."/$system.lst for writing: $!";
        print $GRUBFILE $text;
        close $GRUBFILE or return "Can't save grub file for $system:$!";
        return(0);
}



sub hw_report_create
{
        my ($self, $testrun_id) = @_;
        my $testrun = model->resultset('Testrun')->find($testrun_id);
        my $host;
        eval {
                # parts of this chain may be undefined

                $host = $testrun->testrun_scheduling->host;
        };
        return (1, qq(testrun '$testrun_id' has no host associated)) unless $host;

        my $data = get_hardware_overview($host->id);
        my $yaml = Dump($data);
        $yaml   .= "...\n";
        $yaml =~ s/^(.*)$/  $1/mg;  # indent
        my $report = sprintf("
TAP Version 13
1..2
# Tapper-Reportgroup-Testrun: %s
# Tapper-Suite-Name: Hardwaredb Overview
# Tapper-Suite-Version: %s
# Tapper-Machine-Name: %s
ok 1 - Getting hardware information
%s
ok 2 - Sending
", $testrun_id, $Tapper::MCP::VERSION, $host->name, $yaml);

        return (0, $report);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Net

=head2 start_simnow

Start a simnow installation on given host. Installer is supposed to
start the simnow controller in turn.

@param string - hostname

@return success - 0
@return error   - error string

=head2 start_ssh

Start a ssh testrun on given host. This starts both the Installer and PRC.

@param string - hostname

@return success - 0
@return error   - error string

=head2 start_local

Start a testrun locally. This starts both the Installer and PRC.

@param string - path to config

@return success - 0
@return error   - error string

=head2 wait_for_minion_job

Wait until a Minion job reaches its 'finished' state.

@param string - path to config

@return success - 0
@return error   - error string

=head2 start_minion

Start a testrun via a Minion job. This just enqueues into a queue
named like the current TAPPER_HOSTNAME and assumes a Minion worker is
picking it up as soon as possible so all the timeout assumptions are
very similar to local execution, just with the difference of a job
queue between it to decouple the load between different Tapper client
hosts.

The config file is read into the corresponding data structure and
provided to the Minion as option hash. The Minion worker writes that
hash into a local temp file again and starts the PRC with that temp
file, very similar as start_local() does, just not on server but on
client side.

@param string - path to config

@return success - 0
@return error   - error string

=head2 stop_minion

Stop a testrun's corresponding Minion job.

This finds the queue named like the current TAPPER_HOSTNAME, queries
it for the current job, gets that jobs config, checks if it is for the
current testun and broadcast a 'stop' command to Minion.

The PRC Minion worker that gets the signal command does the actual
remote process cleanup.

@param string - path to config

@return success - 0
@return error   - error string

=head2 install_client_package

Install client package of given architecture on given host at optional
given possition.

@param string   - hostname
@param hash ref - contains arch and dest_path

@return success - 0
@return error   - error string

=head2 write_grub_file

Write the given text to the grub file for the system given as parameter.

@param string - name of the system
@param string - text to put into grub file

@return success - 0
@return error   - error string

=head2 hw_report_create

Create a report containing the test machines hw config as set in the hardware
db. Leave the sending to caller

@param int - testrun id

@return success - (0, hw_report)
@return error   - (1, error string)

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
