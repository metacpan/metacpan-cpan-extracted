#ABSTRACT: NBI Slurm module
use strict;
use warnings;

package NBI::Slurm;
use NBI::Job;
use NBI::Opts;
use base qw(Exporter);
our @ISA = qw(Exporter);
our @EXPORT = qw(Job Opts load_config has_squeue timelog execute_command %FORMAT_STRINGS);

$NBI::Slurm::VERSION = '0.14.0';




our %FORMAT_STRINGS = (
 'account'    => '%a',
 'jobid'      => '%A',
 'jobname'    => '%j',
 'cpus'       => '%C',
 'end_time'   => '%E',
 'start_time' => '%S',
 'total_time' => '%l',
 'time_left'  => '%L',
 'memory'     => '%m',
 'command'    => '%o',
 'queue'      => '%P',
 'reason'     => '%r',
 'status'     => '%T', # short: %t
 'workdir'    => '%Z',
 'user'       => '%u',
);

sub execute_command {
    my ($command) = @_;
    
    # Use File::Temp functionality available in core Perl
    use File::Temp qw(tempfile);
    
    # Create temporary files for capturing output
    my ($stdout_fh, $stdout_file) = tempfile(UNLINK => 1);
    my ($stderr_fh, $stderr_file) = tempfile(UNLINK => 1);
    close($stdout_fh);  # Close handles so system() can write to files
    close($stderr_fh);
    
    # Execute command with output redirection
    my $full_command = "$command >$stdout_file 2>$stderr_file";
    system($full_command);
    
    # Capture exit code (system() returns exit code << 8)
    my $exit_code = $? >> 8;
    
    # Read stdout
    my $stdout = '';
    if (open(my $stdout_read_fh, '<', $stdout_file)) {
        $stdout = do { local $/; <$stdout_read_fh> };
        close($stdout_read_fh);
    }
    
    # Read stderr  
    my $stderr = '';
    if (open(my $stderr_read_fh, '<', $stderr_file)) {
        $stderr = do { local $/; <$stderr_read_fh> };
        close($stderr_read_fh);
    }
    
    # Files are automatically cleaned up due to UNLINK => 1
    
    return {
        stdout    => $stdout,
        stderr    => $stderr,
        exit_code => $exit_code
    };
}

sub load_config {
    my $filename = shift;
    if (! $filename) {
        $filename = "$ENV{HOME}/.nbislurm.config";
    }
    my $config = {};
    if (! -e "$filename") {
        say STDERR "# Config file not found: $filename" if ($ENV{"DEBUG"});
        return $config;
    }
    open(my $fh, "<", $filename) or die "Cannot open $filename: $!";
    while (<$fh>) {
        chomp;
        next if (/^\s*$/);
        next if (/^#/);
        next if (/^;/);
        my ($key, $value) = split(/=/, $_);
        # discard keys with spaces
        next if ($key =~ /\s/);
        $config->{$key} = $value;
    }
    close  $fh;
    return $config;
}


sub has_squeue {
    my $cmd = "squeue --version";
    my $output = `$cmd 2>&1`;
    if ($? == 0) {
        return 1;
    } else {
        return 0;
    }
}

sub queues {
  my $can_fail = shift;
  # Retrieve queues from SLURM
  my $has_sinfo = undef;
  eval {
    $has_sinfo = `sinfo --version > /dev/null 2>&1`;
  };
  
  chomp($has_sinfo) if defined $has_sinfo;
  if (not defined $has_sinfo and ! $can_fail) {
    Carp::croak "ERROR NBI::Slurm: sinfo failed. Are you in a SLURM cluster?\n";
  }
  my $cmd = "timeout 5s sinfo --format '%P' --noheader";
  my @output = `$cmd 2>/dev/null`;
  if ($? != 0 and ! $can_fail) {
    Carp::croak "ERROR NBI::Slurm: sinfo did not find queues. Are you in a SLURM cluster?\n";
  }
 
  chomp @output;
  return @output;
}

sub valid_queue {
  if ($ENV{'SKIP_SLURM_CHECK'}) {
    return 1;
  }
  my $queue = shift;
  my @queues = queues('CAN_FAIL');
  my @input_queues = split(/,/, $queue);

  if (scalar(@input_queues) == 0) {
    # Let's assume it exists... TODO CHECK
    return  1;
  }
  foreach my $input_queue (@input_queues) {
    if (! grep { $_ eq $input_queue } @queues) {
      return 0;
    }
  }
  return 1;
}


sub days_since_update {
    my $file_path = shift;

    # Check if the required modules can be loaded
    eval {
        require File::Spec;
        require Time::Piece;
        require Time::Seconds;
    };
    if ($@) {
        return -1;  # Failed to load required module(s)
    }

    # Check if the file exists
    unless (-e $file_path) {
        return -1;  # File not found
    }

    # Get the file's last modification time
    my $last_modified = (stat($file_path))[9];

    # Calculate the number of days since the last modification
    my $current_time = time();
    my $days_since_update = int(($current_time - $last_modified) / (24 * 60 * 60));

    return $days_since_update;
}

sub timelog {
    my $tag = shift;
    $tag = "nbi-slurm" unless defined $tag;
    my ($sec, $min, $hour, $day, $month, $year) = localtime(time);
    $year += 1900;  # Adjust year (localtime returns years since 1900)
    $month += 1;    # Adjust month (localtime returns 0-11)
    
    # Format with leading zeros
    return sprintf("[%s:%04d-%02d-%02d %02d:%02d:%02d]\t", 
            $tag, $year, $month, $day, $hour, $min, $sec);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Slurm - NBI Slurm module

=head1 VERSION

version 0.14.0

=head1 SYNOPSIS

Submit jobs to SLURM using the L<NBI::Job> and L<NBI::Opts> classes.

  use NBI::Slurm;

Create options for the job:

  my $opts = NBI::Opts->new(
    -queue => "short",
    -threads => 4,
    -memory => 8,
);

Create a job, using the options:

  my $job = NBI::Job->new(
    -name => "job-name",
    -command => "ls -l", 
    -opts => $opts,
  );

Submit the job to SLURM

  my $jobid = $job->run;

This package comes with a set of executable utilities.

=head1 DESCRIPTION

The C<NBI::Slurm> package provides a set of classes and methods for submitting jobs to SLURM, a workload manager for high-performance computing (HPC) clusters. It includes the L<NBI::Job> and C<NBI::Opts> classes, which allow you to define and configure jobs to be submitted to SLURM.

The L<NBI::Job> class represents a job to be submitted to SLURM. 
It provides methods for setting the job name, defining the commands to be executed, setting the output and error file paths, and submitting the job to SLURM. 

The L<NBI::Opts> class represents the SLURM options for the job, such as the queue, number of threads, allocated memory, and execution time. It allows you to configure these options and generate the SLURM header for the job script.

By combining the NBI::Job and NBI::Opts classes, you can easily create and submit jobs to SLURM. 
The C<NBI::Slurm> package provides a convenient interface for interacting with SLURM and managing HPC jobs.

=head1 INTRODUCTION

=head2 HPC

I<High-Performance Computing> (HPC) refers to the use of powerful computing systems to solve complex problems that require significant computational resources. 
An B<HPC cluster> typically consists of multiple interconnected computers, referred to as nodes, which work together to perform computational tasks efficiently. The cluster includes a head node, which serves as the central control point for managing the cluster and handling job submissions. 

The I<head node> is responsible for coordinating the execution of jobs, scheduling resources, and distributing them among the execution nodes. Execution nodes, also known as compute nodes, are the workhorses of the cluster, performing the actual computations requested by users' jobs. These nodes are equipped with high-performance processors, large amounts of memory, and fast interconnects to ensure rapid data transfer and efficient parallel processing. 

By leveraging the combined power of the head node and execution nodes, HPC systems provide researchers and scientists with the capability to tackle computationally demanding tasks, such as large-scale simulations, data analysis, and modeling, to accelerate scientific discoveries and innovation.

=head2 SCHEDULERS

I<Schedulers> are an integral component of High-Performance Computing (HPC) systems, responsible for managing and allocating computing resources efficiently among multiple users and their jobs. 

HPC schedulers optimize resource utilization, minimize job waiting times, and ensure fair access to the available resources. 

One popular scheduler used in HPC environments is B<SLURM> (Simple Linux Utility for Resource Management). SLURM is an open-source, highly scalable, and flexible job scheduler that provides a comprehensive set of features for job submission, resource allocation, job prioritization, and job accounting. It offers a powerful command-line interface and extensive configuration options, making it suitable for a wide range of HPC clusters and workload management scenarios. 

SLURM's design philosophy focuses on scalability, fault-tolerance, and extensibility, making it a popular choice for many research institutions and supercomputing centers.

=head1 METHODS

=over 4

=item * B<load_config>

Load configuration from a file.

=item * B<has_squeue>

Check if the squeue command is available.

=item * B<queues>

Retrieve queues from SLURM.

=item * B<valid_queue>

Check if a queue is valid.

=item * B<days_since_update>

Calculate the number of days since a file was last modified.

=item * B<execute_command>

Execute a system command and capture its stdout, stderr, and exit code.
Returns a hash reference with keys: stdout, stderr, exit_code.

=back

=head1 CLASSES

The C<NBI::Slurm> package includes the following classes:

=over 4

=item * L<NBI::Job>: Represents a job to be submitted to SLURM.

=item * L<NBI::Opts>: Represents the SLURM options for a job.

=back

=head1 FUNCTIONS

The C<NBI::Slurm> package provides the following functions:

=over 4

=item * B<timelog(str)>: Generate a timestamp for logging purposes, with an optional tag (string)

=back

Please refer to the documentation for each class for more information on their methods and usage.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
