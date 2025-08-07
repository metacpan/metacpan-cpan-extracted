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
    my ($queue, $memory, $threads, $opts_array, $tmpdir, $hours, $email_address, $email_when, $files, $placeholder) = (undef, undef, undef, undef, undef, undef, undef, undef, undef);
    
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
                
            # PLACEHOLDER
            } elsif ($i =~ /^-placeholder/) {
                # check if placeholder contains special regex characters
                if (not defined $data{$i}) {
                    confess "ERROR NBI::Seq: Placeholder cannot be empty\n";
                }
                if ($data{$i} =~ /[\*\+\?]/) {
                    confess "ERROR NBI::Seq: Placeholder cannot contain special regex characters\n";
                }
                $placeholder = $data{$i};
                
            # ARRAY
            } elsif ($i =~ /^-files/) {
                # expects ref to array
                if (ref($data{$i}) ne "ARRAY") {
                    confess "ERROR NBI::Seq: -files expects an array\n";
                } else {
                    $files = $data{$i};
                }
                
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
    $self->files = defined $files ? $files : [];
    $self->placeholder = defined $placeholder ?  $placeholder : "#FILE#";
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

# property files (list of files)
sub files : lvalue {
    # Update files
    my ($self, $new_val) = @_;
    $self->{files} = $new_val if (defined $new_val);
    return $self->{files};
}

sub placeholder : lvalue {
    # Update placeholder
    my ($self, $new_val) = @_;
    $self->{placeholder} = $new_val if (defined $new_val);
    return $self->{placeholder};
}
sub is_array {
    # Check if the job is an array
    my $self = shift @_;
    return scalar @{$self->{files}} > 0;
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

    # Job array
    if ($self->is_array()) {
        my $len = scalar @{$self->{files}} - 1;
        $str .= "#SBATCH --array=0-$len\n";
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
            $mem = int($1/1024);
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
    # Get an integer (hours) or a string in the format \d+D \d+H \d+M \d+S
    my $time = shift @_;
    $time = uc($time);
    
    if ($time =~ /^(\d+)$/) {
        # Got an integer
        return $1;
    } else {
        my $hours = 0;
        while ($time =~ /(\d+)([DHMS])/g) {
            my $val = $1;
            my $unit = $2;
            if ($unit eq "D") {
                $hours += $val * 24;
            } elsif ($unit eq "H") {
                $hours += $val;
            } elsif ($unit eq "M") {
                $hours += $val / 60;
            } elsif ($unit eq "S") {
                $hours += $val / 3600;
            } else {
                die "ERROR NBI::Opts: Cannot parse time value $time\n";
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

version 0.14.0

=head1 SYNOPSIS

SLURM Options for L<NBI::Slurm>, to be passed to a L<NBI::Job> object.

  use NBI::Opts;
  my $opts = NBI::Opts->new(
   -queue => "short",
   -threads => 4,
   -memory => "8GB",
   -time => "2h",
   -opts => [],
  );

=head1 DESCRIPTION

The C<NBI::Opts> module provides a class for representing the SLURM options used by L<NBI::Slurm> for job submission. 
It allows you to set various options such as the queue, number of threads, allocated memory, execution time, input files, and more.

=head1 METHODS

=head2 new()

Create a new instance of C<NBI::Opts>. In this case this will imply using a job array over a list of files

  my $opts = NBI::Opts->new(
    -queue => "short",
    -threads => 4,
    -memory => "8GB",
    -time => "2h",
    -opts => ["--option=Value"],
    -tmpdir => "/path/to/tmp",
    -email_address => "user@example.com",
    -email_type => "ALL",
    -files => ["file1.txt", "file2.txt"],
    -placeholder => "#FILE#"
  );

This method creates a new C<NBI::Opts> object with the specified options. The following parameters are supported:

=over 4

=item * B<-queue> (string, optional)

The SLURM queue to submit the job to. Default is "nbi-short".

=item * B<-threads> (integer, optional)

The number of threads to allocate for the job. Default is 1.

=item * B<-memory> (string or integer, optional)

The allocated memory for the job. It can be specified as a bare number representing megabytes (e.g., 1024), or with a unit suffix (e.g., "8GB"). Default is 100 megabytes.

=item * B<-time> (string or integer, optional)

The time limit for the job. It can be specified as hours (e.g., 2) or as a string with time units (e.g., "2h", "1d 12h"). Default is 1 hour.

=item * B<-opts> (arrayref, optional)

An array reference containing additional SLURM options to be passed to the job script.

=item * B<-tmpdir> (string, optional)

The temporary directory to use for job execution. Default is the system's temporary directory.

=item * B<-email_address> (string, optional)

The email address for job notifications.

=item * B<-email_type> (string, optional)

The type of email notifications to receive (e.g., "NONE", "BEGIN", "END", "FAIL", "ALL"). Default is "NONE".

=item * B<-files> (arrayref, optional)

An array reference containing input files or file patterns for the job.

=item * B<-placeholder> (string, optional)

A placeholder string to be used in the command for input files. Default is "#FILE#".

=back

=head2 queue

Accessor method for the SLURM queue.

  $opts->queue = "long";
  my $queue = $opts->queue;

=head2 threads

Accessor method for the number of threads.

  $opts->threads = 8;
  my $threads = $opts->threads;

=head2 memory

Accessor method for the allocated memory.

  $opts->memory = "16GB";
  my $memory = $opts->memory;

=head2 email_address

Accessor method for the email address.

  $opts->email_address = "user@example.com";
  my $email_address = $opts->email_address;

=head2 email_type

Accessor method for the email notification type.

  $opts->email_type = "ALL";
  my $email_type = $opts->email_type;

=head2 hours

Accessor method for the execution time in hours.

  $opts->hours = 24;
  my $hours = $opts->hours;

=head2 tmpdir

Accessor method for the temporary directory.

  $opts->tmpdir = "/path/to/tmpdir";
  my $tmpdir = $opts->tmpdir;

=head2 opts

Accessor method for the additional SLURM options.

  $opts->opts = ["--output=TestJob.out", "--mail-user user@example.com"];
  my $opts_array = $opts->opts;

=head2 files

Accessor method for the input files or file patterns.

  $opts->files = ["file1.txt", "*.fasta"];
  my $files = $opts->files;

=head2 placeholder

Accessor method for the input file placeholder.

  $opts->placeholder = "{INPUT}";
  my $placeholder = $opts->placeholder;

=head2 add_option

Add an additional SLURM option.

  $opts->add_option("--output=TestJob.out");

=head2 opts_count

Get the number of additional SLURM options.

  my $count = $opts->opts_count;

=head2 is_array

Check if the job is an array job (has multiple input files).

  my $is_array = $opts->is_array;

=head2 view

Get a string representation of the options.

  my $str = $opts->view;

=head2 header

Generate the SLURM header for the job script.

  my $header = $opts->header;

=head2 timestring

Get the execution time as a formatted string.

  my $timestring = $opts->timestring;

Returns the execution time in the format "DD-HH:MM:SS".

=head1 INTERNAL METHODS

=head2 _mem_parse_mb

Parse memory input and convert to megabytes.

=head2 _time_to_hour

Convert time input to hours.

=cut

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
