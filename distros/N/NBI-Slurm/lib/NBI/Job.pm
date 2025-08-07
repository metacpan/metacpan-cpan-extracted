package NBI::Job;
#ABSTRACT: A class for representing a job for NBI::Slurm

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
use File::Spec::Functions;
$Data::Dumper::Sortkeys = 1;
use File::Basename;

$NBI::Job::VERSION  = $NBI::Slurm::VERSION;
my $DEFAULT_QUEUE   = "nbi-short";
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

    $self->{script_path} = undef;

    # Check here if there is opts->placeholder in the commands.
    # If there is then replace /placeholder/ with ${selected_file}

    if ($self->opts->is_array()) {
        my $placeholder = $self->opts->placeholder;
        # Double escape the backslash for regex
        my $regex_placeholder = $placeholder;
        $regex_placeholder =~ s/\\/\\\\/g;
        my $count = 0;
        for my $cmd (@{$self->{commands}}) {
            if ($cmd =~ $self->opts->placeholder) {
                $count++;
            }
            $cmd =~ s/\Q$regex_placeholder\E/\${selected_file}/g;
        }
    }
    return $self;
 
}


sub script_path : lvalue {
    # Update script_path
    my ($self, $new_val) = @_;
    $self->{script_path} = $new_val if (defined $new_val);
    return $self->{script_path};
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
    my ($self, $parameter) = @_;

    my $interpolate = 0;
    if (defined $parameter) {
        if ($parameter eq '-interpolate') {
            $interpolate = 1;
        } else {
            $self->{output_file} = $parameter;
        }
    }

    # Create a default output_file if not defined
    if (not defined $self->{output_file}) {
        $self->{output_file} = catfile( $self->opts->tmpdir , $self->name . ".%j.out");
    }
    
    if ($interpolate) {
        my $jobid = $self->jobid;
        my $output_file = $self->{output_file};
        $output_file =~ s/%j/$jobid/g;
        return $output_file;
    } else {
        return $self->{output_file};
    }
    
}

sub errorfile : lvalue {
   # Update name
    my ($self, $parameter) = @_;

    my $interpolate = 0;
    if (defined $parameter) {
        if ($parameter eq '-interpolate') {
            $interpolate = 1;
        } else {
            $self->{error_file} = $parameter;
        }
    }

    # Create a default error_file if not defined
    if (not defined $self->{error_file}) {
        $self->{error_file} = catfile( $self->opts->tmpdir , $self->name . ".%j.err");
    }
    
    if ($interpolate) {
        my $jobid = $self->jobid;
        my $error_file = $self->{error_file};
        $error_file =~ s/%j/$jobid/g;
        return $error_file;
    } else {
        return $self->{error_file};
    }
    
}
sub append_command {
    my ($self, $new_command) = @_;
    if ($self->opts->is_array()) {
        my $placeholder = $self->opts->placeholder;
        $new_command =~ s/\Q$placeholder\E/\${selected_file}/g;
    }
    push @{$self->{commands}}, $new_command;
}

sub prepend_command {
    my ($self, $new_command) = @_;
    if ($self->opts->is_array()) {
        my $placeholder = $self->opts->placeholder;
        $new_command =~ s/\Q$placeholder\E/\${selected_file}/g;
    }
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
    
    my $replacements = 0;
    my $placeholder = $self->opts->placeholder;
    
    if ($self->opts->is_array()) {
  
        # Prepend strings to array $self->{commands}
        # Escape spaces in each file
        my @prepend = ();
        my $self_files = $self->opts->files;
        for my $file (@{$self_files}) {
            $file =~ s/ /\\ /g;
        }
        my $files_list = join(" ", @{$self_files});
        my $list = "self_files=($files_list)";
        push(@prepend, "# Job array list", "$list", "selected_file=\${self_files[\$SLURM_ARRAY_TASK_ID]}");
        
        # Prepend the array to the commands
        unshift @{$self->{commands}}, @prepend;

 
        
    }
    if ($self->opts->is_array()) {
        # check if at least one command containts ${selected_file}
        my $selected_file = 0;
        for my $cmd (@{$self->{commands}}) {
            if ($cmd =~ /\$\{selected_file\}/) {
                $selected_file = 1;
                last;
            }
        }
        if ($selected_file == 0) {
            confess "ERROR NBI::Job: No command contains the placeholder:" . $self->opts->placeholder . "\n";
        }
    }    

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

    # change suffix from .sh to .INT.sh if the file exists already
    if (-e $script_file) {
        my $i = 1;
        while (-e $script_file) {
            my $string_int = sprintf("%05d", $i);
            $script_file = catfile($self->opts->tmpdir, $self->name . "." . $string_int . ".sh");
            $i++;
        }
    }

    $self->{"script_path"} = $script_file;
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
        $self->jobid = $job_id;
        return $job_id;
    } else {
        # Job not submitted
        confess "ERROR NBI::Job: Job " . $self->name . " not submitted\n";
    }
    return $self->jobid;
}


sub view {
    # Return a string representation of the object
    my $self = shift @_;
    my $str = " --- NBI::Job object ---\n";
    $str .= " name:       " . $self->name . "\n";
    $str .= " commands:   \n\t" . join("\n\t", @{$self->commands}) . "\n";
    $str .= " jobid:      " . $self->jobid . "\n";    
    $str .= " script:     " . $self->script_path . "\n";
    $str .= " output file:" . $self->outputfile('-interpolate') . "\n";
    $str .= " error file: " . $self->errorfile('-interpolate') . "\n";
    $str .= " ---------------------------\n";
 
    return $str;
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

version 0.14.0

=head1 DESCRIPTION

The C<NBI::Job> module provides a class for representing a job to be submitted to SLURM for High-Performance Computing (HPC). 
It allows you to define the name of the job, the commands to be executed, and various options related to the job execution.

=head1 EXAMPLES

  use NBI::Job;
  use NBI::Opts;

  # Create a simple job
  my $job = NBI::Job->new(
    -name => "simple-job",
    -command => "echo 'Hello, World!'"
  );

  # Create a job with multiple commands
  my $multi_job = NBI::Job->new(
    -name => "multi-command-job",
    -commands => ["echo 'Step 1'", "sleep 5", "echo 'Step 2'"]
  );

  # Create a job with custom options: first define $opts and then $custom_job
  my $opts = NBI::Opts->new(
    -queue => "long",
    -memory => "4GB",
    -threads => 2,
    -time => "1h"
  );

  my $custom_job = NBI::Job->new(
    -name => "custom-job",
    -command => "run_analysis.pl",
    -opts => $opts
  );

  # Submit the job
  my $job_id = $custom_job->run;
  print "Job submitted with ID: $job_id\n";

=head1 METHODS

=head2 new()

Create a new instance of C<NBI::Job>.

  my $job = NBI::Job->new(
    -name => "job-name",
    -command => "ls -l",
    -opts => $options
  );

  # Or with multiple commands
  my $job = NBI::Job->new(
    -name => "multi-step-job",
    -commands => ["step1.pl", "step2.pl", "step3.pl"],
    -opts => $options
  );

Parameters:

=over 4

=item * B<-name> (string, optional): The name of the job. If not provided, a random name will be generated.

=item * B<-command> (string, optional): A single command to be executed by the job.

=item * B<-commands> (arrayref, optional): An array reference containing multiple commands to be executed by the job.

=item * B<-opts> (C<NBI::Opts> object, optional): An instance of the C<NBI::Opts> class representing the options for the job. If not provided, default options will be used.

=back

=head2 name

Accessor method for the job name.

  $job->name = "new-job-name";
  my $name = $job->name;

=head2 jobid

Accessor method for the job ID.

  $job->jobid = 12345;  # Usually set internally after job submission
  my $jobid = $job->jobid;

=head2 outputfile

Accessor method for the output file path. Use C<%j> in the filename to include the job ID.

  $job->outputfile = "job_output_%j.txt";
  my $outputfile = $job->outputfile;
  my $interpolated_outputfile = $job->outputfile('-interpolate');

=head2 errorfile

Accessor method for the error file path. Use C<%j> in the filename to include the job ID.

  $job->errorfile = "job_error_%j.txt";
  my $errorfile = $job->errorfile;
  my $interpolated_errorfile = $job->errorfile('-interpolate');

=head2 script_path

Accessor method for the generated script path.

  my $script_path = $job->script_path;

=head2 append_command

Append a command to the job.

  $job->append_command("echo 'Job finished'");

=head2 prepend_command

Prepend a command to the job.

  $job->prepend_command("echo 'Job starting'");

=head2 commands

Get the list of commands for the job.

  my $commands = $job->commands;
  foreach my $cmd (@$commands) {
    print "Command: $cmd\n";
  }

=head2 commands_count

Get the number of commands for the job.

  my $count = $job->commands_count;
  print "This job has $count commands.\n";

=head2 set_opts

Set the options for the job.

  my $new_opts = NBI::Opts->new(-queue => "short", -memory => "2GB");
  $job->set_opts($new_opts);

=head2 get_opts

Get the options for the job.

  my $opts = $job->get_opts;
  print "Job queue: " . $opts->queue . "\n";

=head2 opts

Alias for get_opts.

  my $opts = $job->opts;

=head2 script

Generate the sbatch script for the job.

  my $script_content = $job->script;
  print "Generated script:\n$script_content\n";

=head2 run

Submit the job to SLURM.

  my $submitted_job_id = $job->run;
  if ($submitted_job_id) {
    print "Job submitted successfully with ID: $submitted_job_id\n";
  } else {
    print "Job submission failed.\n";
  }

=head2 view

Return a string representation of the job object.

  my $job_info = $job->view;
  print $job_info;

=cut

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
