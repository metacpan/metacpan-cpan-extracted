package NBI::Job;
#ABSTRACT: A class for representing a job for NBI::Slurm

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
use File::Spec::Functions;
$Data::Dumper::Sortkeys = 1;
use File::Basename;

$NBI::Job::VERSION           = $NBI::Slurm::VERSION;
my $DEFAULT_QUEUE               = "nbi-short";
require Exporter;
our @ISA = qw(Exporter);


sub new {
    my $class = shift @_;
    my ($job_name, $commands_array, $command, $opts);

    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        my %data = @_;
        # Try parsing
        for my $i (keys %data) {
            if ($i =~ /^-name/) {
                $job_name = $data{$i};
            } elsif ($i =~ /^-command$/) {
                $command = $data{$i};
            } elsif ($i =~ /^-opts$/) {
                # Check that $data{$i} is an instance of NBI::Opts
                if ($data{$i}->isa('NBI::Opts')) {
                    # $data{$i} is an instance of NBI::Opts
                    $opts = $data{$i};
                } else {
                    # $data{$i} is not an instance of NBI::Opts
                    confess "ERROR NBI::Job: -opts must be an instance of NBI::Opts\n";
                }
                
            } elsif ($i =~ /^-commands$/) {
                # Check that $data{$i} is an array
                if (ref($data{$i}) eq 'ARRAY') {
                    $commands_array = $data{$i};
                } else {
                    confess "ERROR NBI::Job: -commands must be an array\n";
                }
            } else {
                confess "ERROR NBI::Seq: Unknown parameter $i\n";
            }
        }
    } 
    
    my $self = bless {}, $class;
    

    $self->{name} = defined $job_name ? $job_name : 'job-' . int(rand(1000000));
    $self->{jobid} = 0;
    
    # Commands: if both commands_array and command are defined, append command to commands_array
    if (defined $commands_array) {
        $self->{commands} = $commands_array;
        if (defined $command) {
            push @{$self->{commands}}, $command;
        }
    } elsif (defined $command) {
        $self->{commands} = [$command];
    } 

    # Opts must be an instance of NBI::Opts, check first
    if (defined $opts) {
        # check that $opts is an instance of NBI::Opts
        if ($opts->isa('NBI::Opts')) {
            # $opts is an instance of NBI::Opts
            $self->{opts} = $opts;
        } else {
            # $opts is not an instance of NBI::Opts
            confess "ERROR NBI::Job: -opts must be an instance of NBI::Opts\n";
        }
  
    } else {
        $self->{opts} = NBI::Opts->new($DEFAULT_QUEUE);
    }
    return $self;
 
}


sub name : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{name} = $new_val if (defined $new_val);
    return $self->{name};
}

sub jobid : lvalue {
    # Update jobid
    my ($self, $new_val) = @_;
    if (defined $new_val and $new_val !~ /^-?(\d+)$/) {
        confess "ERROR NBI::Job: jobid must be an integer ". $new_val ."\n";
    }
    $self->{jobid} = $new_val if (defined $new_val);
    return $self->{jobid};
}

sub outputfile : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{output_file} = $new_val if (defined $new_val);
    if (not defined $self->{output_file}) {
        $self->{output_file} = catfile( $self->opts->tmpdir , $self->name . ".%j.out");
    } else {
        return $self->{output_file};
    }
}

sub errorfile : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{error_file} = $new_val if (defined $new_val);
    if (not defined $self->{error_file}) {
        $self->{error_file} =  catfile($self->opts->tmpdir, $self->name . ".%j.err");
    } else {
        return $self->{error_file};
    }
    
}
sub append_command {
    my ($self, $new_command) = @_;
    push @{$self->{commands}}, $new_command;
}

sub prepend_command {
    my ($self, $new_command) = @_;
    unshift @{$self->{commands}}, $new_command;
}

sub commands {
    my ($self) = @_;
    return $self->{commands};
}

sub commands_count {
    my ($self) = @_;
    return 0 + scalar @{$self->{commands}};
}

sub set_opts {
    my ($self, $opts) = @_;
    # Check that $opts is an instance of NBI::Opts
    if ($opts->isa('NBI::Opts')) {
        # $opts is an instance of NBI::Opts
        $self->{opts} = $opts;
    } else {
        # $opts is not an instance of NBI::Opts
        confess "ERROR NBI::Job: -opts must be an instance of NBI::Opts\n";
    }
}

sub get_opts {
    my ($self) = @_;
    return $self->{opts};
}

sub opts {
    my ($self) = @_;
    return $self->{opts};
}

## Run job

sub script {
    # Generate the sbatch script
    my ($self) = @_;
    
    my $template = [
    '#SBATCH -J NBI_SLURM_JOBNAME',
    '#SBATCH -o NBI_SLURM_OUT',
    '#SBATCH -e NBI_SLURM_ERR',
    ''
    ];
    my $header = $self->opts->header();
    # Replace the template
    my $script = join("\n", @{$template});
    # Replace the values
    
    my $name = $self->name;
    my $file_out = $self->outputfile;
    my $file_err = $self->errorfile;
    $script =~ s/NBI_SLURM_JOBNAME/$name/g;
    $script =~ s/NBI_SLURM_OUT/$file_out/g;
    $script =~ s/NBI_SLURM_ERR/$file_err/g;

    # Add the commands
    $script .= join("\n", @{$self->{commands}});

    return $header . $script . "\n";

}

sub run {
    my $self = shift @_;
        # Check it has some commands
    
 
    # Check it has a queue
    if (not defined $self->opts->queue) {
        confess "ERROR NBI::Job: No queue defined for job " . $self->name . "\n";
    }
    # Check it has some opts
    if (not defined $self->opts) {
        confess "ERROR NBI::Job: No opts defined for job " . $self->name . "\n";
    }
    # Check it has some commands
    if ($self->commands_count == 0) {
        confess "ERROR NBI::Job: No commands defined for job " . $self->name . "\n";
    }

    # Create the script
    my $script = $self->script();

    # Create the script file
    my $script_file = catfile($self->opts->tmpdir, $self->name . ".sh");
    open(my $fh, ">", $script_file) or confess "ERROR NBI::Job: Cannot open file $script_file for writing\n";
    print $fh $script;
    close($fh);

    # Run the script

    if (_has_command('sbatch') == 0) {
        $self->jobid = -1;
        return 0;
    }
    my $job_output = `sbatch "$script_file"`;

    # Check the output
    if ($job_output =~ /Submitted batch job (\d+)/) {
        # Job submitted
        my $job_id = $1;
        # Update the job id
        $self->{job_id} = $job_id;
        return $job_id;
    } else {
        # Job not submitted
        confess "ERROR NBI::Job: Job " . $self->name . " not submitted\n";
    }
    return $self->jobid;
}


sub _has_command {
    my $command = shift;
    my $is_available = 0;
    
    if ($^O eq 'MSWin32') {
        # Windows system
        $is_available = system("where $command >nul 2>nul") == 0;
    } else {
        # Unix-like system
        $is_available = system("command -v $command >/dev/null 2>&1") == 0;
    }
    
    return $is_available;
}

sub _to_string {
    # Convert string to a sanitized string with alphanumeric chars and dashes
    my ($self, $string) = @_;
    return $string =~ s/[^a-zA-Z0-9\-]//gr; 
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Job - A class for representing a job for NBI::Slurm

=head1 VERSION

version 0.5.0

=head1 SYNOPSIS

  use NBI::Job;
  my $job = NBI::Job->new(
    -name => "job-name",
    -command => "ls -l",
  );

Multiple commands can be encoded as a list:

  my $job = NBI::Job->new(
    -name => "job-name",
    -commands => ["ls -l", "echo done"]
  );

=head1 DESCRIPTION

The C<NBI::Job> module provides a class for representing a job to be submitted to SLURM for High-Performance Computing (HPC). 
It allows you to define the name of the job, the commands to be executed, and various options related to the job.

=head1 METHODS

=head2 new()

Create a new instance of C<NBI::Job>. Note that the options must be made as C<NBI::Opts> class.

  my $job = NBI::Job->new(
     -name => "job-name",
     -command => "ls -l",
     -opts => $options
  );

# Multi commands
my $job = NBI::Job->new(
    -name => "job-name",
    -commands => ["ls -l", "echo done"]
);

This method creates a new CNBI::Job object with the specified parameters. The following parameters are supported:

=over 4

=item * B<-name> (string, optional): The name of the job. If not provided, a default name will be assigned.

=item * B<-command> (string, optional): The command to be executed by the job. Only one command can be specified using this parameter.

=item * B<-commands> (arrayref, optional): An array reference containing multiple commands to be executed by the job. If both C<-command> and C<-commands> are provided, the C<-command> will be appended to the C<-commands> array.

=item * B<-opts> (C<NBI::Opts> object, optional): An instance of the C<NBI::Opts> class representing the options for the job. If not provided, a default instance with the "nbi-short" queue will be used.

=back

=head2 name

Accessor method for the job name.

  $job->name = "new-name";
  my $name = $job->name;

This method allows you to get or set the name of the job. 
If called with an argument, it sets the name of the job to the specified value. 
If called without an argument, it returns the current name of the job.

=head2 jobid

Accessor method for the job ID.

  $job->jobid = 12345;
  my $jobid = $job->jobid;

This method allows you to get or set the ID of the job. If called with an argument, it sets the ID of the job to the specified value. If called without an argument, it returns the current ID of the job. 
It's currently B<a public method> but it's meant to be updated by the module itself.

=head2 outputfile

Accessor method for the output file path, where the output of the job will be written. Add C<%j> in the name to use the JobID.

  $job->outputfile = "/path/to/output.txt";
  my $outputfile = $job->outputfile;

This method allows you to get or set the path of the output file generated by the job. If called with an argument, it sets the output file path to the specified value. If called without an argument, it returns the current output file path.

=head2 errorfile

Accessor method for the error file path.

  $job->errorfile = "/path/to/error.txt";
  my $errorfile = $job->errorfile;

This method allows you to get or set the path of the error file generated by the job. If called with an argument, it sets the error file path to the specified value. If called without an argument, it returns the current error file path.

=head2 append_command

Append a command to the job.

  $job->append_command("echo done");

This method allows you to append a command to the list of commands executed by the job.

=head2 prepend_command

Prepend a command to the job.

  $job->prepend_command("echo start");

This method allows you to prepend a command to the list of commands executed by the job.

=head2 commands

Get the list of commands for the job.

  my $commands = $job->commands;

This method returns an array reference containing the commands to be executed by the job.

=head2 commands_count

Get the number of commands for the job.

  my $count = $job->commands_count;

This method returns the number of commands defined for the job.

=head2 set_opts

Set the options for the job.

  $job->set_opts($opts);

This method allows you to set the options for the job using an instance of the C<NBI::Opts> class.

=head2 get_opts

Get the options for the job.

  my $opts = $job->get_opts;

This method returns the options for the job as an instance of the CNBI::Opts class.

=head2 opts

Accessor method for the options of the job.

  my $opts = $job->opts;

This method returns the options for the job as an instance of the CNBI::Opts class.

=head2 script

Generate the sbatch script for the job.

  my $script = $job->script;

This method generates the sbatch script for the job based on the current settings and returns it as a string.

=head2 run

Submit the job to SLURM.

  my $jobid = $job->run;

This method submits the job to SLURM for execution. 
It generates the sbatch script, writes it to a file, and uses the "sbatch" command to submit the job. If the submission is successful, it returns the job ID assigned by SLURM. Otherwise, it throws an exception.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
