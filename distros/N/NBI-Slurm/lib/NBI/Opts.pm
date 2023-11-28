package NBI::Opts;
#ABSTRACT: A class for representing a the SLURM options for NBI::Slurm

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;

$NBI::Opts::VERSION           = $NBI::Slurm::VERSION;

my $SYSTEM_TEMPDIR = $ENV{'TMPDIR'} || $ENV{'TEMP'} || "/tmp";
require Exporter;
our @ISA = qw(Exporter);

sub _yell {
    use Term::ANSIColor;
    my $msg = shift @_;
    my $col = shift @_ || "bold green";
    say STDERR color($col), "[NBI::Opts]", color("reset"), " $msg";
}
sub new {
    my $class = shift @_;
    my ($queue, $memory, $threads, $opts_array, $tmpdir, $hours, $email_address, $email_when) = (undef, undef, undef, undef, undef, undef, undef);
    
    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        
        my %data = @_;

        # Try parsing
        for my $i (keys %data) {
            
            # QUEUE
            if ($i =~ /^-queue/) {
                next unless (defined $data{$i});
                $queue = $data{$i};
                

            # THREADS
            } elsif ($i =~ /^-threads/) {
                next unless (defined $data{$i});
                # Check it's an integer 
                if ($data{$i} =~ /^\d+$/) {
                    $threads = $data{$i};
                } else {
                    confess "ERROR NBI::Seq: -threads expects an integer\n";
                }
                
                
            # MEMORY
            } elsif ($i =~ /^-memory/) {
                next unless (defined $data{$i});
                $memory = _mem_parse_mb($data{$i});
               

            # TMPDIR
            } elsif ($i =~ /^-tmpdir/) {
                next unless (defined $data{$i});
                $tmpdir = $data{$i};
               
            # MAIL ADDRESS
            } elsif ($i =~ /^-(mail|email_address)/) {
                next unless (defined $data{$i});
                $email_address = $data{$i};
                
            # WHEN MAIL
            } elsif ($i =~ /^-(when|email_type)/) {
                next unless (defined $data{$i});
                $email_when = $data{$i};
                

            # OPTS ARRAY
            } elsif ($i =~ /^-opts/) {
                next unless (defined $data{$i});
                # in this case we expect an array
                if (ref($data{$i}) ne "ARRAY") {
                    confess "ERROR NBI::Seq: -opts expects an array\n";
                }
                $opts_array = $data{$i};
                

            # TIME
            } elsif ($i =~ /^-time/) {
                $hours = _time_to_hour($data{$i});
                
            } else {
                confess "ERROR NBI::Seq: Unknown parameter $i\n";
            }
        }
    } 
    
    my $self = bless {}, $class;
    
    # Set attributes
    $self->queue = defined $queue ? $queue : "nbi-short";
    $self->threads = defined $threads ? $threads : 1;
    $self->memory = defined $memory ? $memory : 100;
    $self->hours = defined $hours ? $hours : 1;
    $self->tmpdir = defined $tmpdir ? $tmpdir : $SYSTEM_TEMPDIR;
    $self->email_address = defined $email_address ? $email_address : undef;
    $self->email_type = defined $email_when ? $email_when : "none";
    # Set options
    $self->opts = defined $$opts_array[0] ? $opts_array : [];
    
    
    
    

    return $self;
 
}


sub queue : lvalue {
    # Update queue
    my ($self, $new_val) = @_;
    $self->{queue} = $new_val if (defined $new_val);
    return $self->{queue};
}

sub threads : lvalue {
    # Update threads
    my ($self, $new_val) = @_;
    $self->{threads} = $new_val if (defined $new_val);
    return $self->{threads};
}

sub memory : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{memory} = _mem_parse_mb($new_val) if (defined $new_val);
    return $self->{memory};
}

sub email_address : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{email_address} = $new_val if (defined $new_val);
    return $self->{email_address};
}

sub email_type : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{email_type} = $new_val if (defined $new_val);
    return $self->{email_type};
}

sub hours : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{hours} = _time_to_hour($new_val) if (defined $new_val);
    return $self->{hours};
}

sub tmpdir : lvalue {
    # Update tmpdir
    my ($self, $new_val) = @_;
    $self->{tmpdir} = $new_val if (defined $new_val);
    return $self->{tmpdir};
}

sub opts : lvalue {
    # Update opts
    my ($self, $new_val) = @_;
    if (not defined $self->{opts}) {
        $self->{opts} = [];
        return $self->{opts};
    }
    # check newval is an array
    confess "ERROR NBI::Opts: opts must be an array, got $new_val\n" if (ref($new_val) ne "ARRAY");
    $self->{opts} = $new_val if (defined $new_val);
    return $self->{opts};
}
sub add_option {
    # Add an option
    my ($self, $new_val) = @_;
    push @{$self->{opts}}, $new_val;
    return $self->{opts};
}

sub opts_count {
    # Return the number of options
    my $self = shift @_;
    return defined $self->{opts} ? scalar @{$self->{opts}} : 0;
}

sub view {
    # Return a string representation of the object
    my $self = shift @_;
    my $str = " --- NBI::Opts object ---\n";
    $str .= " queue:\t" . $self->{queue} . "\n";
    $str .= " threads:\t" . $self->{threads} . "\n";
    $str .= " memory MB:\t" . $self->{memory} . "\n";
    $str .= " time (h):\t" . $self->{hours} . "\n";
    $str .= " tmpdir:\t" . $self->{tmpdir} . "\n";
    $str .= " ---------------------------\n";
    for my $o (@{$self->{opts}}) {
        $str .= "#SBATCH $o\n" if defined $o;
    }
    return $str;
}

sub header {
    # Return a header for the script based on the options
    my $self = shift @_;
    my $str = "#!/bin/bash\n";
    # Queue
    $str .= "#SBATCH -p " . $self->{queue} . "\n";
    # Nodes: 1
    $str .= "#SBATCH -N 1\n";
    # Time
    $str .= "#SBATCH -t " . $self->timestring() . "\n";
    # Memory
    $str .= "#SBATCH --mem=" . $self->{memory} . "\n";
    # Threads
    $str .= "#SBATCH -c " . $self->{threads} . "\n";
    # Mail
    if (defined $self->{email_address}) {
        $str .= "#SBATCH --mail-user=" . $self->{email_address} . "\n";
        $str .= "#SBATCH --mail-type=" . $self->{email_type} . "\n";
    }
    # Custom options
    for my $o (@{$self->{opts}}) {
        next if not defined $o;
        $str .= "#SBATCH $o\n";
    }
    return $str;
}

sub timestring {
    my $self = shift @_;
    my $hours = $self->{hours};
    my $days = 0+ int($hours / 24);
    $hours = $hours % 24;
    # Format hours to be 2 digits
    $hours = sprintf("%02d", $hours);
    return "${days}-${hours}:00:00";
}

sub _mem_parse_mb {
    my $mem = shift @_;
    if ($mem=~/^(\d+)$/) {
        # bare number: interpret as MB
        return $mem;
    } elsif ($mem=~/^(\d+)\.?(MB?|GB?|TB?|KB?)$/i) {
        if (substr(uc($2), 0, 1) eq "G") {
            $mem = $1 * 1024;
        } elsif (substr(uc($2), 0, 1) eq "T") {
            $mem = $1 * 1024 * 1024;
        } elsif (substr(uc($2), 0, 1) eq "M") {
            $mem = $1;
        } elsif (substr(uc($2), 0, 1) eq "K") {
            continue;
        } else {
            # Consider MB
            $mem = $1;
        }
    } else {
        confess "ERROR NBI::Opts: Cannot parse memory value $mem\n";
    }
    return $mem;
}

sub _time_to_hour {
    # Get an integer (hours) or a string in the format \d+D \d+H \d+M
    my $time = shift @_;
    $time = uc($time);
    if ($time =~/^(\d+)$/) {
        # Got an integer
        return $1;
    } else {
        my $hours = 0;
        while ($time =~/(\d+)([DHM])/g) {
            my $val = $1;
            my $unit = $2;
            if ($unit eq "D") {
                
                $hours += $val * 24;
          
            } elsif ($unit eq "M") {
                $val /= 60;
                $hours += $val;

            } elsif ($unit eq "H") {
                $hours += $val;
    
            } elsif ($unit eq "S") {
                continue;
            } else {
                confess "ERROR NBI::Opts: Cannot parse time value $time\n";
            }
            
        }
        return $hours;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Opts - A class for representing a the SLURM options for NBI::Slurm

=head1 VERSION

version 0.8.2

=head1 SYNOPSIS

SLURM Options for L<NBI::Slurm>, to be passed to a L<NBI::Job> object.

  use NBI::Opts;
  my $opts = NBI::Opts->new(
   -queue => "short",
   -threads => 4,
   -memory => 8,
   -opts => []
  );

=head1 DESCRIPTION

The C<NBI::Opts> module provides a class for representing the SLURM options used by L<NBI::Slurm> for job submission. 
It allows you to set various options such as the queue, number of threads, allocated memory, execution time, and more.

=head1 METHODS

=head2 new()

Create a new instance of CNBI::Opts.

  my $opts = NBI::Opts->new(
    -queue => "short",
    -threads => 4,
    -memory => 8,
    -opts  => ["--option=Value"],
  );

This method creates a new C<NBI::Opts> object with the specified options. The following parameters are supported:

=over 4

=item * B<-queue> (string, optional)

The SLURM queue to submit the job to. If not provided, the default queue will be used.

=item * B<-threads> (integer, optional)

The number of threads to allocate for the job. If not provided, the default value is 1.

=item * B<-memory> (string or integer (Mb), optional)

The allocated memory for the job. It can be specified as a bare number representing megabytes (e.g., 1024), or with a unit suffix (e.g., 1GB). If not provided, the default value is 100 megabytes.

=item * B<-opts> (arrayref, optional)

An array reference containing additional SLURM options to be passed to the job script. Each option should be specified as a string. For example, ["--output=TestJob.out", "--mail-user user@nmsu.edu"]. If not provided, no additional options will be added.

B<NOTE> that some options are set by other methods (like C<output_file> and C<email_address>): do not specify them manually.

=back

=head2 queue

Accessor method for the SLURM queue.

  $opts->queue = "long";
  my $queue = $opts->queue;

This method allows you to get or set the SLURM queue for the job. If called with an argument, it sets the queue to the specified value. If called without an argument, it returns the current queue value.

=head2 threads

Accessor method for the number of threads.

  $opts->threads = 8;
  my $threads = $opts->threads;

This method allows you to get or set the number of threads allocated for the job. If called with an argument, it sets the number of threads to the specified value. If called without an argument, it returns the current number of threads.

=head2 memory

Accessor method for the allocated memory.

  $opts->memory = 16;
  my $memory = $opts->memory;

This method allows you to get or set the allocated memory for the job. If called with an argument, it sets the memory to the specified value. If called without an argument, it returns the current allocated memory.

=head2 email_address

Accessor method for the email address.

  $opts->email_address = "user@example.com";
  my $email_address = $opts->email_address;

This method allows you to get or set the email address to which job notifications will be sent. If called with an argument, it sets the email address to the specified value. If called without an argument, it returns the current email address.

=head2 email_type

Accessor method for the email type.

  $opts->email_type = "end";
  my $email_type = $opts->email_type;

This method allows you to get or set the type of email notifications to receive. Possible values are "none" (no email notifications), "begin" (send email at the start of the job), "end" (send email at the end of the job), or "all" (send email for all job events). If called with an argument, it sets the email type to the specified value. If called without an argument, it returns the current email type.

=head2 hours

Accessor method for the execution time in hours.

  $opts->hours = 24;
  my $hours = $opts->hours;

This method allows you to get or set the execution time for the job in hours. If called with an argument, it sets the execution time to the specified value. If called without an argument, it returns the current execution time.

=head2 tmpdir

Accessor method for the temporary directory.

  $opts->tmpdir = "/path/to/tmpdir";
  my $tmpdir = $opts->tmpdir;

This method allows you to get or set the temporary directory path where temporary files for the job will be stored. If called with an argument, it sets the temporary directory to the specified value. If called without an argument, it returns the current temporary directory.

=head2 opts

Accessor method for the additional SLURM options.

  $opts->opts = ["--output=TestJob.out", "--mail-user user@nmsu.edu"];
  my $opts_array = $opts->opts;

This method allows you to get or set the additional SLURM options for the job. The options should be specified as an array reference, where each element is a string representing a single option. If called with an argument, it sets the additional options to the specified array reference. If called without an argument, it returns the current additional options.

=head2 add_option

Add an additional SLURM option.

  $opts->add_option("--output=TestJob.out");

This method allows you to add an additional SLURM option to the options list.

=head2 opts_count

Get the number of additional SLURM options.

  my $count = $opts->opts_count;

This method returns the number of additional SLURM options specified for the job.

=head2 view

Get a string representation of the options.

  my $str = $opts->view;

This method returns a string representation of the CNBI::Opts object, including all the options and their values.

=head2 header

Generate the SLURM header for the job script.

  my $header = $opts->header;

This method generates the SLURM header for the job script based on the current options and returns it as a string.

=head2 timestring

Get the execution time as a formatted string.

  my $timestring = $opts->timestring;

This method returns the execution time as a formatted string in the format "DD-HH:MM:SS", where "DD" is the number of days, "HH" is the number of hours (in 2 digits), "MM" is the number of minutes, and "SS" is the number of seconds.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
